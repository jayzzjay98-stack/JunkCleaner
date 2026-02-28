# 🤖 AI Prompt: สร้าง JunkCleaner macOS App

---

## 🎯 ภาพรวมโปรเจ็ค

สร้าง macOS Menu Bar application ชื่อ **JunkCleaner** โดยใช้ **Swift + SwiftUI** รองรับ **macOS 14+ (Sonoma) บน Apple Silicon M4**
โปรเจ็คนี้จะถูกนำไปรวมกับ RamCleaner app ในอนาคต ดังนั้นสถาปัตยกรรมต้องออกแบบให้ reusable และ modular

---

## 📁 โครงสร้างโปรเจ็ค

```
JunkCleaner/
├── Package.swift
├── Info.plist
├── AppIcon.icns
├── install.sh
├── build_and_run.sh
└── Sources/
    └── JunkCleaner/
        ├── JunkCleanerApp.swift          ← @main entry point (MenuBarExtra)
        ├── JunkScanner.swift             ← Core scanning engine
        ├── JunkCleaner.swift             ← Core deletion engine
        ├── AppUninstaller.swift          ← Deep app uninstall engine
        ├── JunkCategory.swift            ← Data models & category definitions
        ├── MenuBarView.swift             ← Main UI (popup window)
        ├── ScanResultView.swift          ← Scan results breakdown UI
        └── Theme.swift                   ← Theme system (ตาม RamCleaner style)
```

---

## 📦 Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JunkCleaner",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "JunkCleaner",
            path: "Sources/JunkCleaner",
            resources: [.copy("../../AppIcon.icns")]
        )
    ]
)
```

---

## 🗂️ JunkCategory.swift — Data Models

```swift
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

    // Description สำหรับ UI
    var description: String { ... }
    var icon: String { ... }         // SF Symbol name
    var riskLevel: RiskLevel { ... } // safe / caution / dangerous
    var category: CategoryGroup { ... }
}

enum RiskLevel: String {
    case safe       = "Safe"     // ลบได้เลยไม่มีผลกระทบ
    case caution    = "Caution"  // ควรตรวจสอบก่อน
    case dangerous  = "Dangerous" // ต้องให้ user ยืนยัน
}

enum CategoryGroup: String, CaseIterable {
    case appLeftovers = "App Leftovers"
    case systemJunk   = "System Junk"
    case devTools     = "Developer Tools"
    case browsers     = "Browsers"
    case other        = "Other"
}

// MARK: - ผลลัพธ์จากการสแกน
struct JunkItem: Identifiable {
    let id = UUID()
    let type: JunkType
    let path: String          // full path ของไฟล์/โฟลเดอร์
    let displayName: String   // ชื่อที่แสดงใน UI
    let sizeBytes: Int64
    let relatedApp: String?   // ชื่อแอปที่เกี่ยวข้อง (ถ้ามี)
    var isSelected: Bool = true

    var sizeMB: Double { Double(sizeBytes) / 1_048_576.0 }
    var sizeGB: Double { Double(sizeBytes) / 1_073_741_824.0 }
    var formattedSize: String { ... }
}

