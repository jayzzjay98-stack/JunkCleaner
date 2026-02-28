import SwiftUI

struct ChipsRow: View {
    let scanner: JunkScanner

    var body: some View {
        HStack(spacing: 6) {
            StatChip(
                label: "Status",
                value: statusText,
                valueStyle: statusStyle
            )
            StatChip(
                label: "Items",
                value: itemsText,
                valueStyle: .default
            )
            StatChip(
                label: "Can Free",
                value: canFreeText,
                valueStyle: scanner.totalJunkGB > 0 ? .orange : .default
            )
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
    }

    private var statusText: String {
        if scanner.isScanning { return "Scanning" }
        if scanner.scanResult != nil {
            return scanner.totalJunkGB > 0 ? "Found" : "Clean"
        }
        return "Ready"
    }

    private var statusStyle: StatChip.ValueStyle {
        if scanner.isScanning { return .orange }
        if scanner.scanResult != nil && scanner.totalJunkGB == 0 { return .green }
        if scanner.scanResult != nil && scanner.totalJunkGB > 0 { return .orange }
        return .green
    }

    private var itemsText: String {
        guard let result = scanner.scanResult else { return "—" }
        return "\(result.items.count)"
    }

    private var canFreeText: String {
        guard scanner.scanResult != nil else { return "—" }
        if scanner.totalJunkGB >= 1.0 {
            return String(format: "%.1f GB", scanner.totalJunkGB)
        } else {
            return String(format: "%.0f MB", scanner.totalJunkGB * 1024)
        }
    }
}

// MARK: - Stat Chip
struct StatChip: View {
    enum ValueStyle { case `default`, green, orange }

    let label: String
    let value: String
    let valueStyle: ValueStyle

    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9.5, weight: .semibold))
                .kerning(0.8)
                .textCase(.uppercase)
                .foregroundStyle(DS.textTertiary)

            Group {
                switch valueStyle {
                case .green:
                    Text(value)
                        .foregroundStyle(DS.gradientSuccess)
                case .orange:
                    Text(value)
                        .foregroundStyle(DS.gradientJunk)
                case .default:
                    Text(value)
                        .foregroundStyle(DS.textPrimary)
                }
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .kerning(-0.3)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4), value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusChip)
                .fill(DS.bgPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusChip)
                        .strokeBorder(
                            hovering ? DS.borderDefault : DS.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(hovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.14), value: hovering)
        .onHover { h in hovering = h }
    }
}
