import Foundation
import AppKit

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

        // Setup sudoers ก่อน loop ลบไฟล์ หากยกเลิกให้หยุดการทำงาน
        if !setupAdminOnce() {
            await MainActor.run { self.lastResult = CleanResult(freedBytes: 0, deletedCount: 0, failedCount: 0, duration: 0) }
            return
        }

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
        // เรียง: LaunchAgents/Daemons ก่อน (unload ก่อนลบ)
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
                let reason = error.localizedDescription
                await MainActor.run {
                    self.failedItems.append((item, reason))
                }
            }
        }

        let duration = Date().timeIntervalSince(start)
        await MainActor.run {
            self.lastResult = CleanResult(freedBytes: self.totalFreedBytes, deletedCount: self.deletedItems.count, failedCount: self.failedItems.count, duration: duration)
            self.isDeleting = false
            self.deleteProgress = 1.0
            self.currentDeleteTask = "Done!"
        }
    }

    // MARK: - ลบ item เดียว
    private func deleteItem(_ item: JunkItem) async throws {
        let path = item.path
        let url = URL(fileURLWithPath: path)
        guard fm.fileExists(atPath: path) else { return }

        // LaunchAgent/Daemon: unload ก่อนเสมอ แล้วรอ 0.3 วินาที
        if item.type == .appLaunchAgents || item.type == .appLaunchDaemons {
            unloadLaunchItem(path: path)
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        // pkgutil receipt: ใช้ pkgutil --forget
        if item.type == .appReceipts {
            let packageID = (path as NSString).lastPathComponent
                .replacingOccurrences(of: ".plist", with: "")
                .replacingOccurrences(of: ".bom", with: "")
            forgetPackage(packageID: packageID)
            return
        }

        // ถ้า path ครอบคลุม /Library/, /private/, /usr/ ให้ข้าม trashItem แล้วเรียก deleteWithAdmin ทันที
        if path.hasPrefix("/Library/") || path.hasPrefix("/private/") || path.hasPrefix("/usr/") {
            try await deleteWithAdmin(path: path)
            return
        }

        // ลองย้ายไป Trash ก่อน (safer)
        var outURL: NSURL?
        do {
            try fm.trashItem(at: url, resultingItemURL: &outURL)
        } catch {
            // ถ้า trashItem fail ให้เรียก deleteWithAdmin ทันที อย่า fallback ไป removeItem
            try await deleteWithAdmin(path: path)
        }
    }

    // MARK: - Admin delete ผ่าน Process sudo
    private func deleteWithAdmin(path: String) async throws {
        var p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        p.arguments = ["-n", "/bin/rm", "-rf", path]
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        
        do {
            try p.run()
            p.waitUntilExit()
            if p.terminationStatus != 0 {
                // ถ้า sudo -n fail แสดงว่า sudoers ยังไม่ได้ setup -> fallback
                if !setupAdminOnce() {
                    throw NSError(domain: "JunkCleaner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Admin setup failed or cancelled"])
                }
                
                // ลองใหม่อีกครั้ง
                p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
                p.arguments = ["-n", "/bin/rm", "-rf", path]
                p.standardOutput = FileHandle.nullDevice
                p.standardError = FileHandle.nullDevice
                try p.run()
                p.waitUntilExit()
                if p.terminationStatus != 0 {
                    throw NSError(domain: "JunkCleaner", code: Int(p.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Admin delete failed after setup"])
                }
            }
        } catch {
            throw NSError(domain: "JunkCleaner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to run sudo process: \(error.localizedDescription)"])
        }
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

    private func forgetPackage(packageID: String) {
        let script = "do shell script \"pkgutil --forget '\(packageID)'\" with administrator privileges"
        let appleScript = NSAppleScript(source: script)
        var err: NSDictionary?
        appleScript?.executeAndReturnError(&err)
    }

    // MARK: - Admin Setup
    private func setupAdminOnce() -> Bool {
        let user = NSUserName()
        let script = """
        do shell script "mkdir -p /private/etc/sudoers.d && echo '\(user) ALL=(ALL) NOPASSWD: /bin/rm' > /private/etc/sudoers.d/junkcleaner_\(user) && chmod 440 /private/etc/sudoers.d/junkcleaner_\(user)" with prompt "JunkCleaner ต้องการรหัสผ่านครั้งเดียว เพื่อเปิดใช้ Touch ID สำหรับการลบไฟล์ในอนาคต" with administrator privileges
        """
        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorDict)
        }
        return errorDict == nil
    }
}