struct ScanResult {
    var items: [JunkItem] = []
    var scanDuration: TimeInterval = 0
    var totalSize: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes } }
    var itemsByType: [JunkType: [JunkItem]] { Dictionary(grouping: items) { $0.type } }
    var itemsByApp: [String: [JunkItem]] { ... }
}
```

---

## 🔍 JunkScanner.swift — Core Scanning Engine

```swift
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

    // MARK: - Main Scan Function
    func startScan() async {
        // รัน scan ทุก category แบบ concurrent ด้วย TaskGroup
        // อัปเดต progress ทุก step
        // เมื่อเสร็จ set scanResult
    }

    func cancelScan() { ... }

    // MARK: - Scan ทุก Path เหล่านี้:

    // 1. APP LEFTOVERS — ค้นหาจาก installed apps vs leftover files
    private func scanAppLeftovers() async -> [JunkItem] {
        /*
        สำหรับแต่ละแอปที่ถูกลบออกไปแล้ว (ไม่มีใน /Applications อีกต่อไป)
        ค้นหา leftover ในทุก path เหล่านี้:

        ~/Library/Application Support/{AppName}
        ~/Library/Application Support/{BundleID}
        ~/Library/Preferences/{BundleID}.plist
        ~/Library/Preferences/{BundleID}.*.plist
        ~/Library/Caches/{AppName}
        ~/Library/Caches/{BundleID}
        ~/Library/Logs/{AppName}
        ~/Library/Logs/{BundleID}
        ~/Library/Containers/{BundleID}
        ~/Library/Group Containers/*.{AppName}.*
        ~/Library/Group Containers/{BundleID}.*
        ~/Library/Saved Application State/{BundleID}.savedState
        ~/Library/HTTPStorages/{BundleID}
        ~/Library/WebKit/{BundleID}
        ~/Library/Cookies/{BundleID}*
        ~/Library/LaunchAgents/{BundleID}*.plist
        /Library/LaunchAgents/{BundleID}*.plist
        /Library/LaunchDaemons/{BundleID}*.plist
        /Library/Application Support/{AppName}
        /Library/Application Support/{BundleID}
        /Library/Preferences/{BundleID}*.plist
        /Library/PrivilegedHelperTools/{BundleID}*
        /Library/Extensions/{BundleID}.kext
        /Library/Frameworks/{AppName}*
        ~/Library/Frameworks/{AppName}*
        /usr/local/lib/{AppName}*
        /usr/local/bin/{AppName}*
        /usr/local/etc/{AppName}*
        /usr/local/var/{AppName}*
        ~/Library/Application Scripts/{BundleID}*
        ~/Library/Mail/V10/MailData/  ← search for app-specific
        /private/var/db/receipts/{BundleID}*     ← pkgutil receipts
        /Library/Receipts/{BundleID}*
        ~/.config/{AppName}
        ~/.local/share/{AppName}
        ~/.cache/{AppName}

        วิธีตรวจสอบว่าแอปถูกลบแล้ว:
        - ใช้ NSWorkspace.shared.urlForApplication(withBundleIdentifier:) → nil = ลบแล้ว
        - ใช้ FileManager เช็ค /Applications/{AppName}.app ไม่มีอยู่
        - Cross-reference กับ pkgutil --pkgs เพื่อหา orphaned packages

        วิธีค้นหา BundleID จาก leftover path:
        - อ่าน Info.plist จากภายใน .app bundle
        - ใช้ reverse domain pattern matching
        - สร้าง database ของ known app->bundleID mapping
        */
    }

    // 2. SYSTEM CACHES
    private func scanSystemCaches() async -> [JunkItem] {
        /*
        Scan paths:
        ~/Library/Caches/                     ← ทุกโฟลเดอร์ในนี้ที่ไม่ใช่ Apple system
        /Library/Caches/                       ← ที่ไม่ใช่ system critical
        /private/var/folders/**               ← temp files (ใช้ glob)
        ~/Library/Caches/com.apple.Safari/    ← Safari cache
        ~/Library/Caches/Google/Chrome/       ← Chrome cache
        ~/Library/Caches/Firefox/             ← Firefox cache
        ~/Library/Caches/org.mozilla.firefox/ ← Firefox cache alternate

        กฎ: ไม่ลบ cache ของ:
        - com.apple.dt.* (Xcode related — handled separately)
        - com.apple.security.*
        - com.apple.keychain.*
        - com.apple.trustd.*
        - com.apple.SystemPreferences
        */
    }

    // 3. APP LOGS
    private func scanLogs() async -> [JunkItem] {
        /*
        Paths:
        ~/Library/Logs/                        ← user app logs
        /Library/Logs/                         ← system/app logs
        /private/var/log/                      ← system logs (เฉพาะ .log ที่ไม่ใช่ active)
        ~/Library/Logs/DiagnosticReports/     ← crash reports (safe to delete)
        /Library/Logs/DiagnosticReports/      ← system crash reports
        ~/Library/Logs/CoreSimulator/         ← Simulator logs

        ลบได้: ไฟล์ .log, .crash, .ips, .spin, .diag
        อายุ > 7 วัน → safe
        */
    }

    // 4. TEMP FILES
    private func scanTempFiles() async -> [JunkItem] {
        /*
        Paths:
        /private/tmp/                          ← system temp
        /private/var/tmp/                      ← alternate temp
        ~/Library/Caches/TemporaryItems/
        ~/.Trash/                              ← Trash contents
        /Volumes/*/.Trashes/                   ← External drive trash
        NSTemporaryDirectory()                 ← Swift temp dir

        ไฟล์ที่ลบได้:
        - .tmp, .temp extensions
        - Files ที่ไม่ได้ถูกเปิดใช้ > 24 ชม.
        - ไฟล์ที่มี parent process ที่ไม่ได้ run อยู่แล้ว
        */
    }

    // 5. DEVELOPER JUNK
    private func scanDeveloperJunk() async -> [JunkItem] {
        /*
        Xcode:
        ~/Library/Developer/Xcode/DerivedData/     ← ใหญ่มาก บางครั้ง 10-50 GB
        ~/Library/Developer/Xcode/Archives/        ← .xcarchive เก่า
        ~/Library/Developer/Xcode/iOS Device Logs/
        ~/Library/Developer/Xcode/UserData/
        ~/Library/Developer/CoreSimulator/Devices/ ← Simulator devices ที่ไม่ได้ใช้
        ~/Library/Developer/CoreSimulator/Caches/

        Homebrew:
        $(brew --cache)                             ← ปกติ ~/Library/Caches/Homebrew
        ~/.cache/Homebrew/
        /opt/homebrew/var/cache/ (M-series)

        npm/Node:
        ~/.npm/_cacache/
        ~/.npm/tmp/
        ~/Library/Caches/node-gyp/
        ~/.node_repl_history

        Yarn:
        ~/.yarn/cache/
        $(yarn cache dir)

        pip/Python:
        ~/Library/Caches/pip/
        ~/.cache/pip/

        Gradle (Android):
        ~/.gradle/caches/
        ~/.gradle/wrapper/dists/

        Maven:
        ~/.m2/repository/ (เฉพาะ snapshots เก่า)

        CocoaPods:
        ~/Library/Caches/CocoaPods/
        ~/.cocoapods/repos/ (เฉพาะ old index)

        Ruby Gems:
        ~/.gem/specs/
        /usr/local/lib/ruby/gems/ → old versions

        Docker:
        ~/Library/Containers/com.docker.docker/Data/vms/
        ~/.docker/ → old configs

        JetBrains (IntelliJ, WebStorm ฯลฯ):
        ~/Library/Caches/JetBrains/
        ~/Library/Logs/JetBrains/
        ~/Library/Application Support/JetBrains/ → old versions only
        */
    }

    // 6. LANGUAGE PACKS
    private func scanLanguagePacks() async -> [JunkItem] {
        /*
        ค้นหา .lproj โฟลเดอร์ในแอปที่ไม่ใช่ภาษาที่ user ใช้
        Paths to scan: /Applications/**/*.app/Contents/Resources/*.lproj

        วิธีรู้ว่าภาษาไหน user ใช้:
        Locale.preferredLanguages → ["th", "en"]

        ลบได้: .lproj ที่ไม่ match กับ preferred languages
        ยกเว้น: Base.lproj, en.lproj (English ต้องเก็บเสมอ)
        */
    }

    // 7. iOS/iPadOS RELATED
    private func scanIOSRelated() async -> [JunkItem] {
        /*
        Backups:
        ~/Library/Application Support/MobileSync/Backup/   ← iTunes/Finder backups
        (เฉพาะ backups ที่เก่ากว่า 30 วัน หรือมีหลาย backup ของ device เดียวกัน)

        Device Support:
        ~/Library/Developer/Xcode/iOS DeviceSupport/       ← symbols สำหรับ iOS เก่า
        ~/Library/Developer/Xcode/watchOS DeviceSupport/
        ~/Library/Developer/Xcode/tvOS DeviceSupport/
        (เก็บแค่ version ล่าสุด 2 versions)
        */
    }

    // 8. DOWNLOADS (เก่า)
    private func scanOldDownloads() async -> [JunkItem] {
        /*
        ~/Downloads/
        - ไฟล์ที่ไม่ได้เปิดใช้ > 90 วัน
        - .dmg, .pkg ที่ถูก install แล้ว (ตรวจสอบจาก quarantine metadata)
        - .zip ที่มีโฟลเดอร์ที่ unzip แล้วอยู่ข้างๆ

        วิธีตรวจ .dmg ที่ install แล้ว:
        - xattr -l file.dmg | grep com.apple.quarantine
        - ls -la → lastOpened นานมาก
        */
    }

    // 9. MAIL CACHE
    private func scanMailCache() async -> [JunkItem] {
        /*
        ~/Library/Mail/V10/ (หรือ V8, V9 แล้วแต่ version)
        - ~/Library/Mail/V*/MailData/  ← email attachments cache
        - Attachments ที่ถูก download มาแล้ว
        - Message preview cache
        */
    }

    // 10. SAFARI / BROWSERS
    private func scanBrowserCaches() async -> [JunkItem] {
        /*
        Safari:
        ~/Library/Caches/com.apple.Safari/
        ~/Library/Safari/LocalStorage/
        ~/Library/Safari/Databases/
        ~/Library/WebKit/com.apple.Safari/

        Chrome:
        ~/Library/Caches/Google/Chrome/Default/Cache/
        ~/Library/Application Support/Google/Chrome/Default/Cache/
        ~/Library/Application Support/Google/Chrome/Default/Code Cache/

        Firefox:
        ~/Library/Caches/Firefox/Profiles/
        ~/Library/Application Support/Firefox/Profiles/*/cache2/

        Brave, Edge, Opera, Arc — similar paths ตาม Chromium pattern
        */
    }

    // MARK: - Helper: คำนวณขนาดโฟลเดอร์
    private func calculateDirectorySize(_ path: String) -> Int64 { ... }

    // MARK: - Helper: ตรวจสอบว่า path มีอยู่จริงไหม
    private func safeExists(_ path: String) -> Bool { ... }

    // MARK: - Helper: อ่าน bundle ID จาก .app
    private func bundleID(for appPath: String) -> String? { ... }

    // MARK: - Helper: ดึงรายชื่อแอปที่ถูกลบออกไปแล้ว (มี leftover)
    private func findUninstalledAppsWithLeftovers() -> [(name: String, bundleID: String)] { ... }
}
```

---

## 🧹 JunkCleaner.swift — Core Deletion Engine

```swift
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
    }

    // MARK: - Main Clean Function
    func clean(items: [JunkItem], requireAuth: Bool = true) async {
        /*
        1. ถ้า requireAuth: ใช้ LocalAuthentication (Touch ID / Password)
        2. Loop ผ่าน items
        3. สำหรับแต่ละ item:
           - เช็คว่า path ยังมีอยู่
           - เช็ค permission
           - ลองลบด้วย FileManager.default.removeItem(at:)
           - ถ้าต้องการ admin: ใช้ AppleScript "do shell script ... with administrator privileges"
           - Track progress
        4. อัปเดต totalFreedBytes
        5. Set lastResult
        */
    }

    // MARK: - ลบ item เดียว
    private func deleteItem(_ item: JunkItem) async throws {
        /*
        ลำดับการลบ:
        1. ลอง FileManager.default.trashItem (ย้ายไป Trash ก่อน — safer)
        2. ถ้า permission denied → ลอง sudo ผ่าน AppleScript
        3. ถ้าเป็น LaunchAgent/Daemon → unload ก่อนด้วย launchctl unload
        4. ถ้าเป็น pkgutil receipt → ลบด้วย pkgutil --forget
        */
    }

    // MARK: - ลบด้วย Admin Privilege
    private func deleteWithAdmin(path: String) async throws {
        /*
        AppleScript:
        do shell script "rm -rf '{path}'" with administrator privileges
        */
    }

    // MARK: - Unload LaunchAgent/Daemon ก่อนลบ
    private func unloadLaunchItem(path: String) {
        /*
        Process:
        executableURL = /bin/launchctl
        arguments = ["unload", path]
        */
    }

    // MARK: - ลบ pkgutil receipt
    private func forgetPackage(bundleID: String) async throws {
        /*
        sudo pkgutil --forget {bundleID}
        */
    }
}
```

---

## 🗑️ AppUninstaller.swift — Deep App Uninstall Engine

```swift
import Foundation
import AppKit

