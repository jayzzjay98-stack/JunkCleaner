import SwiftUI

struct ScanResultView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    let theme: AppTheme

    @State private var expandedGroups = Set<CategoryGroup>()
    @State private var showOnlySafe = false

    var body: some View {
        VStack(spacing: 0) {
            // toolbar
            HStack(spacing: 8) {
                Toggle("Safe only", isOn: $showOnlySafe)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(theme.accent)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                if let result = scanner.scanResult {
                    let selectedCount = result.items.filter { $0.isSelected }.count
                    Text("\(selectedCount) selected")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))

                    Button("All") { selectAll(result: result, select: true) }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.accent)
                    Button("None") { selectAll(result: result, select: false) }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5) }

            if scanner.isScanning {
                VStack(spacing: 8) {
                    Spacer()
                    ProgressView(value: scanner.scanProgress)
                        .progressViewStyle(.linear)
                        .tint(theme.accent)
                        .frame(width: 200)
                    Text(scanner.currentScanTask)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                }
            } else if let result = scanner.scanResult {
                if result.items.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("Your Mac is clean!")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                } else {
                    // grouped list
                    let displayItems = showOnlySafe ? result.items.filter { $0.type.riskLevel == .safe } : result.items
                    let byGroup = Dictionary(grouping: displayItems) { $0.type.category }

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(CategoryGroup.allCases) { group in
                                if let items = byGroup[group], !items.isEmpty {
                                    groupSection(group: group, items: items, scanResult: scanner.scanResult!)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("Run a scan first")
                        .foregroundStyle(.white.opacity(0.4))
                        .font(.system(size: 13))
                    Spacer()
                }
            }

            // Clean button
            if let result = scanner.scanResult, !result.items.isEmpty {
                Divider().overlay(Color.white.opacity(0.06))
                HStack {
                    let selected = result.items.filter { $0.isSelected }
                    let selectedSize = selected.reduce(0) { $0 + $1.sizeBytes }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(selected.count) items selected")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(formatSize(selectedSize))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(theme.accent)
                    }
                    Spacer()

                    if cleaner.isDeleting {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small).tint(theme.accent)
                            Text(cleaner.currentDeleteTask)
                                .font(.system(size: 11))
                                .foregroundStyle(theme.accent)
                        }
                    } else {
                        Button("Clean Selected") {
                            Task { await cleaner.clean(items: selected) }
                        }
                        .buttonStyle(JunkButtonStyle(theme: theme))
                        .disabled(selected.isEmpty)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }

    private func groupSection(group: CategoryGroup, items: [JunkItem], scanResult: ScanResult) -> some View {
        let groupSize = items.reduce(0) { $0 + $1.sizeBytes }
        let isExpanded = expandedGroups.contains(group)

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expandedGroups.remove(group) } else { expandedGroups.insert(group) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: items.first?.type.icon ?? "folder")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.accent)
                        .frame(width: 18)
                    Text(group.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("\(items.count) items")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(formatSize(groupSize))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.accent)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.03))
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(items) { item in
                    itemRow(item: item, scanResult: scanResult)
                }
            }

            Divider().overlay(Color.white.opacity(0.05))
        }
    }

    private func itemRow(item: JunkItem, scanResult: ScanResult) -> some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: {
                    scanResult.items.first(where: { $0.id == item.id })?.isSelected ?? false
                },
                set: { newVal in
                    if let idx = scanner.scanResult?.items.firstIndex(where: { $0.id == item.id }) {
                        scanner.scanResult?.items[idx].isSelected = newVal
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                Text(item.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()

            riskDot(item.type.riskLevel)

            Text(item.formattedSize)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 58, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.01))
    }

    private func riskDot(_ risk: RiskLevel) -> some View {
        Circle()
            .fill(risk == .safe ? Color.green : risk == .caution ? Color.yellow : Color.red)
            .frame(width: 6, height: 6)
    }

    private func selectAll(result: ScanResult, select: Bool) {
        for i in scanner.scanResult!.items.indices {
            scanner.scanResult?.items[i].isSelected = select
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        let mb = Double(bytes) / 1_048_576.0
        if gb >= 1.0 { return String(format: "%.2f GB", gb) }
        if mb >= 1.0 { return String(format: "%.0f MB", mb) }
        return String(format: "%d KB", bytes / 1024)
    }
}

