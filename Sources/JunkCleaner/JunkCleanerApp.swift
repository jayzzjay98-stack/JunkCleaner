import SwiftUI

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()
    @State private var uninstaller = AppUninstaller()
    
    var body: some Scene {
        MenuBarExtra("JunkCleaner", systemImage: "trash") {
            MenuBarView(scanner: scanner, cleaner: cleaner, uninstaller: uninstaller)
        }
        .menuBarExtraStyle(.window)
    }
}
