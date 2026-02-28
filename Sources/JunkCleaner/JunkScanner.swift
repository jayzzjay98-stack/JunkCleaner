import Foundation
import AppKit

@Observable
final class JunkScanner {

    // MARK: - State
    var isScanning: Bool = false
    var scanProgress: Double = 0
    var currentScanTask: String = ""
    var scanResult: ScanResult?
    var lastError: String?
    var totalJunkGB: Double = 0

    var selectedTypes: Set<JunkType> = Set(JunkType.allCases)
    var minimumFileSizeMB: Double = 0.01

    private var isCancelled: Bool = false
    private let fm = FileManager.default
    private var home: String { NSHomeDirectory() }

    func startScan() async {
        guard !isScanning else { return }
        await MainActor.run {
            self.isScanning = true
            self.isCancelled = false
            self.scanProgress = 0.0
            self.currentScanTask = "Starting scan..."
            self.scanResult = nil
            self.lastError = nil
            self.totalJunkGB = 0
        }

        let startTime = Date()
        var allItems: [JunkItem] = []

        let steps: [(String, () async -> [JunkItem])] = [
            ("Scanning App Leftovers...", scanAppLeftovers),
            ("Scanning System Caches...", scanSystemCaches),
            ("Scanning Logs & Crash Reports...", scanLogs),
            ("Scanning Temporary Files & Trash...", scanTempFiles),
            ("Scanning Developer Junk...", scanDeveloperJunk),
            ("Scanning Language Packs...", scanLanguagePacks),
            ("Scanning iOS Backups...", scanIOSRelated),
            ("Scanning Old Downloads...", scanOldDownloads),
            ("Scanning Mail Cache...", scanMailCache),
            ("Scanning Browser Caches...", scanBrowserCaches),
        ]

        for (i, (label, fn)) in steps.enumerated() {
            if isCancelled { break }
            await MainActor.run { self.currentScanTask = label }
            let found = await fn()
            allItems.append(contentsOf: found)
            let progress = Double(i + 1) / Double(steps.count)
            await MainActor.run { self.scanProgress = progress }
        }

        let filtered = allItems.filter {
            selectedTypes.contains($0.type) && $0.sizeMB >= minimumFileSizeMB
        }
        var seen = Set<String>()
        let deduped = filtered.filter { seen.insert($0.path).inserted }

        let result = ScanResult(items: deduped, scanDuration: Date().timeIntervalSince(startTime))
        await MainActor.run {
            self.scanResult = result
            self.totalJunkGB = Double(result.totalSize) / 1_073_741_824.0
            self.isScanning = false
            self.currentScanTask = isCancelled ? "Cancelled" : "Scan complete"
        }
    }

    func cancelScan() {
        isCancelled = true
        isScanning = false
    }

