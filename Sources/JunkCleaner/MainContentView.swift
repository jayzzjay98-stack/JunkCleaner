import SwiftUI
import AppKit
import Darwin

// MARK: - Main Content
struct MainContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool

    // Controls whether we show scan result list or idle circle
    @State private var viewMode: ViewMode = .idle

    enum ViewMode { case idle, scanning, results }

    var body: some View {
        VStack(spacing: 0) {
            // ── Topbar ────────────────────────────────────────────────────
            TopbarView()

            // ── Content area ───────────────────────────────────────────────
            ZStack {
                // Background base
                T.bgMain.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Info Strip ─────────────────────────────────────────────
                    HStack(spacing: 0) {
                        InfoBadge(label: "Last Scan", value: scanner.scanResult != nil ? "Just now" : "Never")
                        Spacer()
                        StatusChip(isOptimal: (scanner.scanResult?.items.count ?? 0) == 0 && !scanner.isScanning)
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .opacity(viewMode == .results ? 0 : 1) // Hide when showing results

                    // ── Hero / Results Area ───────────────────────────────────────
                    ZStack {
                        if viewMode == .idle || viewMode == .scanning {
                            ScanCircleView(scanner: scanner)
                                .transition(.opacity)
                        }

                        if viewMode == .results {
                            ResultsOverlay(
                                scanner: scanner,
                                cleaner: cleaner,
                                showResult: $showResult,
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        viewMode = .idle
                                    }
                                }
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // ── Action Bar ────────────────────────────────────────────────
            ActionBar(scanner: scanner, cleaner: cleaner)
        }
        .background(T.bgMain)
        .onChange(of: scanner.isScanning) { _, isScanning in
            withAnimation(.easeInOut(duration: 0.3)) {
                if isScanning {
                    viewMode = .scanning
                }
            }
        }
        .onChange(of: scanner.scanResult) { _, result in
            if let r = result, !scanner.isScanning {
                withAnimation(.easeInOut(duration: 0.4)) {
                    viewMode = r.items.isEmpty ? .idle : .results
                }
            }
        }
        .onAppear {
            if scanner.scanResult != nil {
                viewMode = .results
            } else if scanner.isScanning {
                viewMode = .scanning
            } else {
                viewMode = .idle
            }
        }
    }
}

// MARK: - Topbar
struct TopbarView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("System Overview")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(T.t1)
                    .kerning(-0.5)
                
                Text(macModelName)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(T.t3)
                    .kerning(-0.1)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(height: 60)
        .background(T.bgSidebar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(T.b1).frame(height: 1)
        }
    }

    private var macModelName: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buf, &size, nil, 0)
        let raw = String(cString: buf)
        if raw.hasPrefix("Mac16,") { return "MacBook Air M4" }
        if raw.hasPrefix("Mac15,") { return "MacBook Pro M3" }
        if raw.hasPrefix("Mac14,") { return "MacBook Pro M2" }
        if raw.hasPrefix("Mac13,") { return "MacBook Air M2" }
        return "Mac15,13" // Mockup style fallback
    }
}

// MARK: - Info Badge
struct InfoBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .semibold))
                .kerning(1.4)
                .foregroundStyle(T.t3)
            
            Text(value)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(T.t1)
                .kerning(-0.3)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(T.bgSurface)
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(T.b1, lineWidth: 1))
        )
    }
}

// MARK: - Status Chip
struct StatusChip: View {
    let isOptimal: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isOptimal ? T.ok : T.warn)
                .frame(width: 7, height: 7)
                .shadow(color: (isOptimal ? T.okGlow : T.warnGlow), radius: 6)
                .opacity(pulse ? 0.5 : 1.0)
            
            Text(isOptimal ? "System Optimal" : "Junk Found")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(T.t1)
                .kerning(-0.2)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(T.bgSurface)
                .overlay(Capsule().strokeBorder(T.b1, lineWidth: 1))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: isOptimal ? 2.5 : 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Scan Circle View
