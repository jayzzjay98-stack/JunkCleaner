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
                .fill(T.borderDim)
                .frame(height: 1)

            HStack(spacing: 10) {
                if cleaner.isDeleting {
                    CleaningProgressRow(cleaner: cleaner)
                } else {
                    // Scan button
                    ScanButton(scanner: scanner)
                    
                    // Clean All button
                    CleanButton(scanner: scanner, cleaner: cleaner, canClean: canClean)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(T.bgRaised)
    }
}

// MARK: - Cleaning in progress
struct CleaningProgressRow: View {
    let cleaner: JunkCleaner

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(T.accLight)
            
            Text(cleaner.currentDeleteTask.lowercased())
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(T.accLight)
                .lineLimit(1)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(T.accDim)
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(T.acc.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Scan Button
struct ScanButton: View {
    @Bindable var scanner: JunkScanner
    @State private var hovering = false

    var body: some View {
        Button {
            Task { await scanner.startScan() }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                Text("Scan")
                    .font(.system(size: 13.5, weight: .medium))
            }
            .foregroundStyle(hovering ? T.txt1 : T.txt2)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(hovering ? T.bgFloat : T.bgHover)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(hovering ? T.borderHi : T.borderMid, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(scanner.isScanning)
        .opacity(scanner.isScanning ? 0.5 : 1.0)
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}

// MARK: - Clean All Button
struct CleanButton: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    let canClean: Bool

    @State private var hovering = false

    var body: some View {
        Button {
            guard let result = scanner.scanResult else { return }
            Task {
                await cleaner.clean(items: result.items.filter { $0.isSelected })
                // We don't auto-scan here, the user can scan again if they want
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 14, weight: .medium))
                Text("Clean All")
                    .font(.system(size: 13.5, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(T.accGrad)
                    
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: T.accGlow, radius: hovering ? 26 : 18, y: hovering ? 6 : 3)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canClean)
        .opacity(canClean ? 1.0 : 0.3)
        .scaleEffect(hovering && canClean ? 1.01 : 1.0)
        .offset(y: hovering && canClean ? -1 : 0)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
    }
}
