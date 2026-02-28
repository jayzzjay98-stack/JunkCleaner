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

        // ขอ admin ครั้งเดียว — เขียน sudoers + ทดสอบว่าใช้งานได้จริง
        // ถ้า user กด Cancel หรือใส่รหัสผิด ให้หยุดทั้งหมด
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
        await MainActor.run {
            self.lastResult = CleanResult(
                freedBytes: self.totalFreedBytes,
                deletedCount: self.deletedItems.count,
                failedCount: self.failedItems.count,
                duration: duration
            )
            self.isDeleting = false
            self.deleteProgress = 1.0
            self.currentDeleteTask = "Done!"
        }
    }

    // MARK: - ลบไฟล์เดียว (ไม่ขอรหัสซ้ำ เพราะ sudoers พร้อมแล้ว)
    private func deleteItem(_ item: JunkItem) async throws {
        let path = item.path
        let url = URL(fileURLWithPath: path)
        guard fm.fileExists(atPath: path) else { return }

        // LaunchAgent/Daemon: unload ก่อน
        if item.type == .appLaunchAgents || item.type == .appLaunchDaemons {
            unloadLaunchItem(path: path)
            try? await Task.sleep(nanoseconds: 300_000_000)
        }

        // pkgutil receipt
        if item.type == .appReceipts {
            let packageID = (path as NSString).lastPathComponent
                .replacingOccurrences(of: ".plist", with: "")
                .replacingOccurrences(of: ".bom", with: "")
            try sudoRm(path: "/private/var/db/receipts/\(packageID).plist")
            try sudoRm(path: "/private/var/db/receipts/\(packageID).bom")
            return
        }

        // ไฟล์ใน system paths → ใช้ sudo rm ทันที (sudoers พร้อมแล้ว ไม่ขอรหัส)
        if path.hasPrefix("/Library/") || path.hasPrefix("/private/") || path.hasPrefix("/usr/") {
            try sudoRm(path: path)
            return
        }

        // ไฟล์ยูสเซอร์ทั่วไป ลบ Trash โดยตรง ไม่ให้ซ้อนโฟลเดอร์ในถังขยะ
        if item.type == .trashContents {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return }
            for file in contents {
                let filePath = "\(path)/\(file)"
                if (try? fm.removeItem(atPath: filePath)) == nil {
                    try sudoRm(path: filePath)
                }
            }
            return
        }

        // ไฟล์ user level → trash ก่อน ถ้าไม่ได้ค่อย sudo rm
        var outURL: NSURL?
        do {
            try fm.trashItem(at: url, resultingItemURL: &outURL)
        } catch {
            try sudoRm(path: path)
        }
    }

    // MARK: - sudo rm -rf (ไม่มี popup เพราะ sudoers อนุญาตแล้ว)
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

    // MARK: - Setup Admin (ขอรหัสครั้งเดียว เขียน sudoers + ทดสอบ)
    // ใช้ async เพื่อรัน AppleScript บน background thread ไม่ block UI
    private func setupAdminPersistent() async -> Bool {
        // ทดสอบก่อนว่า sudoers มีแล้วหรือยัง (ถ้ามีแล้วไม่ต้องขอรหัสซ้ำ)
        if isSudoersReady() { return true }

        // ยังไม่มี sudoers → ขอรหัส 1 ครั้ง เพื่อเขียน sudoers
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let user = NSUserName()
                let sudoersFile = "/private/etc/sudoers.d/junkcleaner_\(user)"
                let rule = "\(user) ALL=(ALL) NOPASSWD: /bin/rm"

                // สร้าง sudoers + ทดสอบว่าใช้งานได้ทันที ในคำสั่งเดียว
                let script = """
                do shell script "mkdir -p /private/etc/sudoers.d && echo '\(rule)' > \(sudoersFile) && chmod 440 \(sudoersFile) && /usr/bin/sudo -n /bin/rm -f /dev/null" with prompt "JunkCleaner ต้องการรหัสผ่านครั้งเดียว เพื่อลบไฟล์ขยะโดยไม่ถามซ้ำ" with administrator privileges
                """
                var errorDict: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&errorDict)
                continuation.resume(returning: errorDict == nil)
            }
        }
    }

    // เช็คว่า sudoers file มีอยู่และ sudo -n ใช้งานได้จริงไหม
    private func isSudoersReady() -> Bool {
        let user = NSUserName()
        let sudoersFile = "/private/etc/sudoers.d/junkcleaner_\(user)"
        guard fm.fileExists(atPath: sudoersFile) else { return false }

        // ทดสอบ sudo -n จริง
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
