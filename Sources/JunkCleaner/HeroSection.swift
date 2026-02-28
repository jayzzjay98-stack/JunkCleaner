import SwiftUI

struct HeroSection: View {
    let scanner: JunkScanner

    private var ringState: RingState {
        if scanner.totalJunkGB > 0 && scanner.scanResult != nil { return .junk }
        return .idle
    }

    var body: some View {
        ZStack {
            // Mesh background
            HeroMeshBackground()

            VStack(spacing: 0) {
                // Top row: number + donut
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Junk to Clean")
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(1.2)
                            .textCase(.uppercase)
                            .foregroundStyle(DS.textTertiary)
                            .padding(.bottom, 8)

                        // Giant number
                        HStack(alignment: .bottom, spacing: 3) {
                            Text(scanner.isScanning ? "..." : String(format: "%.1f", scanner.totalJunkGB))
                                .font(.system(size: 62, weight: .heavy, design: .rounded))
                                .kerning(-4)
                                .foregroundStyle(
                                    scanner.totalJunkGB > 0 && scanner.scanResult != nil
                                    ? DS.gradientJunk
                                    : DS.gradientHeroText
                                )
                                .monospacedDigit()
                                .animation(.spring(response: 0.5), value: scanner.totalJunkGB)
                                .contentTransition(.numericText(countsDown: false))

                            Text("GB")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(DS.textTertiary)
                                .kerning(-1)
                                .padding(.bottom, 6)
                        }

                        Text(captionText)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(DS.textTertiary)
                            .padding(.top, 3)
                            .lineLimit(1)
                            .animation(.easeInOut, value: captionText)
                    }

                    Spacer()

                    // Donut ring
                    DonutRing(scanner: scanner, ringState: ringState)
                }
                .padding(.bottom, 18)

                // Disk usage bar
                DiskUsageBar(scanner: scanner)
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
            .padding(.bottom, 18)
        }
    }

    private var captionText: String {
        if scanner.isScanning { return scanner.currentScanTask }
        if let result = scanner.scanResult {
            if result.items.isEmpty { return "Your Mac is clean ✦" }
            return "\(result.items.count) items found · ready to clean"
        }
        return "Ready to scan your Mac"
    }
}

// MARK: - Mesh Background
struct HeroMeshBackground: View {
    var body: some View {
        ZStack {
            // Grid texture
            Canvas { ctx, size in
                let step: CGFloat = 28
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += step
                }
                ctx.stroke(path, with: .color(.white.opacity(0.018)), lineWidth: 1)
            }
            .mask(
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // Radial glow top-right
            RadialGradient(
                colors: [DS.lavender.opacity(0.1), .clear],
                center: UnitPoint(x: 0.9, y: 0),
                startRadius: 0,
                endRadius: 200
            )

            // Faint glow bottom-left
            RadialGradient(
                colors: [DS.violet.opacity(0.05), .clear],
                center: UnitPoint(x: -0.1, y: 1.1),
                startRadius: 0,
                endRadius: 180
            )
        }
    }
}

// MARK: - Donut Ring
struct DonutRing: View {
    let scanner: JunkScanner
    let ringState: RingState

    private var freePercent: Double {
        let (total, free) = scanner.getDiskInfo()
        guard total > 0 else { return 0.75 }
        return free / total
    }

    private var strokeColor: Color {
        switch ringState {
        case .idle:  return DS.lavender
        case .junk:  return DS.warning
        case .clean: return DS.success
        }
    }

    private var glowColor: Color {
        switch ringState {
        case .idle:  return DS.glowAccent
        case .junk:  return DS.glowJunk
        case .clean: return DS.glowSuccess
        }
    }

    private var freeGB: Double {
        scanner.getDiskInfo().1
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 6)

            // Fill arc
            Circle()
                .trim(from: 0, to: freePercent)
                .stroke(
                    strokeColor,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: glowColor, radius: 6)
                .animation(.spring(response: 0.9, dampingFraction: 0.7), value: freePercent)
                .animation(.easeInOut(duration: 0.4), value: ringState)

            // Center label
            VStack(spacing: 2) {
                Text(String(format: "%.0f", freeGB))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("GB FREE")
                    .font(.system(size: 8, weight: .semibold))
                    .kerning(0.8)
                    .foregroundStyle(DS.textTertiary)
            }
        }
        .frame(width: 88, height: 88)
    }
}

// MARK: - Disk Usage Bar
struct DiskUsageBar: View {
    let scanner: JunkScanner

    private var totalGB: Double { scanner.getDiskInfo().0 }
    private var freeGB: Double { scanner.getDiskInfo().1 }
    private var usedGB: Double { totalGB - freeGB }
    private var usedFraction: Double { totalGB > 0 ? usedGB / totalGB : 0.74 }
    private var junkFraction: Double { totalGB > 0 ? scanner.totalJunkGB / totalGB : 0 }

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Text("Disk Usage")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.textTertiary)
                Spacer()
                Text(String(format: "%.0f GB used · %.0f GB total", usedGB, totalGB))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.textTertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.bgQuaternary)
                        .frame(height: 5)

                    // Used (violet gradient)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.gradientDiskUsed)
                        .frame(width: max(0, geo.size.width * usedFraction), height: 5)
                        .animation(.spring(response: 0.8), value: usedFraction)

                    // Junk overlay (orange)
                    if junkFraction > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DS.gradientJunk)
                            .frame(
                                width: max(0, geo.size.width * junkFraction),
                                height: 5
                            )
                            .offset(x: max(0, geo.size.width * (usedFraction - junkFraction)))
                            .animation(.spring(response: 0.8), value: junkFraction)
                    }
                }
            }
            .frame(height: 5)
        }
    }
}