// MARK: - App Uninstaller View
struct AppUninstallerView: View {
    @Bindable var uninstaller: AppUninstaller
    @Bindable var cleaner: JunkCleaner
    let theme: AppTheme

    @State private var searchText = ""
    @State private var allApps: [AppUninstaller.AppInfo] = []
    @State private var selectedApp: AppUninstaller.AppInfo?
    @State private var showConfirm = false

    var filteredApps: [AppUninstaller.AppInfo] {
        searchText.isEmpty ? allApps : allApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.4))
                    .font(.system(size: 12))
                TextField("Search apps...", text: $searchText)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.borderColor, lineWidth: 0.5)))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            if let target = uninstaller.targetApp {
                // Analysis result
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(target.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text("v\(target.version) · \(target.bundleID)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                            if uninstaller.isAnalyzing {
                                Text("Scanning...")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.accent)
                            } else {
                                Text(uninstaller.analysisSummary)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(red: 0.3, green: 0.9, blue: 0.5))
                            }
                        }
                        Spacer()
                        Button("← Back") { uninstaller.targetApp = nil; uninstaller.foundItems = [] }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.04))

                    if uninstaller.isAnalyzing {
                        ProgressView(value: uninstaller.analysisProgress)
                            .progressViewStyle(.linear)
                            .tint(theme.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 4)
                    }

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(uninstaller.foundItems) { item in
                                HStack(spacing: 8) {
                                    Image(systemName: item.type.icon)
                                        .foregroundStyle(theme.accent)
                                        .frame(width: 16)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.displayName)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(.white.opacity(0.9))
                                            .lineLimit(1)
                                        Text(item.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.3))
                                            .lineLimit(1).truncationMode(.middle)
                                    }
                                    Spacer()
                                    Text(item.formattedSize)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                Divider().overlay(Color.white.opacity(0.04)).padding(.horizontal, 14)
                            }
                        }
                    }

                    if !uninstaller.foundItems.isEmpty {
                        Divider().overlay(Color.white.opacity(0.06))
                        HStack {
                            Text("\(uninstaller.foundItems.count) leftover files found")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                            Spacer()
                            Button("Deep Uninstall") { showConfirm = true }
                                .buttonStyle(JunkButtonStyle(theme: theme))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                }
                .alert("Deep Uninstall \(target.name)?", isPresented: $showConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Uninstall", role: .destructive) {
                        Task {
                            try? await uninstaller.deepUninstall(app: target, items: uninstaller.foundItems)
                            uninstaller.targetApp = nil
                            uninstaller.foundItems = []
                        }
                    }
                } message: {
                    Text("This will move \(target.name).app and all \(uninstaller.foundItems.count) leftover files to Trash. This cannot be undone easily.")
                }

            } else {
                // App list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredApps) { app in
                            HStack(spacing: 10) {
                                Image(systemName: "app")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(width: 32, height: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.9))
                                    Text("v\(app.version)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                Spacer()
                                Text(formatSize(app.sizeBytes))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.5))
                                Button("Analyze") {
                                    uninstaller.targetApp = nil
                                    Task { await uninstaller.analyzeApp(at: app.path) }
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 5).fill(theme.accentDim))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            Divider().overlay(Color.white.opacity(0.04)).padding(.horizontal, 14)
                        }
                    }
                }
            }
        }
        .onAppear {
            if allApps.isEmpty {
                allApps = uninstaller.getAllInstalledApps()
            }
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        let mb = Double(bytes) / 1_048_576.0
        if gb >= 0.1 { return String(format: "%.1f GB", gb) }
        return String(format: "%.0f MB", mb)
    }
}
