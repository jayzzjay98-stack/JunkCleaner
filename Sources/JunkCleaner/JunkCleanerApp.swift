import SwiftUI

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()

    var body: some Scene {
        WindowGroup {
            ContentView(scanner: scanner, cleaner: cleaner)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 690)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Scan") { Task { await scanner.startScan() } }
                    .keyboardShortcut("s", modifiers: [.command])
            }
        }
    }
}
