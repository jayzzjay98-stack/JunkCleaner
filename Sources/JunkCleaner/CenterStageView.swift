import SwiftUI

// MARK: - Center Stage (lg:col-span-8)
struct CenterStageView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool

    private var healthScore: Int {
        guard scanner.scanResult != nil else { return 98 }
        let gb = scanner.totalJunkGB
        if gb > 10 { return 68 }
        if gb > 5  { return 78 }
        if gb > 1  { return 89 }
        return 98
    }
    private var isClean: Bool { scanner.totalJunkGB == 0 && scanner.scanResult != nil }

    var body: some View {
        VStack(spacing: 0) {
            // Status chips row (absolute top in HTML → top of VStack here)
            HStack {
                // "Last Scan" chip
                GlassMiniCard(label: "Last Scan",
                              value: scanner.scanResult != nil ? "Just now" : "Never")

                Spacer()

                // Status badge
                SystemStatusBadge(isClean: isClean, hasResult: scanner.scanResult != nil)
            }
            .padding(.bottom, 16)

            Spacer(minLength: 0)

            // ── Sphere ────────────────────────────────────────────────
            SphereWidget(
                healthScore: healthScore,
                isScanning: scanner.isScanning
            )

            Spacer(minLength: 0)

            // ── Scan progress ─────────────────────────────────────────
            if scanner.isScanning {
                ScanProgressWidget(scanner: scanner)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // ── Success banner ────────────────────────────────────────
            if showResult, let result = cleaner.lastResult {
                SuccessBannerView(result: result) {
                    withAnimation { showResult = false }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // ── Main scan button ──────────────────────────────────────
            MainScanButton(scanner: scanner, cleaner: cleaner)
                .padding(.bottom, 8)

            Text("Estimated time: ~2 mins")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(T.textFaint)

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .animation(.easeInOut(duration: 0.25), value: scanner.isScanning)
        .animation(.spring(response: 0.4), value: showResult)
    }
}

// MARK: - Glass mini card (Last Scan / System status)
struct GlassMiniCard: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .kerning(2)
                .foregroundStyle(T.textFaint)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(T.textWhite)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .glassPanel()
    }
}

struct SystemStatusBadge: View {
    let isClean: Bool
    let hasResult: Bool
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isClean ? T.green400 : T.orange400)
                .frame(width: 8, height: 8)
                .shadow(color: (isClean ? T.green400 : T.orange400).opacity(0.7), radius: 5)
            Text(hasResult ? (isClean ? "System Optimal" : "Junk Found") : "System Optimal")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(T.textWhite)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .glassPanel()
    }
}

// MARK: - The Sphere
struct SphereWidget: View {
    let healthScore: Int
    let isScanning: Bool

    @State private var ring1: Double = 0
    @State private var ring2: Double = 0
    @State private var ring3: Double = 0
    @State private var sphereHover = false

    var body: some View {
        ZStack {
            // Outer ring 1 – border-primary/20, spin 10s
            Circle()
                .stroke(T.primary.opacity(0.20), lineWidth: 1)
                .frame(width: 330, height: 330)
                .rotationEffect(.degrees(ring1))

            // Outer ring 2 – border-indigo-400/10, reverse 15s
            Circle()
                .stroke(T.indigo500.opacity(0.10), lineWidth: 1)
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-ring2))

            // Partial ring – border-t-primary/30 border-b-primary/30, 20s, opacity-50
            Circle()
                .trim(from: 0, to: 0.65)
                .stroke(
                    T.primary.opacity(0.30),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 370, height: 370)
                .rotationEffect(.degrees(ring3))
                .opacity(0.5)

