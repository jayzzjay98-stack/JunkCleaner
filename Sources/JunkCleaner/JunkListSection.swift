import SwiftUI

struct JunkListSection: View {
    let scanner: JunkScanner

    var body: some View {
        VStack(spacing: 0) {
            if scanner.isScanning {
                // Don't show list while scanning
            } else if let result = scanner.scanResult {
                if result.items.isEmpty {
                    EmptyResultState()
                } else {
                    JunkItemsList(items: result.items)
                }
            } else {
                EmptyIdleState()
            }
        }
    }
}

// MARK: - Idle empty state
struct EmptyIdleState: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(T.bgRaised)
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(T.borderDim, lineWidth: 1)
                    )

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(T.txt3)
            }

            Text("Your Mac is ready")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(T.txt2)

            Text("Run a scan to detect junk files, caches,\nand leftover data that can be removed.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(T.txt3)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - After scan: nothing found
struct EmptyResultState: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(T.ok.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(T.ok)
            }
            Text("No junk files found!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(T.ok)
            Text("Your Mac is in great shape.")
                .font(.system(size: 12))
                .foregroundStyle(T.txt3)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Items list
struct JunkItemsList: View {
    let items: [JunkItem]

    private var sorted: [JunkItem] {
        items.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private var maxSize: Int64 { sorted.first?.sizeBytes ?? 1 }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(sorted) { item in
                JunkRow(item: item, maxSize: maxSize)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
}

// MARK: - Single junk row
struct JunkRow: View {
    let item: JunkItem
    let maxSize: Int64

    @State private var hovering = false
    private var barFraction: Double { Double(item.sizeBytes) / Double(max(1, maxSize)) }

    var body: some View {
        HStack(spacing: 11) {
            // Icon (Emoji based on category from mockup)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.accentColor.opacity(0.11))
                    .frame(width: 34, height: 34)
                Text(item.emoji)
                    .font(.system(size: 14))
            }

            // Name + category
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(T.txt1)
                    .kerning(-0.15)
                    .lineLimit(1)
                Text(item.type.rawValue)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(T.txt3)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Size + bar
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.formattedSize)
                    .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(T.txt2)

                // Mini bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(T.bgHover)
                        .frame(width: 44, height: 3)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.accentColor.opacity(0.65))
                        .frame(width: max(3, 44 * barFraction), height: 3)
                }
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? T.bgFloat : Color.clear)
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}
