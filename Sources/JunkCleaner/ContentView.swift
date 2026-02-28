import SwiftUI
import UserNotifications
import AppKit

// MARK: - Root View
struct ContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @State private var showResult = false
    @State private var resultTimer: Timer?

    var body: some View {
        ZStack {
            // Background void color
            T.bgVoid.ignoresSafeArea()

            // Main App Container
            HStack(spacing: 0) {
                AppSidebar(scanner: scanner, cleaner: cleaner)

                // Divider line matches mockup's Sidebar boundary
                // We're already drawing a 1px border on its right side in AppSidebar.

                MainContentView(
                    scanner: scanner,
                    cleaner: cleaner,
                    showResult: $showResult
                )
            }
            .background(T.bgBase)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(T.borderMid, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.65), radius: 60, x: 0, y: 30)
            .padding(40) // Spacing for window shadow
            .frame(width: 900 + 80, height: 620 + 80)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        NSApplication.shared.keyWindow?.performDrag(with: NSApp.currentEvent ?? NSEvent())
                    }
            )
        }
        .frame(minWidth: 900, minHeight: 620)
        .onAppear {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
}
