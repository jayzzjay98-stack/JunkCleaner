import Foundation
import AppKit

@Observable
final class JunkScanner {

    // MARK: - State
    var isScanning: Bool = false
    var scanProgress: Double = 0        // 0.0 - 1.0
    var currentScanTask: String = ""    // "Scanning ~/Library/Caches..."
    var scanResult: ScanResult?
    var lastError: String?
    var totalJunkGB: Double = 0

    // MARK: - Settings
    var selectedTypes: Set<JunkType> = Set(JunkType.allCases)  // ทุก type เปิดไว้
    var minimumFileSizeMB: Double = 0.1
    
    private var isCancelled: Bool = false

    // MARK: - Main Scan Function
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
        var items: [JunkItem] = []
        
        let actions: [(String, () async -> [JunkItem])] = [
            ("Scanning App Leftovers...", scanAppLeftovers),
            ("Scanning System Caches...", scanSystemCaches),
            ("Scanning App Logs...", scanLogs),
            ("Scanning Temporary Files...", scanTempFiles),
            ("Scanning Developer Junk...", scanDeveloperJunk),
            ("Scanning Language Packs...", scanLanguagePacks),
            ("Scanning iOS Backups/Support...", scanIOSRelated),
            ("Scanning Old Downloads...", scanOldDownloads),
            ("Scanning Mail Cache...", scanMailCache),
            ("Scanning Browser Caches...", scanBrowserCaches)
        ]

        await withTaskGroup(of: [JunkItem].self) { group in
            for (index, action) in actions.enumerated() {
                group.addTask {
                    let result = await action.1()
                    return result
                }
            }

            var completedTasks = 0
            for await resultItems in group {
                if isCancelled { break }
                items.append(contentsOf: resultItems)
                completedTasks += 1
                
                await MainActor.run {
                    self.scanProgress = Double(completedTasks) / Double(actions.count)
                }
            }
        }
        
        let finalItems = items.filter { item in
            self.selectedTypes.contains(item.type) &&
            item.sizeMB >= self.minimumFileSizeMB
        }
        
        let result = ScanResult(
            items: finalItems,
            scanDuration: Date().timeIntervalSince(startTime)
        )

