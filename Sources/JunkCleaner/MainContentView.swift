import SwiftUI
import AppKit
import Darwin

struct MainContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Top header bar
            SystemOverviewHeader()

            // Body: left center stage + right panel
            HStack(alignment: .top, spacing: 0) {
                // Left: hero circle + action bar
                VStack(spacing: 0) {
                    // Last scan + status row
                    HStack(spacing: 12) {
                        LastScanBadge(scanner: scanner)
                        Spacer()
                        ScanStatusBadge(scanner: scanner)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 4)

                    // Health Score circle (main hero)
                    HealthScoreHero(scanner: scanner)
                        .frame(maxWidth: .infinity)

                    // Scan progress bar (shown while scanning)
                    ScanProgressSection(scanner: scanner)

                    // Junk list (shown after scan)
                    if let result = scanner.scanResult, !result.items.isEmpty {
                        JunkListSection(scanner: scanner)
                    }

                    // Success banner
                    if showResult {
                        SuccessBanner(cleaner: cleaner, showResult: $showResult)
                            .padding(.horizontal, 22)
                            .padding(.bottom, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer()

                    ActionBar(scanner: scanner, cleaner: cleaner)
                }
                .frame(maxWidth: .infinity)

                // Right divider
                Rectangle()
                    .fill(DS.borderSubtle)
                    .frame(width: 1)
                    .padding(.vertical, 0)

                // Right panel — no stats, just disk junk card
                DiskJunkPanel(scanner: scanner, cleaner: cleaner)
                    .frame(width: 270)
            }
        }
        .background(DS.bgPrimary)
    }
}

// MARK: - System Overview Header
struct SystemOverviewHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("System Overview")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(DS.textPrimary)
                Text(systemInfoString)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(DS.textSecondary.opacity(0.7))
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(height: 68)
        .background(DS.bgSecondary)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DS.borderSubtle).frame(height: 1)
        }
    }

    private var systemInfoString: String {
        let model = getMacModel()
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(model) · macOS \(version.majorVersion).\(version.minorVersion)"
    }

    private func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let raw = String(cString: model)
        if raw.contains("MacBookPro") { return "MacBook Pro" }
        if raw.contains("MacBookAir") { return "MacBook Air" }
        if raw.contains("MacPro")     { return "Mac Pro" }
        if raw.contains("MacMini")    { return "Mac Mini" }
        if raw.contains("iMac")       { return "iMac" }
        return "Mac"
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
                .foregroundStyle(DS.textTertiary)
            Text(scanner.scanResult != nil ? "Just now" : "Never")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusCard)
                .fill(DS.bgSecondary)
                .overlay(RoundedRectangle(cornerRadius: DS.radiusCard).strokeBorder(DS.borderSubtle, lineWidth: 1))
        )
    }
}

// MARK: - Scan Status Badge
struct ScanStatusBadge: View {
    let scanner: JunkScanner

    private var isClean: Bool {
        guard let r = scanner.scanResult else { return false }
        return r.items.isEmpty
    }

    private var hasJunk: Bool {
        scanner.totalJunkGB > 0 && scanner.scanResult != nil
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(hasJunk ? DS.warning : DS.success)
                .frame(width: 8, height: 8)
                .shadow(color: hasJunk ? DS.glowJunk : DS.glowSuccess, radius: 4)
            Text(hasJunk ? "Junk Found" : "System Optimal")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DS.bgSecondary)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DS.borderSubtle, lineWidth: 1))
        )
    }
}

// MARK: - Health Score Hero (big circle like the design)
struct HealthScoreHero: View {
    let scanner: JunkScanner

    // Health score: 100% when clean, decreases with junk
    private var healthScore: Double {
        if scanner.isScanning { return animatingScore }
        guard let result = scanner.scanResult else { return 100.0 }
        if result.items.isEmpty { return 100.0 }
        // Lose up to 30 points based on junk (0–5 GB = 0–30 pts)
        let penalty = min(30.0, scanner.totalJunkGB * 6.0)
        return max(70.0, 100.0 - penalty)
    }

    @State private var animatingScore: Double = 100.0
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Ambient glow background
            RadialGradient(
                colors: [DS.violet.opacity(0.18), DS.purple.opacity(0.10), .clear],
                center: .center,
                startRadius: 60,
                endRadius: 200
            )
            .frame(width: 400, height: 360)

