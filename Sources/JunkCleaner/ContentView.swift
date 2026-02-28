import SwiftUI
import UserNotifications

// MARK: - Root
struct ContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @State private var selectedTab: NavTab = .scan
    @State private var showResult = false
    @State private var resultTimer: Timer?

    var body: some View {
        ZStack {
            DS.bgSecondary.ignoresSafeArea()

            VStack(spacing: 0) {
                TitleBar(scanner: scanner)
                HStack(spacing: 0) {
                    SidebarView()
                    Divider().background(DS.borderSubtle)
                    MainContentView(
                        scanner: scanner,
                        cleaner: cleaner,
                        showResult: $showResult
                    )
                }
            }
        }
        .frame(width: 420, height: 690)
        .clipShape(RoundedRectangle(cornerRadius: DS.radiusApp))
        .overlay(
            RoundedRectangle(cornerRadius: DS.radiusApp)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: DS.shadowApp, radius: 60, x: 0, y: 30)
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

// MARK: - Navigation Tab
enum NavTab: CaseIterable {
    case scan, settings

    var icon: String {
        switch self {
        case .scan:     return "magnifyingglass"
        case .settings: return "gearshape.fill"
        }
    }
    var label: String {
        switch self {
        case .scan:     return "Smart Scan"
        case .settings: return "Settings"
        }
    }
    var hasBadge: Bool { false }
}
