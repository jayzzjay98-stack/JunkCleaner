import Foundation
import AppKit

@Observable
final class AppUninstaller {

    var isAnalyzing: Bool = false
    var foundItems: [JunkItem] = []
    var targetApp: AppInfo?
    var analysisProgress: Double = 0
    var analysisSummary: String = ""

    struct AppInfo: Identifiable {
        let id = UUID()
        let name: String
        let bundleID: String
        let version: String
        let path: String
        let iconPath: String?
        var sizeBytes: Int64
    }

    private let fm = FileManager.default
    private var home: String { NSHomeDirectory() }

    // MARK: - วิเคราะห์แอปเพื่อหา ALL related files
    func analyzeApp(at path: String) async {
        guard !isAnalyzing else { return }
        await MainActor.run {
            self.isAnalyzing = true
            self.foundItems = []
            self.targetApp = nil
            self.analysisProgress = 0
            self.analysisSummary = "Analyzing..."
        }

        let appName = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        let plistPath = "\(path)/Contents/Info.plist"

        guard let plist = NSDictionary(contentsOfFile: plistPath),
              let bundleID = plist["CFBundleIdentifier"] as? String else {
            await MainActor.run {
                self.isAnalyzing = false
                self.analysisSummary = "Could not read app bundle"
            }
            return
        }

        let version = plist["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appSize = JunkScanner().calculateDirectorySize(path)

        await MainActor.run {
            self.targetApp = AppInfo(
                name: appName,
                bundleID: bundleID,
                version: version,
                path: path,
                iconPath: nil,
                sizeBytes: appSize
            )
        }

        // สร้าง search terms จาก bundleID และชื่อแอป
        var searchTerms = Set<String>()
        searchTerms.insert(bundleID.lowercased())
        searchTerms.insert(appName.lowercased())
        // เพิ่ม parts ของ bundleID: com.spotify.client → "spotify", "client"
        for part in bundleID.lowercased().split(separator: ".") where part.count > 2 && part != "com" && part != "org" && part != "net" && part != "app" {
            searchTerms.insert(String(part))
        }

        var allFound: [JunkItem] = []

        // paths ที่ต้องค้นหาทั้งหมด
        let searchDirs: [(String, JunkType)] = [
            // USER LEVEL
            ("\(home)/Library/Application Support", .appSupportLeftovers),
            ("\(home)/Library/Preferences", .appPreferences),
            ("\(home)/Library/Caches", .appCaches),
            ("\(home)/Library/Logs", .appLogs),
            ("\(home)/Library/Containers", .appContainers),
            ("\(home)/Library/Group Containers", .appContainers),
            ("\(home)/Library/Saved Application State", .appSavedStates),
            ("\(home)/Library/Application Scripts", .appSupportLeftovers),
            ("\(home)/Library/HTTPStorages", .appSupportLeftovers),
            ("\(home)/Library/WebKit", .appSupportLeftovers),
            ("\(home)/Library/LaunchAgents", .appLaunchAgents),
            ("\(home)/Library/Cookies", .appSupportLeftovers),
            ("\(home)/.config", .appSupportLeftovers),
            ("\(home)/.local/share", .appSupportLeftovers),
            ("\(home)/.cache", .appCaches),
            // SYSTEM LEVEL
            ("/Library/Application Support", .appSupportLeftovers),
            ("/Library/Preferences", .appPreferences),
            ("/Library/Caches", .appCaches),
            ("/Library/Logs", .appLogs),
            ("/Library/LaunchAgents", .appLaunchAgents),
            ("/Library/LaunchDaemons", .appLaunchDaemons),
            ("/Library/PrivilegedHelperTools", .appHelperTools),
            ("/Library/Frameworks", .appFrameworks),
            ("/Library/PreferencePanes", .appSupportLeftovers),
            ("/usr/local/lib", .appSupportLeftovers),
            ("/usr/local/bin", .appSupportLeftovers),
            ("/usr/local/etc", .appSupportLeftovers),
            ("/usr/local/var", .appSupportLeftovers),
            ("/usr/local/share", .appSupportLeftovers),
        ]

        let totalSteps = Double(searchDirs.count + 3)

        for (dir, type) in searchDirs {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else {
                await MainActor.run {
                    self.analysisProgress += 1.0 / totalSteps
                }
                continue
            }
            for entry in entries {
                let entryLower = entry.lowercased()
                let matches = searchTerms.contains(where: { term in
                    entryLower.contains(term) || term.contains(entryLower.replacingOccurrences(of: ".plist", with: ""))
                })
                if !matches { continue }

                let fullPath = "\(dir)/\(entry)"
                // ข้ามถ้าเป็น .app bundle อื่น
                if fullPath.hasSuffix(".app") { continue }
                let scanner = JunkScanner()
                let size = scanner.calculateDirectorySize(fullPath)
                if size < 100 { continue }
                allFound.append(JunkItem(type: type, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: appName))
            }
            await MainActor.run {
                self.analysisProgress += 1.0 / totalSteps
            }
        }

        // ค้นหา dotfiles ใน home: ~/.spotify, ~/.vscode ฯลฯ
        let appNameLower = appName.lowercased()
        if let homeDots = try? fm.contentsOfDirectory(atPath: home) {
            for entry in homeDots where entry.hasPrefix(".") {
                let clean = entry.dropFirst().lowercased()
                if clean.contains(appNameLower) || appNameLower.contains(clean) {
                    if clean == ".trash" || clean == ".ds_store" { continue }
                    let fullPath = "\(home)/\(entry)"
                    let scanner = JunkScanner()
                    let size = scanner.calculateDirectorySize(fullPath)
                    if size > 100 {
                        allFound.append(JunkItem(type: .appSupportLeftovers, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: appName))
                    }
                }
            }
        }

        // pkgutil receipts
        await MainActor.run {
            self.analysisProgress += 1.0 / totalSteps
        }
        let receiptsDir = "/private/var/db/receipts"
        if let receipts = try? fm.contentsOfDirectory(atPath: receiptsDir) {
            for receipt in receipts {
                let rLower = receipt.lowercased()
                if searchTerms.contains(where: { rLower.contains($0) }) {
                    let fullPath = "\(receiptsDir)/\(receipt)"
                    let size = (try? fm.attributesOfItem(atPath: fullPath))?[.size] as? Int64 ?? 0
                    allFound.append(JunkItem(type: .appReceipts, path: fullPath, displayName: receipt, sizeBytes: size, relatedApp: appName))
                }
            }
        }

        // mdfind (Spotlight) — ค้นหาไฟล์ที่อาจหลุดจาก path scan
        await MainActor.run {
            self.analysisProgress += 1.0 / totalSteps
        }
        let mdfindResults = mdfindSearch(bundleID: bundleID, appName: appName)
        for mdPath in mdfindResults {
            // ข้ามถ้า path อยู่ใน allFound แล้ว
            if allFound.contains(where: { $0.path == mdPath }) { continue }
            if mdPath == path { continue } // ข้าม app bundle เอง
            let scanner = JunkScanner()
            let size = scanner.calculateDirectorySize(mdPath)
            if size < 100 { continue }
            let name = (mdPath as NSString).lastPathComponent
            allFound.append(JunkItem(type: .appSupportLeftovers, path: mdPath, displayName: "\(name) (Spotlight)", sizeBytes: size, relatedApp: appName))
        }

        // Deduplicate
        var seen = Set<String>()
        let deduped = allFound.filter { seen.insert($0.path).inserted }

        let totalSize = deduped.reduce(0) { $0 + $1.sizeBytes }
        let formattedTotal: String
        if totalSize >= 1_073_741_824 {
            formattedTotal = String(format: "%.1f GB", Double(totalSize) / 1_073_741_824.0)
        } else {
            formattedTotal = String(format: "%.1f MB", Double(totalSize) / 1_048_576.0)
        }

        await MainActor.run {
            self.foundItems = deduped
            self.isAnalyzing = false
            self.analysisProgress = 1.0
            self.analysisSummary = "Found \(deduped.count) items (\(formattedTotal))"
        }
    }

    // MARK: - mdfind search
    private func mdfindSearch(bundleID: String, appName: String) -> [String] {
        var results: [String] = []
        let queries = [
            "kMDItemCFBundleIdentifier == '\(bundleID)'",
            "kMDItemWhereFroms == '*\(bundleID)*'",
        ]
        for query in queries {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
            process.arguments = [query]
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
                process.waitUntilExit()
                if let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) {
                    let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                    results.append(contentsOf: lines)
                }
            } catch {}
        }
        return results
    }

    // MARK: - Deep Uninstall
    func deepUninstall(app: AppInfo, items: [JunkItem]) async throws {
        // 1. ปิดแอป
        NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == app.bundleID }
            .forEach { $0.forceTerminate() }

        try await Task.sleep(nanoseconds: 500_000_000)

        // 2. ลบ LaunchAgents/Daemons ก่อน (unload)
        let launchItems = items.filter { $0.type == .appLaunchAgents || $0.type == .appLaunchDaemons }
        for item in launchItems {
            unloadLaunchItem(path: item.path)
            try? await Task.sleep(nanoseconds: 100_000_000)
            try? fm.removeItem(atPath: item.path)
        }

        // 3. ลบ .app bundle
        var outURL: NSURL?
        try? fm.trashItem(at: URL(fileURLWithPath: app.path), resultingItemURL: &outURL)

        // 4. ลบไฟล์ที่เหลือ
        for item in items where item.type != .appLaunchAgents && item.type != .appLaunchDaemons {
            var out: NSURL?
            do {
                try fm.trashItem(at: URL(fileURLWithPath: item.path), resultingItemURL: &out)
            } catch {
                // ลองลบตรงถ้า trash ไม่ได้
                try? fm.removeItem(atPath: item.path)
            }
        }

        // 5. ลบ pkgutil receipts
        let receiptItems = items.filter { $0.type == .appReceipts }
        if !receiptItems.isEmpty {
            forgetPackages(bundleID: app.bundleID)
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

    private func forgetPackages(bundleID: String) {
        let script = "do shell script \"pkgutil --forget '\(bundleID)'\" with administrator privileges"
        let appleScript = NSAppleScript(source: script)
        var err: NSDictionary?
        appleScript?.executeAndReturnError(&err)
    }

    // MARK: - ดึงแอปทั้งหมด
    func getAllInstalledApps() -> [AppInfo] {
        var apps: [AppInfo] = []
        let scanner = JunkScanner()
        for dir in ["/Applications", "\(home)/Applications"] {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries where entry.hasSuffix(".app") {
                let appPath = "\(dir)/\(entry)"
                let plistPath = "\(appPath)/Contents/Info.plist"
                guard let plist = NSDictionary(contentsOfFile: plistPath) else { continue }
                let bundleID = plist["CFBundleIdentifier"] as? String ?? "unknown"
                let version = plist["CFBundleShortVersionString"] as? String ?? "?"
                let name = (entry as NSString).deletingPathExtension
                let size = scanner.calculateDirectorySize(appPath)
                apps.append(AppInfo(name: name, bundleID: bundleID, version: version, path: appPath, iconPath: nil, sizeBytes: size))
            }
        }
        return apps.sorted { $0.name < $1.name }
    }
}