            VStack(spacing: 0) {
                ZStack {
                    // Outer decorative rings
                    Circle()
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                        .frame(width: 260, height: 260)

                    Circle()
                        .stroke(Color.white.opacity(0.03), lineWidth: 1)
                        .frame(width: 300, height: 300)

                    // Progress ring (track)
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 10)
                        .frame(width: 200, height: 200)

                    // Progress ring (fill)
                    Circle()
                        .trim(from: 0, to: healthScore / 100.0)
                        .stroke(
                            AngularGradient(
                                colors: healthScore < 90
                                    ? [DS.warning, DS.warningAmber, DS.warning]
                                    : [DS.violet, DS.lavender, DS.violet],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0, dampingFraction: 0.7), value: healthScore)

                    // Scanning spinner overlay
                    if scanner.isScanning {
                        Circle()
                            .trim(from: 0.0, to: 0.25)
                            .stroke(DS.lavender.opacity(0.6), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(rotationAngle))
                            .onAppear {
                                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                    rotationAngle = 360
                                }
                            }
                    }

                    // Inner circle (darker fill)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DS.bgTertiary, DS.bgPrimary],
                                center: .center,
                                startRadius: 0,
                                endRadius: 90
                            )
                        )
                        .frame(width: 172, height: 172)

                    // Center text
                    VStack(spacing: 4) {
                        if scanner.isScanning {
                            Text(String(format: "%.0f%%", scanner.scanProgress * 100))
                                .font(.system(size: 52, weight: .light, design: .rounded))
                                .foregroundStyle(DS.textPrimary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.easeInOut, value: scanner.scanProgress)
                        } else {
                            Text(String(format: "%.0f%%", healthScore))
                                .font(.system(size: 52, weight: .light, design: .rounded))
                                .foregroundStyle(DS.textPrimary)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.8), value: healthScore)
                        }
                        Text(scanner.isScanning ? "SCANNING" : "HEALTH SCORE")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.5)
                            .foregroundStyle(DS.textSecondary.opacity(0.6))
                    }
                }
                .frame(width: 320, height: 320)
            }
        }
        .frame(height: 340)
        .clipped()
    }
}

// MARK: - Right Panel: Disk Junk only
struct DiskJunkPanel: View {
    let scanner: JunkScanner
    let cleaner: JunkCleaner

    private var totalGB: Double { scanner.getDiskInfo().0 }
    private var freeGB: Double { scanner.getDiskInfo().1 }
    private var usedGB: Double { totalGB - freeGB }
    private var usedPercent: Int { totalGB > 0 ? Int((usedGB / totalGB) * 100) : 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Disk Space card
                DiskSpaceCard(
                    usedPercent: usedPercent,
                    usedGB: usedGB,
                    totalGB: totalGB,
                    junkGB: scanner.totalJunkGB,
                    cleaner: cleaner,
                    scanner: scanner
                )
            }
            .padding(16)
        }
        .background(DS.bgSecondary)
    }
}

// MARK: - Disk Space Card
struct DiskSpaceCard: View {
    let usedPercent: Int
    let usedGB: Double
    let totalGB: Double
    let junkGB: Double
    let cleaner: JunkCleaner
    let scanner: JunkScanner
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusIcon)
                        .fill(Color(hex: "#22d3ee").opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(hex: "#22d3ee"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Disk Space")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.textPrimary)
                    Text("Macintosh HD")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.textSecondary.opacity(0.6))
                }
                Spacer()
                Text("\(usedPercent)%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.textPrimary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.bgQuaternary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#22d3ee"), Color(hex: "#14b8a6")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * (totalGB > 0 ? usedGB / totalGB : 0.5)), height: 6)
                        .animation(.spring(response: 0.8), value: usedGB)
                }
            }
            .frame(height: 6)

            // Stats row
            HStack {
                Text(String(format: "Used: %.1f GB", usedGB))
                    .font(.system(size: 11))
                    .foregroundStyle(DS.textTertiary)
                Spacer()
                Text(String(format: "Free: %.0f GB", max(0, totalGB - usedGB)))
                    .font(.system(size: 11))
                    .foregroundStyle(DS.textTertiary)
            }

            Divider().background(DS.borderSubtle)

            // Junk Found row
            HStack {
                Text("Junk Found")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.textSecondary)
                Spacer()
                Text(junkGB > 0 ? String(format: "%.1f GB", junkGB) : "0.0 GB")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(junkGB > 0 ? DS.warning : DS.textSecondary.opacity(0.5))
            }

            // Clean Now button
            Button {
                guard let result = scanner.scanResult else { return }
                Task { await cleaner.clean(items: result.items.filter { $0.isSelected }) }
            } label: {
                Text("Clean Now")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: DS.radiusButton)
                            .fill(hovering ? DS.bgQuaternary : DS.bgTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.radiusButton)
                                    .strokeBorder(DS.borderDefault, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(scanner.scanResult == nil || junkGB == 0)
            .opacity(scanner.scanResult != nil && junkGB > 0 ? 1.0 : 0.4)
            .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.radiusCard)
                .fill(DS.bgTertiary)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.radiusCard)
                        .strokeBorder(DS.borderSubtle, lineWidth: 1)
                )
        )
    }
}

