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
                    SectionLabel(text: "Found Items")
                    JunkItemsList(items: result.items)
                }
            } else {
                EmptyIdleState()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: scanner.isScanning)
        .animation(.easeInOut(duration: 0.25), value: scanner.scanResult?.items.count ?? -1)
    }
}

// MARK: - Idle empty state
struct EmptyIdleState: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(DS.bgPrimary)
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(DS.borderSubtle, lineWidth: 1)
                    )
                    .overlay(
                        // Subtle gradient top edge
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [DS.violet.opacity(0.2), .clear],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(DS.textTertiary)
            }

            Text("Your Mac looks clean")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.textSecondary)

            Text("Run a scan to detect junk files, caches,\nlogs, and leftover data that can be removed.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(DS.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.vertical, 28)
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
                    .fill(DS.successDim)
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DS.success)
            }
            Text("No junk files found!")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.success)
            Text("Your Mac is in great shape.")
                .font(.system(size: 12))
                .foregroundStyle(DS.textTertiary)
        }
        .padding(.vertical, 28)
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
            ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, item in
                JunkRow(item: item, rank: idx + 1, maxSize: maxSize)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Single junk row
struct JunkRow: View {
    let item: JunkItem
    let rank: Int
    let maxSize: Int64

    @State private var hovering = false
    private var barFraction: Double { Double(item.sizeBytes) / Double(max(1, maxSize)) }

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: DS.radiusIcon)
                    .fill(item.type.accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: item.type.displayIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(item.type.accentColor)
            }

            // Name + category
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                    .lineLimit(1)
                Text(item.type.rawValue)
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundStyle(DS.textTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Size + bar
            VStack(alignment: .trailing, spacing: 5) {
                Text(item.formattedSize)
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DS.textSecondary)

                // Mini bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DS.bgQuaternary)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [item.type.accentColor, item.type.accentColor.opacity(0.6)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: max(3, geo.size.width * barFraction))
                    }
                }
                .frame(width: 48, height: 3)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusItem)
                .fill(hovering ? DS.bgTertiary : Color.clear)
        )
        .animation(.easeInOut(duration: 0.12), value: hovering)
        .onHover { h in hovering = h }
        // Separator line
        .overlay(alignment: .top) {
            if rank > 1 {
                Rectangle()
                    .fill(DS.borderSubtle)
                    .frame(height: 1)
                    .padding(.leading, 56)
            }
        }
    }
}