@Observable
final class AppUninstaller {

    var isAnalyzing: Bool = false
    var foundItems: [JunkItem] = []
    var targetApp: AppInfo?

    struct AppInfo {
        let name: String
        let bundleID: String
        let version: String
        let path: String
        let iconPath: String?
        var sizeBytes: Int64
    }

    // MARK: - วิเคราะห์แอปเพื่อหา ALL related files
    func analyzeApp(at path: String) async {
        /*
        รับ path ของ .app เช่น /Applications/Spotify.app
        แล้วค้นหา ทุกไฟล์ที่เกี่ยวข้อง ดังนี้:

        Step 1: อ่าน Info.plist → ได้ CFBundleIdentifier, CFBundleName, CFBundleExecutable

        Step 2: สร้าง search terms หลายรูปแบบ:
        - bundleID เต็ม: "com.spotify.client"
        - bundleID parts: "spotify", "client"
        - app name: "Spotify"
        - executable name: "Spotify"
        - reverse DNS variations: "com.spotify.*"

        Step 3: ค้นหาใน paths ทั้งหมดนี้ (ครอบคลุมที่สุด):

        USER LEVEL:
        ~/Library/Application Support/{term}*
        ~/Library/Preferences/{term}*
        ~/Library/Caches/{term}*
        ~/Library/Logs/{term}*
        ~/Library/Containers/{term}*
        ~/Library/Group Containers/*{term}*
        ~/Library/Saved Application State/{term}*.savedState
        ~/Library/Application Scripts/{term}*
        ~/Library/HTTPStorages/{term}*
        ~/Library/WebKit/{term}*
        ~/Library/Cookies/{term}*.binarycookies
        ~/Library/LaunchAgents/{term}*.plist
        ~/Library/Keychains/{term}*            ← keychain entries (use security delete)
        ~/Library/Spelling/{term}*
        ~/Library/Dictionaries/{term}*
        ~/Library/Input Methods/{term}*
        ~/Library/Screen Savers/{term}*
        ~/Library/Internet Plug-Ins/{term}*
        ~/Library/PreferencePanes/{term}*
        ~/.config/{term}*
        ~/.local/share/{term}*
        ~/.cache/{term}*
        ~/.{term}*                              ← dotfiles (เช่น .spotify)
        ~/Desktop/{term}*                       ← ไฟล์ที่ user อาจสร้าง

        SYSTEM LEVEL (ต้องการ admin):
        /Library/Application Support/{term}*
        /Library/Preferences/{term}*
        /Library/Caches/{term}*
        /Library/Logs/{term}*
        /Library/LaunchAgents/{term}*.plist
        /Library/LaunchDaemons/{term}*.plist
        /Library/PrivilegedHelperTools/{term}*
        /Library/Extensions/{term}*.kext
        /Library/Frameworks/{term}*
        /Library/PreferencePanes/{term}*.prefPane
        /Library/Screen Savers/{term}*
        /Library/Internet Plug-Ins/{term}*
        /Library/Services/{term}*
        /Library/Contextual Menu Items/{term}*
        /Library/InputManagers/{term}*
        /Library/Address Book Plug-Ins/{term}*
        /usr/local/lib/{term}*
        /usr/local/bin/{term}*
        /usr/local/etc/{term}*
        /usr/local/var/{term}*
        /usr/local/share/{term}*
        /private/var/db/receipts/{term}*        ← pkgutil receipts

        Step 4: ใช้ `mdfind` (Spotlight) เพื่อค้นหาไฟล์ที่อาจหลุดจาก path scan:
        mdfind "kMDItemCFBundleIdentifier == '{bundleID}'"
        mdfind "{bundleID}" -onlyin ~/Library
        mdfind "{appName}" -onlyin ~/Library

        Step 5: ตรวจสอบ pkgutil receipts:
        pkgutil --pkgs | grep -i {term}
        → แล้วใช้ pkgutil --files {packageID} เพื่อดูว่ามีไฟล์ที่ยังอยู่ไหม

        Step 6: ตรวจสอบ Login Items:
        SMAppService / ServiceManagement framework
        → แอปที่อยู่ใน Login Items

        Step 7: ตรวจสอบ Keychain entries ที่เกี่ยวข้อง:
        security find-generic-password -s "{appName}"
        → แสดงให้ user รู้ว่ามี keychain entry (อย่าลบอัตโนมัติ)
        */
    }

