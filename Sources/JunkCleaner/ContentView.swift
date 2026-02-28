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
            T.bgApp.ignoresSafeArea()

            // Main App Container (920 x 620)
            HStack(spacing: 0) {
                AppSidebar(scanner: scanner, cleaner: cleaner)

                MainContentView(
                    scanner: scanner,
                    cleaner: cleaner,
                    showResult: $showResult
                )
            }
            .background(T.bgMain)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(T.b1, lineWidth: 1)
            )
            // Layered premium shadow from mockup
            .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 0)
            .shadow(color: .black.opacity(0.7), radius: 64, x: 0, y: 32)
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 8)
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
            // Top highlight
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.07), Color.white.opacity(0.07), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 1)
                .padding(.horizontal, 10)
            }
            .padding(40) // Spacing for window shadow
            .frame(width: 920 + 80, height: 620 + 80)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        NSApplication.shared.keyWindow?.performDrag(with: NSApp.currentEvent ?? NSEvent())
                    }
            )
        }
        .frame(minWidth: 920, minHeight: 620)
        .onAppear {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
}
