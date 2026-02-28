import Foundation

// MARK: - ประเภทของขยะทั้งหมดที่สแกน
enum JunkType: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    // App Leftovers (หลังลบแอป)
    case appSupportLeftovers    = "App Support Leftovers"
    case appPreferences         = "App Preferences"
    case appCaches              = "App Caches"
    case appLogs                = "App Logs"
    case appContainers          = "App Containers"
    case appSavedStates         = "App Saved States"
    case appCrashReports        = "App Crash Reports"
    case appLaunchAgents        = "App Launch Agents"
    case appLaunchDaemons       = "App Launch Daemons"
    case appPlugins             = "App Plugins"
    case appFrameworks          = "App Frameworks"
    case appHelperTools         = "App Helper Tools"
    case appReceipts            = "App Receipts (pkgutil)"

    // System Junk
    case systemLogs             = "System Logs"
    case systemCaches           = "System Caches"
    case systemTempFiles        = "Temporary Files"
    case trashContents          = "Trash Contents"
    case downloadsOld           = "Old Downloads (90+ days)"
    case languagePacks          = "Unused Language Packs"
    case iosBackups             = "Old iOS/iPadOS Backups"
    case iosDeviceSupport       = "iOS Device Support Files"
    case xcodeSimulators        = "Xcode Simulator Runtimes"
    case xcodeDerivedData       = "Xcode DerivedData"
    case xcodeArchives          = "Xcode Archives"
    case xcodeDocsets           = "Xcode Documentation Sets"
    case brewCache              = "Homebrew Cache"
    case npmCache               = "npm Cache"
    case yarnCache              = "Yarn Cache"
    case pipCache               = "pip Cache"
    case gradleCache            = "Gradle Cache"
    case mavenCache             = "Maven Cache"
    case dockerImages           = "Docker Images/Containers"
    case podCache               = "CocoaPods Cache"
    case gemCache               = "Ruby Gems Cache"
    case duplicateFiles         = "Duplicate Files"
    case largeOldFiles          = "Large Unused Files (500MB+)"
    case fontCache              = "Font Cache"
    case spotlightIndex         = "Spotlight Metadata"
    case mailAttachments        = "Mail Downloads Cache"
    case safariCache            = "Safari Cache"
    case chromeCache            = "Chrome/Chromium Cache"
    case firefoxCache           = "Firefox Cache"

    var description: String {
        return self.rawValue
    }
    
    var icon: String {
        switch category {
        case .appLeftovers: return "app.dashed"
        case .systemJunk: return "gearshape.2"
        case .devTools: return "hammer"
        case .browsers: return "network"
        case .other: return "doc"
        }
    }
    
    var riskLevel: RiskLevel {
        switch self {
        case .appSupportLeftovers, .appPreferences, .appCaches, .appLogs, .appSavedStates, .appCrashReports, .systemLogs, .systemCaches, .systemTempFiles, .trashContents, .xcodeDerivedData, .brewCache, .npmCache, .yarnCache, .pipCache, .gradleCache, .mavenCache, .podCache, .gemCache, .fontCache, .safariCache, .chromeCache, .firefoxCache:
            return .safe
        case .appContainers, .appLaunchAgents, .downloadsOld, .languagePacks, .iosBackups, .iosDeviceSupport, .xcodeSimulators, .xcodeArchives, .xcodeDocsets, .dockerImages, .mailAttachments:
            return .caution
        case .appLaunchDaemons, .appPlugins, .appFrameworks, .appHelperTools, .appReceipts, .duplicateFiles, .largeOldFiles, .spotlightIndex:
            return .dangerous
        }
    }
    
    var category: CategoryGroup {
        switch self {
        case .appSupportLeftovers, .appPreferences, .appCaches, .appLogs, .appContainers, .appSavedStates, .appCrashReports, .appLaunchAgents, .appLaunchDaemons, .appPlugins, .appFrameworks, .appHelperTools, .appReceipts:
            return .appLeftovers
        case .systemLogs, .systemCaches, .systemTempFiles, .trashContents, .languagePacks, .fontCache, .spotlightIndex:
            return .systemJunk
        case .xcodeSimulators, .xcodeDerivedData, .xcodeArchives, .xcodeDocsets, .brewCache, .npmCache, .yarnCache, .pipCache, .gradleCache, .mavenCache, .dockerImages, .podCache, .gemCache, .iosBackups, .iosDeviceSupport:
            return .devTools
        case .safariCache, .chromeCache, .firefoxCache:
            return .browsers
        case .downloadsOld, .duplicateFiles, .largeOldFiles, .mailAttachments:
            return .other
        }
    }
}

enum RiskLevel: String {
    case safe       = "Safe"
    case caution    = "Caution"
    case dangerous  = "Dangerous"
}

enum CategoryGroup: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case appLeftovers = "App Leftovers"
    case systemJunk   = "System Junk"
    case devTools     = "Developer Tools"
    case browsers     = "Browsers"
    case other        = "Other"
}

// MARK: - ผลลัพธ์จากการสแกน
struct JunkItem: Identifiable, Hashable {
    let id = UUID()
    let type: JunkType
    let path: String
    let displayName: String
    let sizeBytes: Int64
    let relatedApp: String?
    var isSelected: Bool = true

    var sizeMB: Double { Double(sizeBytes) / 1_048_576.0 }
    var sizeGB: Double { Double(sizeBytes) / 1_073_741_824.0 }
    
    var formattedSize: String {
        if sizeGB >= 1.0 {
            return String(format: "%.1f GB", sizeGB)
        } else if sizeMB >= 1.0 {
            return String(format: "%.1f MB", sizeMB)
        } else {
            return String(format: "%d KB", sizeBytes / 1024)
        }
    }
    
    static func == (lhs: JunkItem, rhs: JunkItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ScanResult {
    var items: [JunkItem] = []
    var scanDuration: TimeInterval = 0
    var totalSize: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes } }
    var itemsByType: [JunkType: [JunkItem]] { Dictionary(grouping: items) { $0.type } }
    var itemsByApp: [String: [JunkItem]] {
        Dictionary(grouping: items.filter { $0.relatedApp != nil }) { $0.relatedApp! }
    }
}
