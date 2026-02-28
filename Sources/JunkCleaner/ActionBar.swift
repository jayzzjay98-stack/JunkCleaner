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
                .fill(T.b1)
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
        .background(T.bgSidebar)
    }
}

// MARK: - Cleaning in progress
struct CleaningProgressRow: View {
    let cleaner: JunkCleaner

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .tint(T.pLt)
            
            Text(cleaner.currentDeleteTask.lowercased())
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(T.pLt)
                .lineLimit(1)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(T.pDim)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(T.p.opacity(0.2), lineWidth: 1)
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
                    .font(.system(size: 14, weight: .regular))
                Text("Scan")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(-0.2)
            }
            .foregroundStyle(hovering ? T.t1 : T.t2)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(hovering ? T.bgHover : T.bgActive)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(hovering ? T.b3 : T.b2, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(scanner.isScanning)
        .opacity(scanner.isScanning ? 0.5 : 1.0)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
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
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .regular))
                Text("Clean All")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(-0.2)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(T.pGrad)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: T.pGlow, radius: hovering ? 24 : 16, y: hovering ? 4 : 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canClean)
        .opacity(canClean ? 1.0 : 0.28)
        .scaleEffect(hovering && canClean ? 1.01 : 1.0)
        .offset(y: hovering && canClean ? -1 : 0)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
    }
}