    // MARK: - Deep Uninstall ทั้งหมด
    func deepUninstall(app: AppInfo, foundItems: [JunkItem]) async throws {
        /*
        1. ปิดแอปก่อน (ถ้ากำลัง run อยู่)
           NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == bundleID }?.terminate()

        2. ลบ .app bundle ก่อน

        3. ลบ LaunchAgents/Daemons → unload ก่อน แล้วค่อยลบ

        4. ลบทุก foundItems ตามลำดับ (user items ก่อน, system items หลัง)

        5. ลบ pkgutil receipts
           sudo pkgutil --forget {packageID}

        6. Flush caches ที่เกี่ยวข้อง:
           sudo update_dyld_shared_cache
           sudo killall -HUP mDNSResponder (ถ้ามี network service)

        7. แสดงสรุปว่าลบอะไรไปบ้าง
        */
    }

    // MARK: - ดึงรายชื่อแอปทั้งหมดใน /Applications
    func getAllInstalledApps() -> [AppInfo] { ... }

    // MARK: - mdfind search
    private func spotlightSearch(query: String, inDirectory: String? = nil) -> [String] { ... }
}
```

---

## 🎨 MenuBarView.swift — Main UI

```swift
// UI ต้องมี 4 หน้าหลัก:

// MARK: - หน้า 1: Overview (หน้าแรกที่เห็นเมื่อเปิด popup)
/*
แสดง:
- ปุ่ม "Scan Now" ขนาดใหญ่
- ถ้าสแกนแล้ว: แสดงสรุป total junk size
- Quick stats: จำนวน categories ที่เจอขยะ
- ปุ่ม "Clean All" (ถ้ามีผลลัพธ์)
- ปุ่ม "App Uninstaller" เปิดหน้า 3
*/