struct ScanCircleView: View {
    let scanner: JunkScanner
    @State private var spinAngle: Double = 0
    
    private var progress: Double { scanner.isScanning ? scanner.scanProgress : 0 }
    
    var body: some View {
        ZStack {
            // Atmospheric glow
            Circle()
                .fill(RadialGradient(
                    colors: [T.p.opacity(0.11), Color(hex: "#5a3cc8").opacity(0.055), .clear],
                    center: .center, startRadius: 0, endRadius: 190
                ))
                .frame(width: 380, height: 380)
                .blur(radius: 20)
            
            ZStack {
                // Decorative Rings
                Circle().stroke(Color.white.opacity(0.02), lineWidth: 1).frame(width: 262) // r 131
                Circle().stroke(Color.white.opacity(0.016), lineWidth: 1).frame(width: 272) // r 136
                
                // Track
                Circle()
                    .stroke(Color.white.opacity(0.055), lineWidth: 13)
                    .frame(width: 216) // r 108
                
                // Fill
                Circle()
                    .trim(from: 0, to: scanner.isScanning ? progress : (scanner.scanResult != nil ? 1.0 : 1.0))
                    .stroke(
                        DS.ringGradient(for: scanner.totalJunkGB > 0 ? .junk : (scanner.scanResult != nil ? .clean : .idle)),
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .frame(width: 216)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (scanner.totalJunkGB > 0 ? T.warnGlow : T.p.opacity(0.5)), radius: 10)
                    .shadow(color: (scanner.totalJunkGB > 0 ? T.warnGlow.opacity(0.5) : T.p.opacity(0.22)), radius: 24)
                    .animation(.easeInOut(duration: 0.35), value: progress)
                
                // Spinner
                if scanner.isScanning {
                    Circle()
                        .trim(from: 0, to: 0.1) // 70/678
                        .stroke(T.p.opacity(0.45), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 242) // r 121
                        .rotationEffect(.degrees(spinAngle))
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                spinAngle = 360
                            }
                        }
                }
                
                // Inner Dark Fill
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(hex: "#151524"), Color(hex: "#0d0d1a"), Color(hex: "#09090f")],
                        center: .center, startRadius: 0, endRadius: 88
                    ))
                    .frame(width: 176) // r 88
                
                // Center content
                VStack(spacing: 8) {
                    if scanner.isScanning {
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.system(size: 50, weight: .light))
                            .foregroundStyle(T.t1)
                            .kerning(-4)
                            .monospacedDigit()
                        
                        Text(scanner.currentScanTask.lowercased())
                            .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                            .foregroundStyle(T.t3)
                            .kerning(0.5)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 132)
                            .lineSpacing(1.55)
                    }
                }
            }
        }
    }
}

// MARK: - Results Overlay
struct ResultsOverlay: View {
    let scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("Back")
                            .font(.system(size: 12.5, weight: .medium))
                    }
                    .foregroundStyle(T.t2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(T.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(T.b2, lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if let result = scanner.scanResult {
                    Text("\(result.items.count) items · \(result.formattedTotal)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(T.t3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(T.bgMain)
            .overlay(alignment: .bottom) { Rectangle().fill(T.b1).frame(height: 1) }

            ScrollView {
                VStack(spacing: 0) {
                    if showResult {
                        SuccessBanner(cleaner: cleaner, showResult: $showResult)
                            .padding(.top, 10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    JunkListSection(scanner: scanner)
                        .padding(.top, 4)
                }
            }
            .scrollIndicators(.visible)
        }
        .background(T.bgMain)
    }
}

extension ScanResult {
    var formattedTotal: String {
        let gb = Double(totalSize) / 1_073_741_824.0
        if gb >= 1.0 { return String(format: "%.1f GB", gb) }
        let mb = Double(totalSize) / 1_048_576.0
        return String(format: "%.0f MB", mb)
    }
}
