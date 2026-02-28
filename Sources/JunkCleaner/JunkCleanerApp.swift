import SwiftUI

@main
struct JunkCleanerApp: App {
    @State private var scanner = JunkScanner()
    @State private var cleaner = JunkCleaner()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(scanner: scanner, cleaner: cleaner)
        } label: {
            MenuBarLabel(scanner: scanner)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    let scanner: JunkScanner

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "trash")
                .font(.system(size: 11))
            if scanner.isScanning {
                Text("Scanning...")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            } else if scanner.totalJunkGB > 0 {
                Text(scanner.totalJunkGB >= 1.0
                     ? String(format: "%.1f GB", scanner.totalJunkGB)
                     : String(format: "%.0f MB", scanner.totalJunkGB * 1024))
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .medium))
            } else {
                Text("Junk")
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .foregroundStyle(
            scanner.totalJunkGB > 5 ? .red :
            scanner.totalJunkGB > 1 ? .yellow : .green
        )
    }
}