// MARK: - หน้า 2: Scan Results
/*
แสดง results แบบ grouped by category:
- แต่ละ row: checkbox + icon + ชื่อ category + จำนวนไฟล์ + ขนาด
- Expand แต่ละ category เพื่อดูรายละเอียดไฟล์แต่ละไฟล์
- Select/Deselect all
- Filter: Safe only / All
- ปุ่ม "Clean Selected" ด้านล่าง
*/

// MARK: - หน้า 3: App Uninstaller
/*
- Search bar ค้นหาแอป
- List แอปทั้งหมดใน /Applications (+ ขนาด)
- คลิกแอป → วิเคราะห์ leftover
- แสดง leftover files ที่พบ (grouped by location)
- ปุ่ม "Deep Uninstall"
*/

// MARK: - หน้า 4: Settings
/*
- เลือก scan categories ที่ต้องการ
- กำหนด minimum file size
- เลือก theme (เหมือน RamCleaner — ใช้ AppTheme system เดียวกัน)
- Auto-scan interval
- Exclude paths
*/
```

---

## 🎨 Theme.swift

```swift
// ใช้ระบบ theme เดียวกันกับ RamCleaner ทุกประการ
// Copy AppTheme struct และ appThemes array มาใช้เลย
// ใช้ @AppStorage("selectedTheme") shared กับ RamCleaner ได้เลย
// ดังนั้นเมื่อรวมกันแล้ว theme ที่ user เลือกจะ sync กันอัตโนมัติ
```

---

## 🔐 Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>JunkCleaner</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.junkcleaner</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSUIElement</key>
    <true/>          <!-- ซ่อนจาก Dock, แสดงแค่ใน Menu Bar -->
    <key>NSAppleEventsUsageDescription</key>
    <string>JunkCleaner needs AppleScript to remove files requiring administrator privileges.</string>
    <key>NSDesktopFolderUsageDescription</key>
    <string>JunkCleaner scans Desktop for junk files.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>JunkCleaner scans Downloads for old files.</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>JunkCleaner needs access to find junk files.</string>
    <key>NSRemovableVolumesUsageDescription</key>
    <string>JunkCleaner scans external drives for trash.</string>
    <key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
    <array>
        <string>/Library/</string>
        <string>/private/var/</string>
        <string>/usr/local/</string>
    </array>
</dict>
</plist>
```

