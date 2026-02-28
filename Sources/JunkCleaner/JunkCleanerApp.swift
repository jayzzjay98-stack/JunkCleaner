import SwiftUI
import AppKit

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()

    var body: some Scene {
        WindowGroup {
            ContentView(scanner: scanner, cleaner: cleaner)
                .onAppear { configureWindow() }
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

    private func configureWindow() {
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first else { return }
            // Hide native traffic lights — we draw our own
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
            // Make window background transparent so our rounded corners show
            window.isOpaque = false
            window.backgroundColor = .clear
            // Allow dragging from anywhere in the title bar area
            window.isMovableByWindowBackground = false
        }
    }
}
