import SwiftUI
import UserNotifications

// MARK: - Root
struct ContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @State private var showResult = false
    @State private var resultTimer: Timer?

    var body: some View {
        HStack(spacing: 0) {
            AppSidebar(scanner: scanner, cleaner: cleaner)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)

            MainContentView(
                scanner: scanner,
                cleaner: cleaner,
                showResult: $showResult
            )
        }
        .frame(width: 860, height: 620)
        .background(Color(hex: "#0c0c12"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.85), radius: 60, x: 0, y: 30)
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