        await MainActor.run {
            self.scanResult = result
            self.totalJunkGB = result.totalSize > 0 ? Double(result.totalSize) / 1_073_741_824.0 : 0
            self.isScanning = false
            self.currentScanTask = ""
            if self.isCancelled {
                self.lastError = "Scan cancelled"
            }
        }
    }

    func cancelScan() {
        isCancelled = true
        isScanning = false
        currentScanTask = "Cancelled"
    }

    // MARK: - 1. APP LEFTOVERS
    private func scanAppLeftovers() async -> [JunkItem] {
        await MainActor.run { self.currentScanTask = "Scanning App Leftovers..." }
        var junk: [JunkItem] = []
        let fm = FileManager.default
        let home = NSHomeDirectory()
        
        let leftoverPaths = [
            "\(home)/Library/Application Support/",
            "\(home)/Library/Preferences/",
            "\(home)/Library/Caches/",
            "\(home)/Library/Logs/",
            "\(home)/Library/Containers/"
        ]
        
        // Mocking leftover items for now, ideally iterating through directories
        // and using NSWorkspace to check for installed apps.
        // For demonstration, let's keep it simple.
        for path in leftoverPaths {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { continue }
            for item in contents {
                let fullPath = (path as NSString).appendingPathComponent(item)
                guard isDirectoryMissingApp(bundleIDOrName: item) else { continue }
                
                let size = calculateDirectorySize(fullPath)
                if size > 0 {
                    junk.append(JunkItem(type: .appSupportLeftovers, path: fullPath, displayName: item, sizeBytes: size, relatedApp: item))
                }
            }
        }
        return junk
    }

    // Checking if an app exists based on bundle ID or name
    private func isDirectoryMissingApp(bundleIDOrName: String) -> Bool {
        // Simple heuristic: if it begins with com.apple., we skip (pretend it's installed)
        if bundleIDOrName.hasPrefix("com.apple.") { return false }
        
        // Typically we would ask NSWorkspace if app exists
        // Here we just mock randomly for now or return false so we don't accidentally delete actual apps
        // Actually, returning true for something like "com.adobe.fake" would list it, let's just make sure it's safe.
        return false 
    }

    // MARK: - 2. SYSTEM CACHES
    private func scanSystemCaches() async -> [JunkItem] {
        await MainActor.run { self.currentScanTask = "Scanning System Caches..." }
        var junk: [JunkItem] = []
        let home = NSHomeDirectory()
        let paths = ["\(home)/Library/Caches/", "/Library/Caches/"]
        
        let fm = FileManager.default
        for path in paths {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { continue }
            for item in contents {
                if item.hasPrefix("com.apple.") { continue } // Skip Apple caches
                let fullPath = (path as NSString).appendingPathComponent(item)
                let size = calculateDirectorySize(fullPath)
                if size > 0 {
                    junk.append(JunkItem(type: .systemCaches, path: fullPath, displayName: item, sizeBytes: size, relatedApp: nil))
                }
            }
        }
        return junk
    }

    // MARK: - 3. APP LOGS
    private func scanLogs() async -> [JunkItem] {
        var junk: [JunkItem] = []
        let home = NSHomeDirectory()
        let paths = ["\(home)/Library/Logs/"]
        
        let fm = FileManager.default
        for path in paths {
            guard let contents = try? fm.contentsOfDirectory(atPath: path) else { continue }
            for item in contents {
                let fullPath = (path as NSString).appendingPathComponent(item)
                let size = calculateDirectorySize(fullPath)
                if size > 0 {
                    junk.append(JunkItem(type: .appLogs, path: fullPath, displayName: item, sizeBytes: size, relatedApp: nil))
                }
            }
        }
        return junk
    }

    // MARK: - 4. TEMP FILES
    private func scanTempFiles() async -> [JunkItem] {
        var junk: [JunkItem] = []
        let trashPath = "\(NSHomeDirectory())/.Trash"
        let size = calculateDirectorySize(trashPath)
        if size > 0 {
            junk.append(JunkItem(type: .trashContents, path: trashPath, displayName: "Trash", sizeBytes: size, relatedApp: nil))
        }
        return junk
    }

    // MARK: - 5. DEVELOPER JUNK
    private func scanDeveloperJunk() async -> [JunkItem] {
        var junk: [JunkItem] = []
        let home = NSHomeDirectory()
        let derivedData = "\(home)/Library/Developer/Xcode/DerivedData"
        let size = calculateDirectorySize(derivedData)
        if size > 0 {
            junk.append(JunkItem(type: .xcodeDerivedData, path: derivedData, displayName: "Xcode DerivedData", sizeBytes: size, relatedApp: "Xcode"))
        }
        return junk
    }

    // MARK: - 6. LANGUAGE PACKS
    private func scanLanguagePacks() async -> [JunkItem] {
        return []
    }

    // MARK: - 7. iOS/iPadOS RELATED
    private func scanIOSRelated() async -> [JunkItem] {
        return []
    }

    // MARK: - 8. DOWNLOADS (เก่า)
    private func scanOldDownloads() async -> [JunkItem] {
        return []
    }

    // MARK: - 9. MAIL CACHE
    private func scanMailCache() async -> [JunkItem] {
        return []
    }

    // MARK: - 10. SAFARI / BROWSERS
    private func scanBrowserCaches() async -> [JunkItem] {
        return []
    }

    // MARK: - Helper: คำนวณขนาดโฟลเดอร์
    private func calculateDirectorySize(_ path: String) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            let attrs = try? fm.attributesOfItem(atPath: path)
            return attrs?[.size] as? Int64 ?? 0
        }
        
        var size: Int64 = 0
        if let enumerator = fm.enumerator(atPath: path) {
            for file in enumerator {
                if let fileName = file as? String {
                    let fullPath = (path as NSString).appendingPathComponent(fileName)
                    let attrs = try? fm.attributesOfItem(atPath: fullPath)
                    size += attrs?[.size] as? Int64 ?? 0
                }
            }
        }
        return size
    }

    private func safeExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
