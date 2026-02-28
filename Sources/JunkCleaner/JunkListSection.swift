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
                RoundedRectangle(cornerRadius: 14)
                    .fill(T.bgSurface)
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(T.b1, lineWidth: 1)
                    )

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(T.t3)
            }

            Text("Your Mac is ready")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(T.t2)

            Text("Run a scan to detect junk files, caches,\nand leftover data that can be removed.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(T.t3)
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
        VStack(spacing: 12) {
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
                .foregroundStyle(T.t3)
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
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                Text(item.emoji)
                    .font(.system(size: 13))
            }

            // Name + category
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(T.t1)
                    .kerning(-0.15)
                    .lineLimit(1)
                
                Text(item.catText)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(T.t3)
                    .kerning(0.2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Size + bar
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.formattedSize)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(T.t2)

                // Mini bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(T.bgHover)
                        .frame(width: 40, height: 2.5)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.accentColor.opacity(0.6))
                        .frame(width: max(3, 40 * barFraction), height: 2.5)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? T.bgSurface : Color.clear)
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.11)) { hovering = h } }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(T.b1)
                .frame(height: 1)
                .padding(.leading, 53)
        }
    }
}
