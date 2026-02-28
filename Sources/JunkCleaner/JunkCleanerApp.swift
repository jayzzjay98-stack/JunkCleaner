import SwiftUI
import AppKit

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()

    var body: some Scene {
        WindowGroup {
            ContentView(scanner: scanner, cleaner: cleaner)
                .onAppear {
                    // Hide the macOS title bar / traffic lights (we draw our own)
                    if let w = NSApplication.shared.windows.first {
                        w.titlebarAppearsTransparent = true
                        w.titleVisibility = .hidden
                        w.standardWindowButton(.closeButton)?.isHidden = true
                        w.standardWindowButton(.miniaturizeButton)?.isHidden = true
                        w.standardWindowButton(.zoomButton)?.isHidden = true
                        w.isMovableByWindowBackground = false
                        w.styleMask.insert(.fullSizeContentView)
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 920, height: 620)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}
