import SwiftUI
import AppKit

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()

    var body: some Scene {
        WindowGroup {
            RootView(scanner: scanner, cleaner: cleaner)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.automatic)
        .defaultSize(width: 1180, height: 820)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
