import Foundation
import AppKit
import LocalAuthentication

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
    func clean(items: [JunkItem], requireAuth: Bool = true) async {
        guard !isDeleting else { return }

        // Touch ID authentication
        if requireAuth {
            let authSuccess = await authenticate(reason: "JunkCleaner needs to delete \(items.count) junk files")
            guard authSuccess else {
                await MainActor.run { self.lastResult = CleanResult(freedBytes: 0, deletedCount: 0, failedCount: 0, duration: 0) }
                return
            }
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
        var freed: Int64 = 0
        var successCount = 0
        var failCount = 0

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
                successCount += 1
                freed += item.sizeBytes
                await MainActor.run {
                    self.deletedItems.append(item)
                    self.totalFreedBytes = freed
                }
            } catch {
                failCount += 1
                let reason = error.localizedDescription
                await MainActor.run {
                    self.failedItems.append((item, reason))
                }
            }
        }

        let duration = Date().timeIntervalSince(start)
        await MainActor.run {
            self.lastResult = CleanResult(freedBytes: freed, deletedCount: successCount, failedCount: failCount, duration: duration)
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

    // MARK: - Admin delete ผ่าน AppleScript
    private func deleteWithAdmin(path: String) async throws {
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        let script = "do shell script \"rm -rf '\(escaped)'\" with administrator privileges"
        
        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&errorDict)
        } else {
            throw NSError(domain: "JunkCleaner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AppleScript"])
        }
        
        // ถ้า fail ให้ลอง retry ท่า Process() sudo rm -rf
        if let err = errorDict {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            p.arguments = ["rm", "-rf", path]
            p.standardOutput = FileHandle.nullDevice
            p.standardError = FileHandle.nullDevice
            
            do {
                try p.run()
                p.waitUntilExit()
                if p.terminationStatus != 0 {
                    let msg = err[NSAppleScript.errorMessage] as? String ?? "Admin delete failed"
                    throw NSError(domain: "JunkCleaner", code: Int(p.terminationStatus), userInfo: [NSLocalizedDescriptionKey: msg])
                }
            } catch {
                let msg = err[NSAppleScript.errorMessage] as? String ?? "Admin delete failed"
                throw NSError(domain: "JunkCleaner", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
            }
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

    // MARK: - Touch ID Authentication
    private func authenticate(reason: String) async -> Bool {
        await withCheckedContinuation { continuation in
            let context = LAContext()
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                    continuation.resume(returning: success)
                }
            } else {
                // Touch ID ไม่มี → ข้ามได้เลย
                continuation.resume(returning: true)
            }
        }
    }
}
