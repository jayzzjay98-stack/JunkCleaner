import SwiftUI
import UserNotifications

struct ContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @AppStorage("selectedTheme") private var selectedTheme: Int = 0
    private var theme: AppTheme { appThemes[selectedTheme] }

    @State private var showResult: Bool = false
    @State private var resultTimer: Timer? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    var body: some View {
        ZStack {
            // Background
            theme.bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                titleBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        mainDisplay
                        statsGrid
                        sectionDivider("JUNK FILES")
                        junkListSection
                        sectionDivider("THEMES")
                        themeSection
                    }
                    .padding(.bottom, 12)
                }
                actionBar
            }
        }
        .frame(minWidth: 360, minHeight: 600)
        .onChange(of: cleaner.isDeleting) { _, isDeleting in
            if !isDeleting, cleaner.lastResult != nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showResult = true
                }
                resultTimer?.invalidate()
                resultTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.4)) { showResult = false }
                    }
                }
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    // MARK: - Title Bar (draggable)
    private var titleBar: some View {
        HStack(spacing: 10) {
            // Traffic lights area
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 1, green: 0.37, blue: 0.34))
                    .frame(width: 12, height: 12)
                    .onTapGesture { NSApplication.shared.terminate(nil) }
                Circle()
                    .fill(Color(red: 1, green: 0.73, blue: 0.25))
                    .frame(width: 12, height: 12)
                    .onTapGesture {
                        NSApplication.shared.keyWindow?.miniaturize(nil)
                    }
                Circle()
                    .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                    .frame(width: 12, height: 12)
                    .onTapGesture {
                        NSApplication.shared.keyWindow?.zoom(nil)
                    }
            }
            .padding(.leading, 14)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Text("JunkCleaner")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                Text("·")
                    .foregroundStyle(.white.opacity(0.3))
                Text(chipName)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            // Disk free info
            let (_, freeGB) = scanner.getDiskInfo()
            Text(String(format: "%.0f GB free", freeGB))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.trailing, 14)
        }
        .frame(height: 44)
        .background(theme.bgColor)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    NSApplication.shared.keyWindow?.performDrag(with: NSApp.currentEvent!)
                }
        )
        .onTapGesture(count: 2) {
            NSApplication.shared.keyWindow?.zoom(nil)
        }
    }

    // MARK: - Main Display
    private var mainDisplay: some View {
        let (totalGB, freeGB) = scanner.getDiskInfo()
        let diskUsedPercent = totalGB > 0 ? Int(((totalGB - freeGB) / totalGB) * 100) : 0
        let itemsCount = scanner.scanResult?.items.count ?? 0

        return HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text("JUNK FILES")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .tracking(1.5)
                    .padding(.bottom, 6)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.1f", scanner.totalJunkGB))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                        .shadow(color: theme.accent.opacity(0.3), radius: 12)
                        .monospacedDigit()
                    Text("GB")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.accent.opacity(0.8))
                        .padding(.bottom, 6)
                }

                Text(scanner.isScanning
                     ? scanner.currentScanTask
                     : (scanner.scanResult != nil ? "\(itemsCount) items found" : "Ready to scan"))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 2)
                    .lineLimit(1)

                segmentBar(percent: diskUsedPercent)
                    .padding(.top, 10)
            }

            Spacer()

            miniRing(freeGB: freeGB, totalGB: totalGB)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private func segmentBar(percent: Int) -> some View {
        GeometryReader { geometry in
            let total = max(10, Int(geometry.size.width / 10))
            let filled = Int(Double(percent) / 100.0 * Double(total))
            HStack(spacing: 2) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            i < filled ? theme.accent :
                            i == filled ? theme.accent.opacity(0.3) :
                            Color.white.opacity(0.05)
                        )
                        .frame(height: segmentHeight(i, total: total))
                }
            }
        }
        .frame(height: 14)
    }

    private func segmentHeight(_ i: Int, total: Int) -> CGFloat {
        let mid = Double(total) / 2.0
        return CGFloat(14.0 - abs(Double(i) - mid) * 0.6)
    }

    private func miniRing(freeGB: Double, totalGB: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 7)
                .frame(width: 80, height: 80)
            let freePercent = totalGB > 0 ? (freeGB / totalGB) : 0.0
            Circle()
                .trim(from: 0, to: freePercent)
                .stroke(theme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .butt))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.accent.opacity(0.3), radius: 5)
            VStack(spacing: 1) {
                Text(String(format: "%.0f", freeGB))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("FREE")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(0.5)
            }
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        HStack(spacing: 6) {
            statBox(label: "STATUS",
                    value: scanner.isScanning ? "Scanning" : (scanner.scanResult != nil ? "Done" : "Ready"),
                    highlight: !scanner.isScanning && scanner.scanResult != nil)
            statBox(label: "ITEMS",
                    value: "\(scanner.scanResult?.items.count ?? 0)",
                    highlight: false)
            statBox(label: "TOTAL SIZE",
                    value: scanner.totalJunkGB >= 1.0
                        ? String(format: "%.1f GB", scanner.totalJunkGB)
                        : String(format: "%.0f MB", scanner.totalJunkGB * 1024),
                    highlight: scanner.totalJunkGB > 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private func statBox(label: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(highlight ? theme.accent : .white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5))
        )
    }

    private func sectionDivider(_ label: String) -> some View {
        ZStack {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)
                .padding(.horizontal, 10)
                .background(theme.bgColor)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Junk List
    private var junkListSection: some View {
        VStack(spacing: 0) {
            if scanner.isScanning {
                VStack(spacing: 8) {
                    ProgressView(value: scanner.scanProgress)
                        .progressViewStyle(.linear)
                        .tint(theme.accent)
                    Text(scanner.currentScanTask)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            } else if let result = scanner.scanResult, !result.items.isEmpty {
                let itemsList = result.items.sorted { $0.sizeBytes > $1.sizeBytes }
                let maxSize = itemsList.first?.sizeBytes ?? 1

                ForEach(Array(itemsList.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 10) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.accent.opacity(0.4))
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(1)
                            Text(item.type.rawValue)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.35))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 50, height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.accent.opacity(0.7))
                                .frame(width: max(3, 50 * Double(item.sizeBytes) / Double(maxSize)), height: 3)
                        }

                        Text(item.formattedSize)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(width: 62, alignment: .trailing)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 20)
                    .background(index % 2 == 0 ? Color.clear : Color.white.opacity(0.01))
                }
                .padding(.bottom, 10)

            } else if scanner.scanResult != nil {
                Text("No junk files found  🎉")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.1))
                    Text("Press Scan to find junk files")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
    }

    // MARK: - Theme Section
    private var themeSection: some View {
        GeometryReader { geo in
            let itemWidth: CGFloat = 44
            let totalWidth = itemWidth * CGFloat(appThemes.count) + 40
            let maxOffset = max(0, totalWidth - geo.size.width)

            HStack(spacing: 5) {
                ForEach(Array(appThemes.enumerated()), id: \.offset) { i, t in
                    themePreset(t, index: i)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .offset(x: -scrollOffset)
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartOffset = scrollOffset
                        }
                        let newOffset = dragStartOffset - value.translation.width
                        scrollOffset = min(max(newOffset, 0), maxOffset)
                    }
                    .onEnded { value in
                        isDragging = false
                        let predictedOffset = dragStartOffset - value.predictedEndTranslation.width
                        let targetOffset = min(max(predictedOffset, 0), maxOffset)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            scrollOffset = targetOffset
                        }
                        dragStartOffset = scrollOffset
                    }
            )
        }
        .frame(height: 60)
        .clipped()
    }

    private func themePreset(_ t: AppTheme, index: Int) -> some View {
        let isActive = index == selectedTheme
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(isActive ? 0.08 : 0.03))
                .frame(width: 36, height: 36)
            Circle()
                .fill(t.accent)
                .frame(width: isActive ? 18 : 14, height: isActive ? 18 : 14)
                .shadow(color: t.accent.opacity(isActive ? 0.8 : 0.3), radius: isActive ? 8 : 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? t.accent : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isActive ? 1.08 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTheme = index }
        }
    }

    // MARK: - Action Bar (bottom)
    private var actionBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)

            VStack(spacing: 8) {
                // Result banner
                if showResult, let result = cleaner.lastResult {
                    HStack(spacing: 12) {
                        Text("✅")
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cleaned \(result.formattedFreed)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(red: 0.29, green: 0.87, blue: 0.5))
                            Text("\(result.deletedCount) files deleted" +
                                 (result.failedCount > 0 ? " · ⚠️ \(result.failedCount) failed" : ""))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Button {
                            withAnimation { showResult = false }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.29, green: 0.87, blue: 0.5).opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.29, green: 0.87, blue: 0.5).opacity(0.25), lineWidth: 0.5))
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if let error = scanner.lastError {
                    Text("❌ \(error)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.35))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Main buttons
                if cleaner.isDeleting {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small).tint(theme.accent)
                        Text(cleaner.currentDeleteTask)
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(theme.accent)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 46)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.accentDim)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(theme.borderColor, lineWidth: 0.5))
                    )
                } else {
                    HStack(spacing: 8) {
                        actionButton(icon: "magnifyingglass", label: "Scan", isPrimary: false) {
                            Task { await scanner.startScan() }
                        }
                        .keyboardShortcut("s", modifiers: [.command])

                        actionButton(icon: "trash.fill", label: "Clean All", isPrimary: true) {
                            guard let result = scanner.scanResult,
                                  !result.items.isEmpty else { return }
                            Task {
                                await cleaner.clean(items: result.items.filter { $0.isSelected })
                                // After clean, rescan to update the list
                                await scanner.startScan()
                            }
                        }
                        .disabled(scanner.scanResult == nil ||
                                  scanner.scanResult!.items.isEmpty ||
                                  scanner.isScanning)
                        .keyboardShortcut("c", modifiers: [.command])
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.bgColor)
        }
    }

    private func actionButton(icon: String, label: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(isPrimary ? theme.bgColor : theme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isPrimary ? theme.accent : theme.accentDim)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(isPrimary ? Color.clear : theme.borderColor, lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private var chipName: String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        let name = String(cString: machine)
        for chip in ["M1", "M2", "M3", "M4", "M5"] {
            if name.contains(chip) { return chip }
        }
        return "Mac"
    }
}