    // MARK: - 1. APP LEFTOVERS
    private func scanAppLeftovers() async -> [JunkItem] {
        var junk: [JunkItem] = []
        var installedBundleIDs = Set<String>()
        var installedNames = Set<String>()

        let appDirs = ["/Applications", "\(home)/Applications"]
        for dir in appDirs {
            guard let apps = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for app in apps where app.hasSuffix(".app") {
                if let bid = readBundleID(appPath: "\(dir)/\(app)") {
                    installedBundleIDs.insert(bid.lowercased())
                    for p in bid.lowercased().split(separator: ".") where p.count > 2 && p != "com" && p != "org" && p != "net" && p != "app" {
                        installedNames.insert(String(p))
                    }
                }
                installedNames.insert((app as NSString).deletingPathExtension.lowercased())
            }
        }
        for app in NSWorkspace.shared.runningApplications {
            if let bid = app.bundleIdentifier { installedBundleIDs.insert(bid.lowercased()) }
            if let name = app.localizedName { installedNames.insert(name.lowercased()) }
        }

        func isOrphaned(_ entry: String) -> Bool {
            let e = entry.lowercased()
                .replacingOccurrences(of: ".plist", with: "")
                .replacingOccurrences(of: ".savedstate", with: "")
            if isAppleSystemPath(entry) { return false }
            if installedBundleIDs.contains(where: { e == $0 || e.hasPrefix($0) || $0.hasPrefix(e) }) { return false }
            if installedNames.contains(where: { e.contains($0) }) { return false }
            return true
        }

        let searchDirs: [(String, JunkType)] = [
            ("\(home)/Library/Application Support", .appSupportLeftovers),
            ("\(home)/Library/Preferences", .appPreferences),
            ("\(home)/Library/Caches", .appCaches),
            ("\(home)/Library/Logs", .appLogs),
            ("\(home)/Library/Containers", .appContainers),
            ("\(home)/Library/Saved Application State", .appSavedStates),
            ("\(home)/Library/HTTPStorages", .appSupportLeftovers),
            ("\(home)/Library/WebKit", .appSupportLeftovers),
            ("\(home)/Library/Application Scripts", .appSupportLeftovers),
            ("/Library/Application Support", .appSupportLeftovers),
            ("/Library/Preferences", .appPreferences),
            ("/Library/Caches", .appCaches),
            ("/Library/Logs", .appLogs),
        ]
        for (dir, type) in searchDirs {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries {
                guard isOrphaned(entry) else { continue }
                let e = entry.lowercased()
                let hasAppPattern = e.contains(".") && (e.hasPrefix("com.") || e.hasPrefix("org.") || e.hasPrefix("net.") || e.hasSuffix(".savedstate") || e.hasSuffix(".plist"))
                if type == .appPreferences && !hasAppPattern { continue }
                let fullPath = "\(dir)/\(entry)"
                let size = calculateDirectorySize(fullPath)
                if size < 1024 { continue }
                junk.append(JunkItem(type: type, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: extractAppName(from: entry)))
            }
        }

        // LaunchAgents / Daemons / HelperTools
        let launchDirs: [(String, JunkType)] = [
            ("\(home)/Library/LaunchAgents", .appLaunchAgents),
            ("/Library/LaunchAgents", .appLaunchAgents),
            ("/Library/LaunchDaemons", .appLaunchDaemons),
            ("/Library/PrivilegedHelperTools", .appHelperTools),
        ]
        for (dir, type) in launchDirs {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries {
                guard isOrphaned(entry) else { continue }
                let fullPath = "\(dir)/\(entry)"
                let size = calculateFileSize(fullPath)
                if size < 100 { continue }
                junk.append(JunkItem(type: type, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: extractAppName(from: entry)))
            }
        }

        // Crash Reports
        for dir in ["\(home)/Library/Logs/DiagnosticReports", "/Library/Logs/DiagnosticReports"] {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries where entry.hasSuffix(".crash") || entry.hasSuffix(".ips") || entry.hasSuffix(".spin") {
                let fullPath = "\(dir)/\(entry)"
                let size = calculateFileSize(fullPath)
                if size < 1024 { continue }
                junk.append(JunkItem(type: .appCrashReports, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: nil))
            }
        }

        // pkgutil receipts
        let receiptsDir = "/private/var/db/receipts"
        if let entries = try? fm.contentsOfDirectory(atPath: receiptsDir) {
            for entry in entries where entry.hasSuffix(".plist") || entry.hasSuffix(".bom") {
                guard isOrphaned(entry) else { continue }
                let fullPath = "\(receiptsDir)/\(entry)"
                let size = calculateFileSize(fullPath)
                if size < 100 { continue }
                junk.append(JunkItem(type: .appReceipts, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: nil))
            }
        }

        return junk
    }

