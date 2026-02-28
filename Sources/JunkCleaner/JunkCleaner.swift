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

        let adminReady = await setupAdminPersistent()
        guard adminReady else { return }

        await MainActor.run {
            self.isDeleting = true
            self.deleteProgress = 0
            self.currentDeleteTask = "Preparing..."
            self.deletedItems = []
            self.failedItems = []
            self.totalFreedBytes = 0
            self.lastResult = nil
        }

        let start = Date()
        let sorted = items.sorted {
            ($0.type == .appLaunchAgents || $0.type == .appLaunchDaemons) &&
            !($1.type == .appLaunchAgents || $1.type == .appLaunchDaemons)
        }

        for (index, item) in sorted.enumerated() {
            await MainActor.run {
                self.currentDeleteTask = "Cleaning: \(item.displayName)"
                self.deleteProgress = Double(index) / Double(sorted.count)
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

        // ส่ง macOS system notification แจ้งเตือนผลลัพธ์
        sendNotification(result: result)
    }

    // MARK: - macOS Notification
    private func sendNotification(result: CleanResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "JunkCleaner — เสร็จแล้ว! 🗑"

            if result.freedGB >= 1.0 {
                content.body = "ลบไฟล์ขยะไปได้ \(String(format: "%.2f GB", result.freedGB)) · \(result.deletedCount) ไฟล์"
            } else {
                content.body = "ลบไฟล์ขยะไปได้ \(String(format: "%.1f MB", result.freedMB)) · \(result.deletedCount) ไฟล์"
            }

            if result.failedCount > 0 {
                content.subtitle = "⚠️ ลบไม่ได้ \(result.failedCount) ไฟล์"
            }

            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "junkcleaner.done.\(Int(Date().timeIntervalSince1970))",
                content: content,
                trigger: nil   // แสดงทันที
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - ลบไฟล์เดียว
    private func deleteItem(_ item: JunkItem) async throws {
        let path = item.path
        let url = URL(fileURLWithPath: path)
        guard fm.fileExists(atPath: path) else { return }

        if item.type == .appLaunchAgents || item.type == .appLaunchDaemons {
            unloadLaunchItem(path: path)
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        if item.type == .appReceipts {
            let packageID = (path as NSString).lastPathComponent
                .replacingOccurrences(of: ".plist", with: "")
                .replacingOccurrences(of: ".bom", with: "")
            try? sudoRm(path: "/private/var/db/receipts/\(packageID).plist")
            try? sudoRm(path: "/private/var/db/receipts/\(packageID).bom")
            return
        }

        if path.hasPrefix("/Library/") || path.hasPrefix("/private/") || path.hasPrefix("/usr/") {
            try sudoRm(path: path)
            return
        }

        if item.type == .trashContents {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return }
            for file in contents {
                let filePath = "\(path)/\(file)"
                if (try? fm.removeItem(atPath: filePath)) == nil {
                    try? sudoRm(path: filePath)
                }
            }
            return
        }

        var outURL: NSURL?
        do {
            try fm.trashItem(at: url, resultingItemURL: &outURL)
        } catch {
            try sudoRm(path: path)
        }
    }

    // MARK: - sudo rm
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
                          userInfo: [NSLocalizedDescriptionKey: "sudo rm failed: \(path)"])
        }
    }

    // MARK: - Admin Setup (ขอรหัสครั้งเดียว)
    private func setupAdminPersistent() async -> Bool {
        if isSudoersReady() { return true }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let user = NSUserName()
                let sudoersFile = "/private/etc/sudoers.d/junkcleaner_\(user)"
                let rule = "\(user) ALL=(ALL) NOPASSWD: /bin/rm"
                let script = """
                do shell script "mkdir -p /private/etc/sudoers.d && echo '\(rule)' > \(sudoersFile) && chmod 440 \(sudoersFile) && /usr/bin/sudo -n /bin/rm -f /dev/null" with prompt "JunkCleaner ต้องการรหัสผ่านครั้งเดียว เพื่อลบไฟล์ขยะโดยไม่ถามซ้ำ" with administrator privileges
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
}