            // ── Glass sphere (.sphere in HTML) ───────────────────────
            ZStack {
                // Base radial gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                T.primary.opacity(0.20),
                                Color(hex: "#1e1b4b").opacity(0.80)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: 130
                        )
                    )
                    .frame(width: 256, height: 256)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30, x: -10, y: -10)
                    .shadow(color: T.primary.opacity(0.30), radius: 30)

                // Inner top-right highlight (from-transparent via-primary/10 to-white/10)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, T.primary.opacity(0.10), Color.white.opacity(0.10)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 256, height: 256)

                // Center content
                VStack(spacing: 6) {
                    if isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.3)
                        Text("Scanning…")
                            .font(.system(size: 12, weight: .light))
                            .kerning(1)
                            .foregroundStyle(T.textDim)
                            .padding(.top, 6)
                    } else {
                        // "98%" – font-light text-5xl glow-text
                        Text("\(healthScore)%")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(T.textWhite)
                            .shadow(color: T.violet400.opacity(0.5), radius: 10)
                        Text("Health Score")
                            .font(.system(size: 11, weight: .regular))
                            .kerning(2)
                            .textCase(.uppercase)
                            .foregroundStyle(T.textDim)
                    }
                }
            }
            .scaleEffect(sphereHover ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.4), value: sphereHover)
            .onHover { h in sphereHover = h }
        }
        .frame(width: 400, height: 400)
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false))  { ring1 = 360 }
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false))  { ring2 = 360 }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false))  { ring3 = 360 }
        }
    }
}

// MARK: - Scan progress bar
struct ScanProgressWidget: View {
    let scanner: JunkScanner
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 3)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [T.blue400, T.indigo500, T.violet400],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, geo.size.width * scanner.scanProgress),
                            height: 3
                        )
                        .shadow(color: T.indigo500.opacity(0.5), radius: 5)
                        .animation(.easeInOut(duration: 0.3), value: scanner.scanProgress)
                }
            }
            .frame(height: 3)
            Text(scanner.currentScanTask)
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(T.textFaint)
                .lineLimit(1)
        }
    }
}

// MARK: - Main Scan Button  (.glass-button in HTML)
struct MainScanButton: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @State private var hovering = false
    @State private var pressing = false

    private var canClean: Bool {
        guard let r = scanner.scanResult else { return false }
        return !r.items.isEmpty && !scanner.isScanning && !cleaner.isDeleting
    }

    var body: some View {
        HStack(spacing: 16) {
            // Scan button
            Button {
                Task { await scanner.startScan() }
            } label: {
                ZStack {
                    // Hover slide-up fill (matching HTML group-hover:translate-y-0)
                    if hovering {
                        Capsule()
                            .fill(T.primary.opacity(0.20))
                            .transition(.opacity)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 18, weight: .medium))
                        Text("Start Deep Scan")
                            .font(.system(size: 17, weight: .medium))
                            .kerning(0.5)
                    }
                    .foregroundStyle(T.textWhite)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 16)
                }
                .background(
                    Capsule()
                        .fill(T.glassButtonGradient)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(
                            color: hovering ? T.primary.opacity(0.40) : T.primary.opacity(0.15),
                            radius: hovering ? 20 : 8
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(scanner.isScanning)
            .opacity(scanner.isScanning ? 0.5 : 1)
            .scaleEffect(pressing ? 0.97 : 1)
            .onHover { h in withAnimation(.easeInOut(duration: 0.25)) { hovering = h } }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in pressing = true }
                    .onEnded { _ in pressing = false }
            )
            .animation(.easeInOut(duration: 0.12), value: pressing)

            // Clean All button (appears when junk found)
            if canClean {
                Button {
                    guard let r = scanner.scanResult else { return }
                    Task {
                        await cleaner.clean(items: r.items)
                        await scanner.startScan()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Clean All")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(T.textWhite)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [T.primary, T.blue500],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: T.primary.opacity(0.4), radius: 14)
                    )
                }
                .buttonStyle(.plain)
                .disabled(cleaner.isDeleting)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: canClean)
    }
}

// MARK: - Success Banner
struct SuccessBannerView: View {
    let result: JunkCleaner.CleanResult
    let onClose: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(T.green400.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(T.green400)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Freed \(result.formattedFreed)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(T.green400)
                Text("\(result.deletedCount) files removed" +
                     (result.failedCount > 0 ? " · ⚠️ \(result.failedCount) failed" : ""))
                    .font(.system(size: 11))
                    .foregroundStyle(T.textFaint)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(T.textFaint)
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }.buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(T.green400.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(T.green400.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
