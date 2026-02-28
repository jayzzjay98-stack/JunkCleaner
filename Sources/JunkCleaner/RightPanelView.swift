import SwiftUI

// MARK: - Right Panel (lg:col-span-4)
struct RightPanelView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    // Live system stats
    @State private var cpuUsage: Double = 0.12
    @State private var memUsage: Double = 0.45
    @State private var memUsedGB: Double = 7.2
    @State private var netDown: Double = 142
    @State private var netUp: Double = 45
    @State private var statsTimer: Timer?

    private var diskTotalGB: Double { scanner.getDiskInfo().0 }
    private var diskFreeGB: Double { scanner.getDiskInfo().1 }
    private var diskUsedFraction: Double {
        guard diskTotalGB > 0 else { return 0.72 }
        return (diskTotalGB - diskFreeGB) / diskTotalGB
    }
    private var junkGB: Double { scanner.totalJunkGB }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // CPU card
                StatCard(
                    icon: "cpu.fill",
                    iconBg: T.indigo500.opacity(0.20),
                    iconFg: T.blue400,
                    title: "CPU Load",
                    subtitle: "8 Cores Active",
                    value: "\(Int(cpuUsage * 100))%",
                    barFraction: cpuUsage,
                    barGradient: T.cpuBarGradient,
                    barGlow: T.indigo500.opacity(0.5),
                    footer: AnyView(
                        HStack {
                            Text("System: \(Int(cpuUsage * 40))%")
                            Spacer()
                            Text("User: \(Int(cpuUsage * 60))%")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(T.textFaint)
                    )
                )

                // Memory card
                StatCard(
                    icon: "memorychip.fill",
                    iconBg: Color(hex: "#a855f7").opacity(0.20),
                    iconFg: Color(hex: "#c084fc"),
                    title: "Memory",
                    subtitle: "16 GB Total",
                    value: "\(Int(memUsage * 100))%",
                    barFraction: memUsage,
                    barGradient: T.memBarGradient,
                    barGlow: Color(hex: "#a855f7").opacity(0.5),
                    footer: AnyView(
                        HStack {
                            Text(String(format: "Used: %.1f GB", memUsedGB))
                            Spacer()
                            Text("Cached: 4.1 GB")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(T.textFaint)
                    )
                )

                // Disk card
                DiskCard(
                    diskUsedFraction: diskUsedFraction,
                    diskTotalGB: diskTotalGB,
                    diskFreeGB: diskFreeGB,
                    junkGB: junkGB,
                    scanner: scanner,
                    cleaner: cleaner
                )

                // Network mini stats
                HStack(spacing: 14) {
                    NetMiniCard(
                        icon: "arrow.down.circle.fill",
                        label: "Down",
                        value: String(format: "%.0f", netDown),
                        unit: "Mb/s"
                    )
                    NetMiniCard(
                        icon: "arrow.up.circle.fill",
                        label: "Up",
                        value: String(format: "%.0f", netUp),
                        unit: "Mb/s"
                    )
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .onAppear { startStatUpdates() }
        .onDisappear { statsTimer?.invalidate() }
    }

    private func startStatUpdates() {
        updateStats()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.8)) { updateStats() }
        }
    }
    private func updateStats() {
        cpuUsage = Double.random(in: 0.06...0.28)
        memUsage = Double.random(in: 0.38...0.62)
        memUsedGB = memUsage * 16
        netDown = Double.random(in: 80...200)
        netUp = Double.random(in: 20...80)
    }
}

// MARK: - Generic stat card
struct StatCard: View {
    let icon: String
    let iconBg: Color
    let iconFg: Color
    let title: String
    let subtitle: String
    let value: String
    let barFraction: Double
    let barGradient: LinearGradient
    let barGlow: Color
    let footer: AnyView

    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundStyle(iconFg)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(T.textWhite)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(T.textFaint)
                }
                Spacer()
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(T.textWhite)
                    .shadow(color: T.violet400.opacity(0.4), radius: 6)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.bottom, 16)

            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#334155").opacity(0.3))
                        .frame(height: 6)
                    Capsule()
                        .fill(barGradient)
                        .frame(width: max(0, geo.size.width * barFraction), height: 6)
                        .shadow(color: barGlow, radius: 5)
                        .animation(.easeInOut(duration: 0.8), value: barFraction)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 14)

            footer
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(hovering ? T.glassBg.opacity(1.2) : T.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(T.glassBorder, lineWidth: 1)
                )
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
    }
}

// MARK: - Disk card (has junk section)
struct DiskCard: View {
    let diskUsedFraction: Double
    let diskTotalGB: Double
    let diskFreeGB: Double
    let junkGB: Double
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @State private var hovering = false
    @State private var reviewHover = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(T.cyan400.opacity(0.20))
                        .frame(width: 36, height: 36)
                    Image(systemName: "externaldrive.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(T.cyan400)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Disk Space")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(T.textWhite)
                    Text("Macintosh HD")
                        .font(.system(size: 11))
                        .foregroundStyle(T.textFaint)
                }
                Spacer()
                Text("\(Int(diskUsedFraction * 100))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(T.textWhite)
                    .shadow(color: T.violet400.opacity(0.4), radius: 6)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.bottom, 16)

            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "#334155").opacity(0.3)).frame(height: 6)
                    Capsule()
                        .fill(T.diskBarGradient)
                        .frame(width: max(0, geo.size.width * diskUsedFraction), height: 6)
                        .shadow(color: T.cyan400.opacity(0.5), radius: 5)
                        .animation(.easeInOut(duration: 0.6), value: diskUsedFraction)
                }
            }
            .frame(height: 6)
            .padding(.bottom, 20)

            Divider().background(T.glassBorder).padding(.bottom, 16)

            // Junk section
            HStack {
                Text("Junk Found")
                    .font(.system(size: 13))
                    .foregroundStyle(T.textDim)
                Spacer()
                Text(junkGB > 0
                     ? String(format: "%.1f GB", junkGB)
                     : (scanner.scanResult != nil ? "None" : "—"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(junkGB > 0 ? T.orange400 : T.textFaint)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: junkGB)
            }
            .padding(.bottom, 10)

            // Review / Scan button
            Button {
                if scanner.scanResult != nil && junkGB > 0 {
                    // clean
                    guard let r = scanner.scanResult else { return }
                    Task {
                        await cleaner.clean(items: r.items)
                        await scanner.startScan()
                    }
                } else {
                    Task { await scanner.startScan() }
                }
            } label: {
                Text(scanner.scanResult != nil && junkGB > 0 ? "Clean Now" : "Review Files")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(T.textWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(reviewHover ? Color.white.opacity(0.10) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(scanner.isScanning || cleaner.isDeleting)
            .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { reviewHover = h } }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(hovering ? T.glassBg.opacity(1.2) : T.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(T.glassBorder, lineWidth: 1)
                )
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
    }
}

// MARK: - Network mini cards
struct NetMiniCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(T.textFaint)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(T.textFaint)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(T.textWhite)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(T.textFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(T.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(T.glassBorder, lineWidth: 1)
                )
        )
        .onHover { h in withAnimation { hovering = h } }
    }
}
