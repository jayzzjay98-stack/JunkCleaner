import SwiftUI

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()

    var body: some Scene {
        WindowGroup("JunkCleaner") {
            ContentView(scanner: scanner, cleaner: cleaner)
                .frame(minWidth: 320, minHeight: 600)
                .frame(width: 360, height: 700)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
