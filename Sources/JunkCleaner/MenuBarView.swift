import SwiftUI

struct MenuBarView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Bindable var uninstaller: AppUninstaller

    @State private var selectedTab = 0
    @AppStorage("selectedTheme") private var selectedTheme: Int = 0
    private var theme: AppTheme { appThemes[selectedTheme] }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Spacer()
                Image(systemName: "trash.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.accent)
                Text("JunkCleaner")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }
            .padding(.vertical, 11)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
            }

            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Results").tag(1)
                Text("Uninstaller").tag(2)
                Text("Settings").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // Content
            Group {
                switch selectedTab {
                case 0: overviewTab
                case 1: ScanResultView(scanner: scanner, cleaner: cleaner, theme: theme)
                case 2: AppUninstallerView(uninstaller: uninstaller, cleaner: cleaner, theme: theme)
                default: settingsTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer
            HStack {
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack(spacing: 4) {
                        Text("⏻").font(.system(size: 11))
                        Text("Quit").font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: [.command])
                Spacer()
                Text("JunkCleaner v1.0")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .overlay(alignment: .top) {
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
            }
        }
        .frame(width: 400, height: 560)
        .background(theme.bgColor)
    }

    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(spacing: 0) {
            Spacer()

            // Big icon + status
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.accentDim)
                        .frame(width: 80, height: 80)
                    Image(systemName: "trash.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(theme.accent)
                        .shadow(color: theme.accent.opacity(0.3), radius: 8)
                }

                if scanner.isScanning {
                    VStack(spacing: 8) {
                        ProgressView(value: scanner.scanProgress)
                            .progressViewStyle(.linear)
                            .tint(theme.accent)
                            .frame(width: 200)
                        Text(scanner.currentScanTask)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Button("Cancel") { scanner.cancelScan() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.8))
                } else if let result = scanner.scanResult {
                    // แสดงผลสแกน
                    VStack(spacing: 4) {
                        let gb = Double(result.totalSize) / 1_073_741_824.0
                        let mb = Double(result.totalSize) / 1_048_576.0
                        Text(gb >= 1.0 ? String(format: "%.2f GB", gb) : String(format: "%.0f MB", mb))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accent)
                            .monospacedDigit()
                        Text("of junk found")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(result.items.count) items · \(String(format: "%.1f", result.scanDuration))s")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.bottom, 4)

                    // mini stats by category
                    let byGroup = Dictionary(grouping: result.items) { $0.type.category }
                    HStack(spacing: 6) {
                        ForEach(CategoryGroup.allCases) { group in
                            if let items = byGroup[group], !items.isEmpty {
                                let size = items.reduce(0) { $0 + $1.sizeBytes }
                                miniStatBox(label: group.rawValue.components(separatedBy: " ").first ?? group.rawValue,
                                            value: formatSize(size), theme: theme)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)

                    HStack(spacing: 8) {
                        Button("Scan Again") {
                            Task { await scanner.startScan() }
                        }
                        .buttonStyle(JunkButtonStyle(theme: theme, isSecondary: true))

                        Button("Clean All") {
                            selectedTab = 1
                            let selected = result.items.filter { $0.isSelected }
                            Task { await cleaner.clean(items: selected) }
                        }
                        .buttonStyle(JunkButtonStyle(theme: theme))
                    }

                } else {
                    Text("Ready to scan your Mac")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, 4)

                    Button("Scan Now") {
                        Task { await scanner.startScan() }
                    }
                    .buttonStyle(JunkButtonStyle(theme: theme))
                    .keyboardShortcut("s", modifiers: [.command])
                }
            }

            if let result = cleaner.lastResult {
                Text("✅ Last clean freed \(result.formattedFreed) (\(result.deletedCount) items)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                    .padding(.top, 8)
            }

            Spacer()

            // Theme selector
            themeStrip
        }
    }

    // MARK: - Settings Tab
    private var settingsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("SCAN SETTINGS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                VStack(spacing: 1) {
                    ForEach(CategoryGroup.allCases) { group in
                        let types = JunkType.allCases.filter { $0.category == group }
                        DisclosureGroup {
                            ForEach(types) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                        .foregroundStyle(theme.accent)
                                        .frame(width: 18)
                                    Text(type.rawValue)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Spacer()
                                    riskBadge(type.riskLevel)
                                    Toggle("", isOn: Binding(
                                        get: { scanner.selectedTypes.contains(type) },
                                        set: { if $0 { scanner.selectedTypes.insert(type) } else { scanner.selectedTypes.remove(type) } }
                                    ))
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                                    .tint(theme.accent)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 4)
                            }
                        } label: {
                            Text(group.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                    }
                }

                Divider().overlay(Color.white.opacity(0.08))

                Text("THEME")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1)
                    .padding(.horizontal, 14)

                themeStrip.padding(.bottom, 10)
            }
        }
    }

    // MARK: - Theme strip
    private var themeStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(Array(appThemes.enumerated()), id: \.offset) { i, t in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(i == selectedTheme ? 0.1 : 0.04))
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(t.accent)
                            .frame(width: i == selectedTheme ? 16 : 13)
                            .shadow(color: t.accent.opacity(0.5), radius: i == selectedTheme ? 5 : 2)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(i == selectedTheme ? t.accent : Color.clear, lineWidth: 1.5))
                    .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { selectedTheme = i } }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers
    private func miniStatBox(label: String, value: String, theme: AppTheme) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.borderColor, lineWidth: 0.5)))
    }

    private func riskBadge(_ risk: RiskLevel) -> some View {
        Text(risk.rawValue)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(risk == .safe ? .green : risk == .caution ? .yellow : .red)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(
                (risk == .safe ? Color.green : risk == .caution ? Color.yellow : Color.red).opacity(0.12)
            ))
    }

    private func formatSize(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        let mb = Double(bytes) / 1_048_576.0
        if gb >= 1.0 { return String(format: "%.1fG", gb) }
        if mb >= 1.0 { return String(format: "%.0fM", mb) }
        return String(format: "%dK", bytes / 1024)
    }
}

// MARK: - Button Style
struct JunkButtonStyle: ButtonStyle {
    let theme: AppTheme
    var isSecondary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isSecondary ? .white.opacity(0.8) : theme.accent)
            .frame(height: 38)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSecondary ? Color.white.opacity(0.06) : theme.accentDim)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSecondary ? Color.white.opacity(0.12) : theme.borderColor, lineWidth: 0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}
