import Foundation
import AppKit

@Observable
final class AppUninstaller {

    var isAnalyzing: Bool = false
    var foundItems: [JunkItem] = []
    var targetApp: AppInfo?

    struct AppInfo: Identifiable {
        let id = UUID()
        let name: String
        let bundleID: String
        let version: String
        let path: String
        let iconPath: String?
        var sizeBytes: Int64
    }

    func analyzeApp(at path: String) async {
        guard !isAnalyzing else { return }
        
        await MainActor.run {
            self.isAnalyzing = true
            self.foundItems = []
            self.targetApp = nil
        }

        // Just a mock implementation
        let lastPathComponent = (path as NSString).lastPathComponent
        let name = (lastPathComponent as NSString).deletingPathExtension
        
        await MainActor.run {
            self.targetApp = AppInfo(name: name, bundleID: "com.mock.\(name.lowercased())", version: "1.0", path: path, iconPath: nil, sizeBytes: 1024 * 1024 * 10)
        }
        
        // Mock finding items
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let junk = JunkItem(type: .appPreferences, path: "~/Library/Preferences/com.mock.\(name.lowercased()).plist", displayName: "Preferences for \(name)", sizeBytes: 1024 * 50, relatedApp: name)
        
        await MainActor.run {
            self.foundItems = [junk]
            self.isAnalyzing = false
        }
    }

    // MARK: - Deep Uninstall ทั้งหมด
    func deepUninstall(app: AppInfo, foundItems: [JunkItem]) async throws {
        // Mock deep uninstall
    }

    // MARK: - ดึงรายชื่อแอปทั้งหมดใน /Applications
    func getAllInstalledApps() -> [AppInfo] {
        let fm = FileManager.default
        let appDir = "/Applications"
        guard let apps = try? fm.contentsOfDirectory(atPath: appDir) else { return [] }
        return apps.filter { $0.hasSuffix(".app") }.map {
            AppInfo(name: ($0 as NSString).deletingPathExtension, bundleID: "com.bundle", version: "1.0", path: (appDir as NSString).appendingPathComponent($0), iconPath: nil, sizeBytes: 50 * 1024 * 1024)
        }
    }
}
