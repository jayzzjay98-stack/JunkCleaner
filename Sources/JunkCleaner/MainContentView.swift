import SwiftUI
import AppKit

struct MainContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool

    var body: some View {
        VStack(spacing: 0) {
            AppHeader()

            ScrollView {
                VStack(spacing: 0) {
                    HeroSection(scanner: scanner)
                    ScanProgressSection(scanner: scanner)

                    if let result = scanner.scanResult, !result.items.isEmpty {
                        JunkListSection(scanner: scanner)
                    }

                    SuccessBanner(cleaner: cleaner, showResult: $showResult)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            ActionBar(scanner: scanner, cleaner: cleaner)
        }
    }
}

// MARK: - Simple App Header
struct AppHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Junk Cleaner")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                Text("Find and remove junk files from your Mac")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(DS.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .frame(height: 56)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.borderSubtle).frame(height: 1)
        }
    }
}
