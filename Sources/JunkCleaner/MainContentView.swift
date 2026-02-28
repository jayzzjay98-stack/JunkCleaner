import SwiftUI

struct MainContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool
    var selectedTab: NavTab

    var body: some View {
        ZStack {
            DS.bgSecondary

            switch selectedTab {
            case .scan:
                ScanTabView(scanner: scanner, cleaner: cleaner, showResult: $showResult)
                    .transition(.opacity)
            case .settings:
                SettingsTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: selectedTab)
    }
}

// MARK: - Scan Tab (main content)
struct ScanTabView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HeroSection(scanner: scanner)
                    ChipsRow(scanner: scanner)
                    ScanProgressSection(scanner: scanner)
                    SuccessBanner(cleaner: cleaner, showResult: $showResult)
                    JunkListSection(scanner: scanner)
                }
                .padding(.bottom, 12)
            }
            ActionBar(scanner: scanner, cleaner: cleaner)
        }
    }
}

// MARK: - Settings Tab (placeholder)
struct SettingsTabView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(DS.textTertiary)
            Text("Settings")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
            Text("Coming soon")
                .font(.system(size: 12))
                .foregroundStyle(DS.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section Divider Label
struct SectionLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(DS.borderSubtle)
                .frame(height: 1)
            Text(text)
                .font(.system(size: 9.5, weight: .semibold))
                .kerning(1.2)
                .textCase(.uppercase)
                .foregroundStyle(DS.textTertiary)
            Rectangle()
                .fill(DS.borderSubtle)
                .frame(height: 1)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
    }
}
