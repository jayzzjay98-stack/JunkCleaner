import SwiftUI
import AppKit

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()

    var body: some Scene {
        WindowGroup {
            ContentView(scanner: scanner, cleaner: cleaner)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.automatic)
        .defaultSize(width: 860, height: 620)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