---

## ⚙️ install.sh

```bash
#!/bin/bash
set -e

echo "🧹 Building JunkCleaner..."
swift build -c release

APP_NAME="JunkCleaner"
BUILD_PATH=".build/release/$APP_NAME"
APP_DIR="/Applications/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_PATH" "$MACOS_DIR/"
cp Info.plist "$CONTENTS/"
[ -f AppIcon.icns ] && cp AppIcon.icns "$RESOURCES_DIR/"

# Sign for local use
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo "✅ Installed to $APP_DIR"
echo "🚀 Launching..."
open "$APP_DIR"
```

---

## ✅ Safety Rules (สำคัญมาก — ต้องปฏิบัติตามเสมอ)

```swift
// NEVER DELETE ไฟล์เหล่านี้:
let PROTECTED_PATHS = [
    "/System/",
    "/usr/bin/", "/usr/sbin/", "/usr/lib/",
    "/bin/", "/sbin/",
    "/Library/Apple/",
    "/Library/Updates/",
    "/private/var/db/",          // ยกเว้น /receipts/
    "~/Library/Keychains/",      // แค่แสดง อย่าลบ
    "~/Library/Mail/V*/MailData/Accounts/",  // account config
    "~/Library/Safari/Bookmarks.plist",
    "~/Library/Safari/History.db",
    "/Applications/Safari.app",
    "/Applications/Finder.app",
]

// NEVER DELETE process ที่ยัง run อยู่
// ตรวจสอบก่อนลบทุกครั้ง: NSWorkspace.shared.runningApplications

// ALWAYS ย้ายไป Trash ก่อน (trashItem) แทนที่จะลบตรง (removeItem)
// ยกเว้น /private/tmp/ และ /private/var/folders/ ที่ลบตรงได้

// ALWAYS แสดง confirmation dialog ก่อนลบ items ที่มีขนาด > 1 GB

// ALWAYS ใช้ Touch ID / Password ก่อนทำการลบ

// NEVER ลบ .app bundle ใน /Applications โดยไม่ให้ user confirm ก่อน

// ALWAYS log ทุกไฟล์ที่ลบพร้อม timestamp ไว้ใน ~/Library/Logs/JunkCleaner.log
```