    // MARK: - 2. SYSTEM CACHES
    private func scanSystemCaches() async -> [JunkItem] {
        var junk: [JunkItem] = []
        let cacheDirs = [
            "\(home)/Library/Caches/com.apple.Safari",
            "\(home)/Library/Caches/com.apple.dt.Xcode",
            "/private/var/folders",
        ]
        for dir in cacheDirs {
            if dir == "/private/var/folders" {
                // Special handling for /private/var/folders using Process
                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/bin/sh")
                p.arguments = ["-c", "du -s /private/var/folders/*/*/C/* 2>/dev/null"]
                let pipe = Pipe()
                p.standardOutput = pipe
                try? p.run()
                p.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines {
                        let parts = line.split(separator: "\t", maxSplits: 1)
                        if parts.count == 2 {
                            let sizeBlocks = Int64(parts[0]) ?? 0
                            let sizeBytes = sizeBlocks * 512
                            if sizeBytes >= 1024 * 10 { // > 10KB
                                let path = String(parts[1])
                                let name = (path as NSString).lastPathComponent
                                junk.append(JunkItem(type: .systemCaches, path: path, displayName: name, sizeBytes: sizeBytes, relatedApp: nil))
                            }
                        }
                    }
                }
            } else {
                guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
                for entry in entries {
                    if isAppleSystemPath(entry) { continue }
                    let fullPath = "\(dir)/\(entry)"
                    let size = calculateDirectorySize(fullPath)
                    if size < 1024 * 10 { continue }
                    junk.append(JunkItem(type: .systemCaches, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: nil))
                }
            }
        }
        return junk
    }

    // MARK: - 3. LOGS
    private func scanLogs() async -> [JunkItem] {
        var junk: [JunkItem] = []
        for dir in ["\(home)/Library/Logs", "/Library/Logs", "/private/var/log"] {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries {
                if isAppleSystemPath(entry) { continue }
                let fullPath = "\(dir)/\(entry)"
                if let attrs = try? fm.attributesOfItem(atPath: fullPath),
                   let mod = attrs[.modificationDate] as? Date,
                   Date().timeIntervalSince(mod) < 86400 { continue }
                let size = calculateDirectorySize(fullPath)
                if size < 1024 { continue }
                junk.append(JunkItem(type: .systemLogs, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: nil))
            }
        }
        return junk
    }

    // MARK: - 4. TEMP FILES & TRASH
    private func scanTempFiles() async -> [JunkItem] {
        var junk: [JunkItem] = []

        let trashPath = "\(home)/.Trash"
        let trashSize = calculateDirectorySize(trashPath)
        if trashSize > 0 {
            junk.append(JunkItem(type: .trashContents, path: trashPath, displayName: "Trash", sizeBytes: trashSize, relatedApp: nil))
        }
        if let vols = try? fm.contentsOfDirectory(atPath: "/Volumes") {
            for vol in vols {
                let tp = "/Volumes/\(vol)/.Trashes"
                let size = calculateDirectorySize(tp)
                if size > 0 {
                    junk.append(JunkItem(type: .trashContents, path: tp, displayName: "Trash (\(vol))", sizeBytes: size, relatedApp: nil))
                }
            }
        }

        for dir in ["/private/tmp", "/private/var/tmp", NSTemporaryDirectory()] {
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for entry in entries {
                let fullPath = "\(dir)/\(entry)"
                guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                      let mod = attrs[.modificationDate] as? Date,
                      Date().timeIntervalSince(mod) > 3600 else { continue }
                let size = calculateDirectorySize(fullPath)
                if size < 1024 { continue }
                junk.append(JunkItem(type: .systemTempFiles, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: nil))
            }
        }

        let tempItems = "\(home)/Library/Caches/TemporaryItems"
        let tempSize = calculateDirectorySize(tempItems)
        if tempSize > 0 {
            junk.append(JunkItem(type: .systemTempFiles, path: tempItems, displayName: "TemporaryItems", sizeBytes: tempSize, relatedApp: nil))
        }
        return junk
    }

    // MARK: - 5. DEVELOPER JUNK
    private func scanDeveloperJunk() async -> [JunkItem] {
        var junk: [JunkItem] = []
        let devBase = "\(home)/Library/Developer"

        let singlePaths: [(String, JunkType, String, String)] = [
            ("\(devBase)/Xcode/DerivedData", .xcodeDerivedData, "Xcode DerivedData", "Xcode"),
            ("\(devBase)/CoreSimulator/Caches", .xcodeSimulators, "Simulator Caches", "Xcode"),
            ("\(devBase)/Xcode/iOS Device Logs", .appLogs, "iOS Device Logs", "Xcode"),
            ("\(devBase)/Xcode/DocumentationCache", .xcodeDocsets, "Xcode Documentation Cache", "Xcode"),
            ("\(home)/Library/Caches/Homebrew", .brewCache, "Homebrew Cache", "Homebrew"),
            ("/opt/homebrew/var/cache", .brewCache, "Homebrew Cache (opt)", "Homebrew"),
            ("\(home)/.npm/_cacache", .npmCache, "npm Cache", "npm"),
            ("\(home)/.npm/tmp", .npmCache, "npm Temp", "npm"),
            ("\(home)/Library/Caches/node-gyp", .npmCache, "node-gyp Cache", "npm"),
            ("\(home)/.yarn/cache", .yarnCache, "Yarn Cache", "Yarn"),
            ("\(home)/.cache/yarn", .yarnCache, "Yarn Cache", "Yarn"),
            ("\(home)/Library/Caches/pip", .pipCache, "pip Cache", "pip"),
            ("\(home)/.cache/pip", .pipCache, "pip Cache", "pip"),
            ("\(home)/.gradle/caches", .gradleCache, "Gradle Cache", "Gradle"),
            ("\(home)/.gradle/wrapper/dists", .gradleCache, "Gradle Wrapper Dists", "Gradle"),
            ("\(home)/.m2/repository", .mavenCache, "Maven Repository", "Maven"),
            ("\(home)/Library/Caches/CocoaPods", .podCache, "CocoaPods Cache", "CocoaPods"),
            ("\(home)/.cocoapods/repos", .podCache, "CocoaPods Repos Index", "CocoaPods"),
            ("\(home)/.gem/specs", .gemCache, "Ruby Gem Specs", "Ruby"),
            ("\(home)/Library/Caches/JetBrains", .appCaches, "JetBrains Cache", "JetBrains"),
            ("\(home)/Library/Logs/JetBrains", .appLogs, "JetBrains Logs", "JetBrains"),
            ("\(home)/Library/Containers/com.docker.docker/Data/vms", .dockerImages, "Docker VM Data", "Docker"),
        ]
        for (path, type, name, app) in singlePaths {
            let size = calculateDirectorySize(path)
            if size > 0 {
                junk.append(JunkItem(type: type, path: path, displayName: name, sizeBytes: size, relatedApp: app))
            }
        }

        // Xcode Archives (เก็บ 3 ล่าสุด)
        let archivesDir = "\(devBase)/Xcode/Archives"
        if let yearDirs = try? fm.contentsOfDirectory(atPath: archivesDir) {
            for year in yearDirs {
                let yearPath = "\(archivesDir)/\(year)"
                if let archives = try? fm.contentsOfDirectory(atPath: yearPath) {
                    for arch in archives.sorted().dropLast(3) {
                        let p = "\(yearPath)/\(arch)"
                        let size = calculateDirectorySize(p)
                        if size > 0 {
                            junk.append(JunkItem(type: .xcodeArchives, path: p, displayName: arch, sizeBytes: size, relatedApp: "Xcode"))
                        }
                    }
                }
            }
        }

        return junk
    }

    // MARK: - 6. LANGUAGE PACKS
    private func scanLanguagePacks() async -> [JunkItem] {
        // ไม่สแกน language packs เพราะการลบ .lproj ภายใน .app bundle
        // จะทำให้ macOS code signature พัง → แอปเปิดไม่ได้
        // ต้องใช้ codesign --deep --force resign หลังลบ ซึ่งซับซ้อนเกินไป
        return []
    }

    // MARK: - 7. iOS RELATED
    private func scanIOSRelated() async -> [JunkItem] {
        var junk: [JunkItem] = []

        let backupsDir = "\(home)/Library/Application Support/MobileSync/Backup"
        if let backups = try? fm.contentsOfDirectory(atPath: backupsDir) {
            let dated = backups.compactMap { b -> (String, Date)? in
                let bp = "\(backupsDir)/\(b)"
                guard let attrs = try? fm.attributesOfItem(atPath: bp),
                      let mod = attrs[.modificationDate] as? Date else { return nil }
                return (bp, mod)
            }.sorted { $0.1 > $1.1 }
            for (path, _) in dated.dropFirst(1) {
                let size = calculateDirectorySize(path)
                let name = (path as NSString).lastPathComponent
                junk.append(JunkItem(type: .iosBackups, path: path, displayName: "iOS Backup: \(name)", sizeBytes: size, relatedApp: "Finder"))
            }
        }

        let devBase = "\(home)/Library/Developer/Xcode"
        for (label, dir, type) in [
            ("iOS DeviceSupport", "\(devBase)/iOS DeviceSupport", JunkType.iosDeviceSupport),
            ("watchOS DeviceSupport", "\(devBase)/watchOS DeviceSupport", JunkType.iosDeviceSupport),
            ("tvOS DeviceSupport", "\(devBase)/tvOS DeviceSupport", JunkType.iosDeviceSupport),
        ] {
            guard let versions = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for ver in versions.sorted().dropLast(2) {
                let p = "\(dir)/\(ver)"
                let size = calculateDirectorySize(p)
                if size > 0 {
                    junk.append(JunkItem(type: type, path: p, displayName: "\(label): \(ver)", sizeBytes: size, relatedApp: "Xcode"))
                }
            }
        }
        return junk
    }

    // MARK: - 8. OLD DOWNLOADS
    private func scanOldDownloads() async -> [JunkItem] {
        var junk: [JunkItem] = []
        let downloadsPath = "\(home)/Downloads"
        guard let entries = try? fm.contentsOfDirectory(atPath: downloadsPath) else { return [] }
        let cutoff = Date().addingTimeInterval(-90 * 24 * 3600)

        for entry in entries {
            let fullPath = "\(downloadsPath)/\(entry)"
            guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                  let mod = attrs[.modificationDate] as? Date,
                  mod < cutoff else { continue }
            let size = calculateDirectorySize(fullPath)
            if size < 1024 * 100 { continue }
            junk.append(JunkItem(type: .downloadsOld, path: fullPath, displayName: entry, sizeBytes: size, relatedApp: nil))
        }
        return junk
    }

    // MARK: - 9. MAIL CACHE
    private func scanMailCache() async -> [JunkItem] {
        var junk: [JunkItem] = []
        for version in ["V10", "V9", "V8", "V7"] {
            let attachPath = "\(home)/Library/Mail/\(version)/Attachments"
            let size = calculateDirectorySize(attachPath)
            if size > 0 {
                junk.append(JunkItem(type: .mailAttachments, path: attachPath, displayName: "Mail Attachment Downloads", sizeBytes: size, relatedApp: "Mail"))
                break
            }
        }
        return junk
    }

    // MARK: - 10. BROWSER CACHES
    private func scanBrowserCaches() async -> [JunkItem] {
        var junk: [JunkItem] = []
        let browsers: [(String, [String], JunkType)] = [
            ("Safari",  ["\(home)/Library/Caches/com.apple.Safari", "\(home)/Library/Safari/LocalStorage", "\(home)/Library/WebKit/com.apple.Safari"], .safariCache),
            ("Chrome",  ["\(home)/Library/Caches/Google/Chrome", "\(home)/Library/Application Support/Google/Chrome/Default/Code Cache"], .chromeCache),
            ("Brave",   ["\(home)/Library/Caches/BraveSoftware", "\(home)/Library/Application Support/BraveSoftware/Brave-Browser/Default/Code Cache"], .chromeCache),
            ("Firefox", ["\(home)/Library/Caches/Firefox", "\(home)/Library/Caches/Mozilla"], .firefoxCache),
            ("Arc",     ["\(home)/Library/Caches/Arc", "\(home)/Library/Caches/company.thebrowser.Browser"], .chromeCache),
            ("Edge",    ["\(home)/Library/Caches/Microsoft Edge"], .chromeCache),
            ("Opera",   ["\(home)/Library/Caches/com.operasoftware.Opera"], .chromeCache),
        ]
        for (name, paths, type) in browsers {
            for path in paths {
                let size = calculateDirectorySize(path)
                if size > 0 {
                    let dirName = (path as NSString).lastPathComponent
                    junk.append(JunkItem(type: type, path: path, displayName: "\(name): \(dirName)", sizeBytes: size, relatedApp: name))
                }
            }
        }
        return junk
    }

    // MARK: - Helpers
    func calculateDirectorySize(_ path: String) -> Int64 {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }
        if !isDir.boolValue { return calculateFileSize(path) }

        var total: Int64 = 0
        if let enumerator = fm.enumerator(at: URL(fileURLWithPath: path),
                                           includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                                           options: []) {
            for case let url as URL in enumerator {
                if let rv = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                   rv.isRegularFile == true, let sz = rv.fileSize {
                    total += Int64(sz)
                }
            }
        }
        return total
    }

    private func calculateFileSize(_ path: String) -> Int64 {
        (try? fm.attributesOfItem(atPath: path))?[.size] as? Int64 ?? 0
    }

    func readBundleID(appPath: String) -> String? {
        guard let plist = NSDictionary(contentsOfFile: "\(appPath)/Contents/Info.plist") else { return nil }
        return plist["CFBundleIdentifier"] as? String
    }

    private func isAppleSystemPath(_ name: String) -> Bool {
        let n = name.lowercased()
            .replacingOccurrences(of: ".plist", with: "")
            .replacingOccurrences(of: ".savedstate", with: "")

        // บล็อค com.apple.* ทั้งหมด
        // ยกเว้น Apple apps ที่ user ซื้อ/download เองซึ่งมี leftover จริง
        if n.hasPrefix("com.apple.") {
            // Apple apps ที่อนุญาตให้ลบ leftover ได้ (user-facing apps)
            let allowedAppleApps = [
                "com.apple.garageband",
                "com.apple.imovie",
                "com.apple.logic",
                "com.apple.finalcutpro",
                "com.apple.motionapp",
                "com.apple.compressor",
                "com.apple.mainstagemac",
                "com.apple.numbers",
                "com.apple.pages",
                "com.apple.keynote",
            ]
            return !allowedAppleApps.contains(where: { n.hasPrefix($0) })
        }

        // บล็อค system binary paths
        let systemPaths = ["/system/", "/usr/bin/", "/usr/sbin/", "/usr/lib/",
                           "/bin/", "/sbin/", "/library/apple/"]
        return systemPaths.contains(where: { n.hasPrefix($0) })
    }

    private func extractAppName(from entry: String) -> String? {
        let without = (entry as NSString).deletingPathExtension
        let parts = without.split(separator: ".")
        if parts.count >= 3 { return parts.dropFirst(2).joined(separator: " ") }
        return without.isEmpty ? nil : without
    }

    // MARK: - Disk Info
    func getDiskInfo() -> (totalGB: Double, freeGB: Double) {
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = attrs?[.systemSize] as? Int64 ?? 0
        let free = attrs?[.systemFreeSize] as? Int64 ?? 0
        return (Double(total) / 1_073_741_824.0, Double(free) / 1_073_741_824.0)
    }
}
