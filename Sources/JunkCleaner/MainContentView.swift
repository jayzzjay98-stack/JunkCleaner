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

            // ── Status row (Last scan + status badge) ─────────────────────
            HStack(spacing: 12) {
                LastScanBadge(scanner: scanner)
                Spacer()
                ScanStatusBadge(scanner: scanner)
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // ── Body ──────────────────────────────────────────────────────
            ZStack {
                // Idle / scanning state: show circle
                if viewMode == .idle || viewMode == .scanning {
                    ScanCircleView(scanner: scanner)
                        .transition(.opacity)
                }

                // Results state: show junk list with back button
                if viewMode == .results {
                    ResultsView(
                        scanner: scanner,
                        cleaner: cleaner,
                        showResult: $showResult,
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewMode = .idle
                                scanner.cancelScan()
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Action Bar ────────────────────────────────────────────────
            ActionBar(scanner: scanner, cleaner: cleaner)
        }
        .background(Color(hex: "#0c0c12"))
        // React to scan state changes
        .onChange(of: scanner.isScanning) { _, isScanning in
            withAnimation(.easeInOut(duration: 0.25)) {
                viewMode = isScanning ? .scanning : viewMode
            }
        }
        .onChange(of: scanner.scanResult) { _, result in
            if let r = result {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewMode = r.items.isEmpty ? .idle : .results
                }
            }
        }
        // Reset state each time the view appears (app re-opened / window shown)
        .onAppear {
            viewMode = .idle
            showResult = false
        }
    }
}

// MARK: - App Header (replaces SystemOverview)
struct AppHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("System Overview")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.white)
                Text(macModelName)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(height: 66)
        .background(Color(hex: "#12121c"))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }

    // Returns the real Mac model name via sysctl
    private var macModelName: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buf, &size, nil, 0)
        let raw = String(cString: buf) // e.g. "Mac15,13"
        // Map known identifiers to friendly names
        if raw.hasPrefix("Mac16,") { return "MacBook Air M4" }   // 2025 Air M4
        if raw.hasPrefix("Mac15,") { return "MacBook Pro M3" }
        if raw.hasPrefix("Mac14,") { return "MacBook Pro M2" }
        if raw.hasPrefix("Mac13,") { return "MacBook Air M2" }
        if raw.hasPrefix("MacBookAir") { return "MacBook Air" }
        if raw.hasPrefix("MacBookPro") { return "MacBook Pro" }
        if raw.hasPrefix("MacPro")     { return "Mac Pro" }
        if raw.hasPrefix("MacMini")    { return "Mac Mini" }
        if raw.hasPrefix("iMac")       { return "iMac" }
        return "MacBook Air M4"   // default fallback
    }
}

// MARK: - Last Scan Badge
struct LastScanBadge: View {
    let scanner: JunkScanner

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("LAST SCAN")
                .font(.system(size: 9, weight: .semibold))
                .kerning(1.0)
                .foregroundStyle(Color.white.opacity(0.3))
            Text(scanner.scanResult != nil ? "Just now" : "Never")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#18182a"))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
        )
    }
}

// MARK: - Scan Status Badge
struct ScanStatusBadge: View {
    let scanner: JunkScanner

    private var hasJunk: Bool { scanner.totalJunkGB > 0 && scanner.scanResult != nil }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(hasJunk ? Color(hex: "#f97316") : Color(hex: "#34d399"))
                .frame(width: 8, height: 8)
                .shadow(color: (hasJunk ? Color(hex: "#f97316") : Color(hex: "#34d399")).opacity(0.6), radius: 4)
            Text(hasJunk ? "Junk Found" : "System Optimal")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(hex: "#18182a"))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.07), lineWidth: 1))
        )
    }
}

// MARK: - Scan Circle (shown when idle or scanning)
struct ScanCircleView: View {
    let scanner: JunkScanner
    @State private var spinAngle: Double = 0

    private var progress: Double {
        scanner.isScanning ? scanner.scanProgress : 0
    }

    var body: some View {
        ZStack {
            // Ambient glow
            RadialGradient(
                colors: [Color(hex: "#667eea").opacity(0.15), Color(hex: "#764ba2").opacity(0.08), .clear],
                center: .center, startRadius: 50, endRadius: 200
            )
            .frame(width: 480, height: 400)

            ZStack {
                // Decorative outer rings
                Circle().stroke(Color.white.opacity(0.03), lineWidth: 1).frame(width: 290)
                Circle().stroke(Color.white.opacity(0.025), lineWidth: 1).frame(width: 330)

                // Progress track
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 11)
                    .frame(width: 210)

                // Progress fill — only visible while scanning
                if scanner.isScanning {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [Color(hex: "#667eea"), Color(hex: "#a78bfa"), Color(hex: "#667eea")],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round)
                        )
                        .frame(width: 210)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)

                    // Spinning arc overlay
                    Circle()
                        .trim(from: 0, to: 0.18)
                        .stroke(Color(hex: "#a78bfa").opacity(0.5), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 234)
                        .rotationEffect(.degrees(spinAngle))
                        .onAppear {
                            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                                spinAngle = 360
                            }
                        }
                } else {
                    // Idle: full ring (static, no number)
                    Circle()
                        .trim(from: 0, to: 1.0)
                        .stroke(
                            AngularGradient(
                                colors: [Color(hex: "#667eea"), Color(hex: "#a78bfa"), Color(hex: "#667eea")],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round)
                        )
                        .frame(width: 210)
                        .rotationEffect(.degrees(-90))
                }

                // Inner filled circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#1e1e30"), Color(hex: "#0c0c12")],
                            center: .center, startRadius: 0, endRadius: 90
                        )
                    )
                    .frame(width: 180)

                // Center content
                if scanner.isScanning {
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: progress)

                        Text(scanner.currentScanTask)
                            .font(.system(size: 9, weight: .medium))
                            .kerning(0.8)
                            .foregroundStyle(Color.white.opacity(0.4))
                            .lineLimit(1)
                            .frame(width: 140)
                            .multilineTextAlignment(.center)
                            .animation(.easeInOut, value: scanner.currentScanTask)
                    }
                }
                // Idle: show nothing inside the ring (empty circle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Results View (shown after scan finds junk)
struct ResultsView: View {
    let scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Back button row
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color.white.opacity(0.55))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                if let result = scanner.scanResult {
                    Text("\(result.items.count) items · \(String(format: "%.1f GB", scanner.totalJunkGB))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)

            // Success banner
            if showResult {
                SuccessBanner(cleaner: cleaner, showResult: $showResult)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Junk list
            ScrollView {
                JunkListSection(scanner: scanner)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
