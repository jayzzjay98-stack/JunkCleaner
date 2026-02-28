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
            // ── Header ────────────────────────────────────────────────────
            AppHeader()

            // ── Body ──────────────────────────────────────────────────────
            ZStack {
                // Background base
                T.bgBase.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Status row ─────────────────────────────────────────────
                    if viewMode != .results {
                        HStack(spacing: 0) {
                            BadgeView(label: "Last Scan", value: scanner.scanResult != nil ? "Just now" : "Never")
                            Spacer()
                            PillView(scanner: scanner)
                        }
                        .padding(.horizontal, 26)
                        .padding(.top, 18)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // ── Main Area ──────────────────────────────────────────────
                    ZStack {
                        if viewMode == .idle || viewMode == .scanning {
                            ScanCircleView(scanner: scanner)
                                .transition(.opacity)
                        }

                        if viewMode == .results {
                            ResultsView(
                                scanner: scanner,
                                cleaner: cleaner,
                                showResult: $showResult,
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        viewMode = .idle
                                        // We don't necessarily cancel the scan when going back,
                                        // but we hide the results.
                                    }
                                }
                            )
                            .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // ── Action Bar ────────────────────────────────────────────────
            ActionBar(scanner: scanner, cleaner: cleaner)
        }
        .background(T.bgBase)
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

// MARK: - App Header
struct AppHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("System Overview")
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(T.txt1)
                    .kerning(-0.5)
                
                Text(macModelName)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(T.txt3)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(height: 64)
        .background(T.bgRaised)
        .overlay(alignment: .bottom) {
            Rectangle().fill(T.borderDim).frame(height: 1)
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
        if raw.hasPrefix("MacBookAir") { return "MacBook Air" }
        if raw.hasPrefix("MacBookPro") { return "MacBook Pro" }
        return "Mac15,13" // Mockup style fallback
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8.5, weight: .semibold))
                .kerning(1.3)
                .foregroundStyle(T.txt3)
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(T.txt1)
                .kerning(-0.3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(T.bgFloat)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(T.borderDim, lineWidth: 1))
        )
    }
}

// MARK: - Pill View
struct PillView: View {
    let scanner: JunkScanner
    
    private var isOptimal: Bool { (scanner.scanResult?.items.count ?? 0) == 0 && !scanner.isScanning }
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isOptimal ? T.ok : T.warn)
                .frame(width: 8, height: 8)
                .shadow(color: (isOptimal ? T.okGlow : T.warnGlow), radius: 6)
                .opacity(pulse ? 0.6 : 1.0)
                .scaleEffect(pulse ? 0.85 : 1.0)
            
            Text(isOptimal ? "System Optimal" : "Junk Found")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(T.txt1)
                .kerning(-0.2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(T.bgFloat)
                .overlay(Capsule().strokeBorder(T.borderDim, lineWidth: 1))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: isOptimal ? 2.4 : 1.8).repeatForever(autoreverses: true)) {
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
                    colors: [T.acc.opacity(0.14), T.acc.opacity(0.07), .clear],
                    center: .center, startRadius: 0, endRadius: 210
                ))
                .frame(width: 420, height: 420)
                .blur(radius: 20)
            
            ZStack {
                // Decorative Rings
                Circle().stroke(Color.white.opacity(0.022), lineWidth: 1).frame(width: 250)
                Circle().stroke(Color.white.opacity(0.022), lineWidth: 1).frame(width: 262)
                
                // Track
                Circle()
                    .stroke(Color.white.opacity(0.058), lineWidth: 13)
                    .frame(width: 210)
                
                // Fill
                Circle()
                    .trim(from: 0, to: scanner.isScanning ? progress : (scanner.scanResult != nil ? 1.0 : 1.0))
                    .stroke(
                        DS.ringGradient(for: scanner.totalJunkGB > 0 ? .junk : (scanner.scanResult != nil ? .clean : .idle)),
                        style: StrokeStyle(lineWidth: 13, lineCap: .round)
                    )
                    .frame(width: 210)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (scanner.totalJunkGB > 0 ? T.warnGlow : T.accGlow), radius: 14)
                    .animation(.easeInOut(duration: 0.35), value: progress)
                
                // Spinner (only while scanning)
                if scanner.isScanning {
                    Circle()
                        .trim(from: 0, to: 0.12) // match mockup spin arc
                        .stroke(T.accLight.opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 238)
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
                        colors: [Color(hex: "#141424"), T.bgVoid],
                        center: .center, startRadius: 0, endRadius: 86
                    ))
                    .frame(width: 172)
                
                // Center content
                if scanner.isScanning {
                    VStack(spacing: 7) {
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(T.txt1)
                            .kerning(-4)
                            .monospacedDigit()
                        
                        Text(scanner.currentScanTask.lowercased())
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(T.txt3)
                            .kerning(0.7)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 140)
                    }
                }
            }
        }
    }
}

// MARK: - Results View
struct ResultsView: View {
    let scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Overlay Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(T.txt2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(T.bgFloat)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(T.borderMid, lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if let result = scanner.scanResult {
                    Text("\(result.items.count) items · \(result.formattedTotal) found")
                        .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(T.txt3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .background(T.bgBase)
            .overlay(alignment: .bottom) { Rectangle().fill(T.borderDim).frame(height: 1) }

            ScrollView {
                VStack(spacing: 0) {
                    // Success banner within scroll or at top
                    if showResult {
                        SuccessBanner(cleaner: cleaner, showResult: $showResult)
                            .padding(.top, 8)
                            .padding(.horizontal, 6)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    JunkListSection(scanner: scanner)
                        .padding(.top, 4)
                }
            }
            .scrollIndicators(.visible)
        }
        .background(T.bgBase)
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