---

## 🔗 Integration กับ RamCleaner (สำหรับอนาคต)

```swift
// เมื่อรวมกัน ให้โครงสร้างเป็น:
// Sources/
//   RamCleaner/ ← (ของเดิม)
//   JunkCleaner/ ← (ของใหม่)
//   Shared/
//     Theme.swift     ← shared theme
//     AppThemes.swift ← shared theme data
//     Utils.swift     ← shared utilities

// ใช้ @AppStorage key เดียวกัน: "selectedTheme"
// เพื่อให้ UI สีเดียวกันเมื่อรวมแอป
```

---

## 📊 ตัวอย่าง Expected Output

```
Scan completed in 12.3 seconds
Found 47.2 GB of junk:

App Leftovers        8.3 GB  (23 items) ← Spotify, Adobe, Android Studio leftovers
System Caches       12.1 GB  (142 items)
Xcode DerivedData   18.4 GB  (1 item)
iOS Device Support   4.2 GB  (8 items)
Logs & Crash Reports 0.8 GB  (234 items)
Old Downloads        2.1 GB  (17 items)
Homebrew Cache       1.3 GB  (1 item)
────────────────────────────────────
TOTAL               47.2 GB
```

---

## 🏗️ Build & Run

```bash
# สร้างโปรเจ็คใหม่
mkdir JunkCleaner && cd JunkCleaner
# วางไฟล์ทั้งหมดตามโครงสร้างด้านบน

# Build
swift build -c release

# Install
chmod +x install.sh && ./install.sh
```

---

*Prompt นี้เขียนสำหรับ AI (Claude / GPT-4) เพื่อสร้าง JunkCleaner macOS app ที่สมบูรณ์*
*รองรับ macOS 14+ Sonoma บน Apple Silicon M-series*
*ออกแบบให้รวมกับ RamCleaner ได้ในอนาคต*
