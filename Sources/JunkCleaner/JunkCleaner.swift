import Foundation
import AppKit
import UserNotifications

@Observable
final class JunkCleaner {

    var isDeleting: Bool = false
    var deleteProgress: Double = 0
    var currentDeleteTask: String = ""
    var deletedItems: [JunkItem] = []
    var failedItems: [(item: JunkItem, reason: String)] = []
    var totalFreedBytes: Int64 = 0
    var lastResult: CleanResult?

    struct CleanResult {
        let freedBytes: Int64
        let deletedCount: Int
        let failedCount: Int
        let duration: TimeInterval
        var freedGB: Double { Double(freedBytes) / 1_073_741_824.0 }
        var freedMB: Double { Double(freedBytes) / 1_048_576.0 }
        var formattedFreed: String {
            if freedGB >= 1.0 { return String(format: "%.2f GB", freedGB) }
            return String(format: "%.1f MB", freedMB)
        }
    }

    private let fm = FileManager.default

    // MARK: - Main Clean
    func clean(items: [JunkItem]) async {
        guard !isDeleting else { return }

        await MainActor.run {
            self.isDeleting = true
            self.deleteProgress = 0
            self.currentDeleteTask = "Preparing..."
            self.deletedItems = []
            self.failedItems = []
            self.totalFreedBytes = 0
            self.lastResult = nil
        }

        // Request admin once before starting
        let adminReady = await setupAdminPersistent()
        if !adminReady {
            await MainActor.run {
                self.isDeleting = false
                self.currentDeleteTask = "Cancelled (needs permission)"
            }
            return
        }

        let start = Date()
        // Sort: launch agents/daemons first so they are unloaded before other files
        let sorted = items.sorted {
            ($0.type == .appLaunchAgents || $0.type == .appLaunchDaemons) &&
            !($1.type == .appLaunchAgents || $1.type == .appLaunchDaemons)
        }

        for (index, item) in sorted.enumerated() {
            await MainActor.run {
                self.currentDeleteTask = "Cleaning: \(item.displayName)"
                self.deleteProgress = Double(index) / Double(sorted.count)
            }

            // Check file still exists
            guard fm.fileExists(atPath: item.path) else {
                // File already gone — count as success
                await MainActor.run {
                    self.totalFreedBytes += item.sizeBytes
                    self.deletedItems.append(item)
                }
                continue
            }

            do {
                try await deleteItem(item)
                await MainActor.run {
                    self.totalFreedBytes += item.sizeBytes
                    self.deletedItems.append(item)
                }
            } catch {
                await MainActor.run {
                    self.failedItems.append((item, error.localizedDescription))
                }
            }
        }

        let duration = Date().timeIntervalSince(start)
        let result = CleanResult(
            freedBytes: self.totalFreedBytes,
            deletedCount: self.deletedItems.count,
            failedCount: self.failedItems.count,
            duration: duration
        )

        await MainActor.run {
            self.lastResult = result
            self.isDeleting = false
            self.deleteProgress = 1.0
            self.currentDeleteTask = "Done!"
        }

        sendNotification(result: result)
    }

    // MARK: - Delete Single Item
    private func deleteItem(_ item: JunkItem) async throws {
        let path = item.path
        let url = URL(fileURLWithPath: path)

        // Unload launch items before deleting
        if item.type == .appLaunchAgents || item.type == .appLaunchDaemons {
            unloadLaunchItem(path: path)
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        // Receipts: delete both .plist and .bom
        if item.type == .appReceipts {
            let base = (path as NSString).lastPathComponent
                .replacingOccurrences(of: ".plist", with: "")
                .replacingOccurrences(of: ".bom", with: "")
            let dir = "/private/var/db/receipts"
            sudoRmForce(path: "\(dir)/\(base).plist")
            sudoRmForce(path: "\(dir)/\(base).bom")
            return
        }

        // Trash contents: remove each file inside
        if item.type == .trashContents {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return }
            for file in contents {
                let filePath = "\(path)/\(file)"
                if (try? fm.removeItem(atPath: filePath)) == nil {
                    sudoRmForce(path: filePath)
                }
            }
            return
        }

        // System paths need sudo
        if isSystemPath(path) {
            try sudoRm(path: path)
            return
        }

        // Try normal trash first, fallback to direct delete, then sudo
        var outURL: NSURL?
        do {
            try fm.trashItem(at: url, resultingItemURL: &outURL)
        } catch {
            do {
                try fm.removeItem(at: url)
            } catch {
                try sudoRm(path: path)
            }
        }
    }

    // MARK: - Is System Path
    private func isSystemPath(_ path: String) -> Bool {
        let systemPrefixes = ["/Library/", "/private/", "/usr/", "/opt/"]
        return systemPrefixes.contains(where: { path.hasPrefix($0) })
    }

    // MARK: - sudo rm (throws on failure)
    private func sudoRm(path: String) throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "/bin/rm", "-rf", path]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus != 0 {
            throw NSError(domain: "JunkCleaner", code: Int(p.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "Permission denied: \(path)"])
        }
    }

    // MARK: - sudo rm (silent, no throw)
    private func sudoRmForce(path: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "/bin/rm", "-rf", path]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
    }

    // MARK: - Admin Setup
    private func setupAdminPersistent() async -> Bool {
        if isSudoersReady() { return true }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let user = NSUserName()
                let sudoersFile = "/private/etc/sudoers.d/junkcleaner_\(user)"
                let rule = "\(user) ALL=(ALL) NOPASSWD: /bin/rm"
                let script = """
                do shell script "mkdir -p /private/etc/sudoers.d && echo '\(rule)' > \(sudoersFile) && chmod 440 \(sudoersFile)" with prompt "JunkCleaner needs one-time permission to delete junk files" with administrator privileges
                """
                var errorDict: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&errorDict)
                continuation.resume(returning: errorDict == nil)
            }
        }
    }

    private func isSudoersReady() -> Bool {
        let user = NSUserName()
        let sudoersFile = "/private/etc/sudoers.d/junkcleaner_\(user)"
        guard fm.fileExists(atPath: sudoersFile) else { return false }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "/bin/rm", "-f", "/dev/null"]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
        return p.terminationStatus == 0
    }

    private func unloadLaunchItem(path: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        p.arguments = ["unload", "-w", path]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        try? p.run()
        p.waitUntilExit()
    }

    // MARK: - Notification
    private func sendNotification(result: CleanResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "JunkCleaner — Done! 🗑"
            content.body = "Freed \(result.formattedFreed) · \(result.deletedCount) files deleted"
            if result.failedCount > 0 {
                content.subtitle = "⚠️ \(result.failedCount) files could not be deleted"
            }
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "junkcleaner.done.\(Int(Date().timeIntervalSince1970))",
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
    }
}
