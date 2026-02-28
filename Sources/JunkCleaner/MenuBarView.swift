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
            Picker("", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Scan Results").tag(1)
                Text("App Uninstaller").tag(2)
                Text("Settings").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch selectedTab {
                case 0:
                    overviewTab
                case 1:
                    ScanResultView(
                        results: .init(get: { scanner.scanResult ?? ScanResult() }, set: { _ in }), 
                        cleaningInProgress: $cleaner.isDeleting,
                        cleanAction: {
                            Task { await cleaner.clean(items: scanner.scanResult?.items ?? []) }
                        }
                    )
                case 2:
                    appUninstallTab
                case 3:
                    settingsTab
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            HStack {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray)
                Spacer()
                Text("JunkCleaner v1.0")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
        .background(theme.bgColor)
    }

    var overviewTab: some View {
        VStack {
            Spacer()
            Image(systemName: "trash.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(theme.accent)
            
            if scanner.isScanning {
                ProgressView(value: scanner.scanProgress)
                    .padding()
                Text(scanner.currentScanTask)
                    .font(.caption)
            } else {
                Text(scanner.scanResult != nil ? "Last scan found \(String(format: "%.2f", scanner.totalJunkGB)) GB" : "Ready to scan")
                    .padding()
                
                Button("Scan Now") {
                    Task { await scanner.startScan() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(theme.accent)
            }
            Spacer()
        }
    }

    var appUninstallTab: some View {
        VStack {
            List(uninstaller.getAllInstalledApps()) { app in
                HStack {
                    Text(app.name)
                    Spacer()
                    Button("Uninstall") {
                        Task { await uninstaller.analyzeApp(at: app.path) }
                    }
                }
            }
        }
    }

    var settingsTab: some View {
        Form {
            Section(header: Text("Themes")) {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(appThemes.enumerated()), id: \.offset) { i, t in
                            Circle()
                                .fill(t.accent)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: selectedTheme == i ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedTheme = i
                                }
                        }
                    }
                }
            }
        }
        .padding()
    }
}
