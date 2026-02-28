import SwiftUI

struct MainContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable area
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

            // Fixed bottom action bar
            ActionBar(scanner: scanner, cleaner: cleaner)
        }
        .background(DS.bgSecondary)
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
