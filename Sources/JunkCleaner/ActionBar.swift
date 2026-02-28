import SwiftUI

struct ActionBar: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    private var canClean: Bool {
        guard let result = scanner.scanResult else { return false }
        return !result.items.isEmpty && !scanner.isScanning && !cleaner.isDeleting
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DS.borderSubtle)
                .frame(height: 1)

            HStack(spacing: 8) {
                if cleaner.isDeleting {
                    // Cleaning in progress
                    CleaningProgressRow(cleaner: cleaner)
                } else {
                    // Scan button
                    ScanButton(scanner: scanner)
                    // Clean All button
                    CleanButton(scanner: scanner, cleaner: cleaner, canClean: canClean)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(
            ZStack {
                DS.bgSecondary
                // Frosted top edge gradient
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [DS.bgSecondary.opacity(0), DS.bgSecondary],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 10)
                    .offset(y: -10)
                    Spacer()
                }
            }
        )
    }
}

// MARK: - Cleaning in progress
struct CleaningProgressRow: View {
    let cleaner: JunkCleaner

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(DS.lavender)
            Text(cleaner.currentDeleteTask)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.lavender)
                .lineLimit(1)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusButton)
                .fill(DS.lavender.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusButton)
                        .strokeBorder(DS.lavender.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Scan Button
struct ScanButton: View {
    @Bindable var scanner: JunkScanner
    @State private var hovering = false
    @State private var pressing = false

    var body: some View {
        Button {
            Task { await scanner.startScan() }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                Text("Scan")
                    .font(.system(size: 13.5, weight: .semibold))
            }
            .foregroundStyle(hovering ? DS.textPrimary : DS.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusButton)
                    .fill(hovering ? DS.bgTertiary : DS.bgQuaternary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusButton)
                            .strokeBorder(
                                hovering ? DS.borderDefault : DS.borderSubtle,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(scanner.isScanning)
        .opacity(scanner.isScanning ? 0.5 : 1.0)
        .scaleEffect(pressing ? 0.97 : 1.0)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.12)) { hovering = h }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressing = true }
                .onEnded { _ in pressing = false }
        )
        .animation(.easeInOut(duration: 0.12), value: pressing)
        .keyboardShortcut("s", modifiers: [.command])
    }
}

// MARK: - Clean All Button
struct CleanButton: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    let canClean: Bool

    @State private var hovering = false
    @State private var pressing = false
    @State private var gradientOffset: CGFloat = 0

    var body: some View {
        Button {
            guard let result = scanner.scanResult else { return }
            Task {
                await cleaner.clean(items: result.items.filter { $0.isSelected })
                await scanner.startScan()
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Clean All")
                    .font(.system(size: 13.5, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusButton)
                    .fill(
                        LinearGradient(
                            colors: [DS.violet, DS.purple, DS.lavender],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // Hover brightener
                        RoundedRectangle(cornerRadius: DS.radiusButton)
                            .fill(Color.white.opacity(hovering ? 0.07 : 0))
                    )
                    .overlay(
                        // Glass top highlight
                        RoundedRectangle(cornerRadius: DS.radiusButton)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(
                        color: DS.glowAccent.opacity(hovering ? 0.7 : 0.4),
                        radius: hovering ? 18 : 10,
                        x: 0, y: hovering ? 6 : 3
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canClean)
        .opacity(canClean ? 1.0 : 0.3)
        .scaleEffect(pressing ? 0.97 : (hovering ? 1.01 : 1.0))
        .offset(y: hovering && canClean ? -1 : 0)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) { hovering = h }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressing = true }
                .onEnded { _ in pressing = false }
        )
        .animation(.easeInOut(duration: 0.12), value: pressing)
        .keyboardShortcut("c", modifiers: [.command])
    }
}
