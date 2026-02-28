import SwiftUI
import UserNotifications

// MARK: - Root
struct ContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @State private var showResult = false
    @State private var resultTimer: Timer?

    var body: some View {
        ZStack {
            DS.bgPrimary.ignoresSafeArea()

            HStack(spacing: 0) {
                // Sidebar with traffic lights built-in
                AppSidebar()

                // Divider
                Rectangle()
                    .fill(DS.borderSubtle)
                    .frame(width: 1)

                // Main content (no separate TitleBar)
                MainContentView(
                    scanner: scanner,
                    cleaner: cleaner,
                    showResult: $showResult
                )
            }
        }
        .frame(width: 860, height: 620)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusApp))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusApp)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: DS.shadowApp, radius: 60, x: 0, y: 30)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    NSApplication.shared.keyWindow?.performDrag(with: NSApp.currentEvent ?? NSEvent())
                }
        )
        .onChange(of: cleaner.isDeleting) { _, isDeleting in
            if !isDeleting, cleaner.lastResult != nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showResult = true
                }
                resultTimer?.invalidate()
                resultTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.4)) { showResult = false }
                    }
                }
            }
        }
        .onAppear {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
}
