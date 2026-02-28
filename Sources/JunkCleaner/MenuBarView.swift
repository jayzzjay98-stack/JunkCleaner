import SwiftUI

struct MenuBarView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner

    @AppStorage("selectedTheme") private var selectedTheme: Int = 0
    private var theme: AppTheme { appThemes[selectedTheme] }
    
    @State private var scrollOffset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            mainDisplay
            statsGrid
            dividerLine("JUNK")
            junkListSection
            actionButtons
            themeSection
            footerSection
        }
        .frame(width: 280)
        .background(theme.bgColor)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Spacer()
            Image(systemName: "trash")
                .font(.system(size: 17))
                .foregroundStyle(theme.accent)
            Text("JunkCleaner · \(chipName)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
        }
    }

    // MARK: - Main Display
    private var mainDisplay: some View {
        let (totalGB, freeGB) = scanner.getDiskInfo()
        let diskUsedPercent = totalGB > 0 ? Int(((totalGB - freeGB) / totalGB) * 100) : 0
        let itemsCount = scanner.scanResult?.items.count ?? 0

        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("JUNK FILES")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(0.8)
                    .padding(.bottom, 4)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", scanner.totalJunkGB))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                        .shadow(color: theme.accent.opacity(0.25), radius: 10)
                        .monospacedDigit()
                    Text("GB")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.accent)
                }
                
                Text(scanner.isScanning ? "Scanning..." : (scanner.scanResult != nil ? "\(itemsCount) items found" : "Ready to scan"))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 2)
                    .lineLimit(1)
                    .truncationMode(.tail)

                segmentBar(percent: diskUsedPercent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            Spacer()
            miniRing(freeGB: freeGB, totalGB: totalGB)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private func segmentBar(percent: Int) -> some View {
        GeometryReader { geometry in
            let total = max(8, Int(geometry.size.width / 12))
            let filled = Int(Double(percent) / 100.0 * Double(total))
            
            HStack(spacing: 1.5) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            i < filled ? theme.accent :
                            i == filled ? theme.accent.opacity(0.35) :
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
        return CGFloat(14.0 - abs(Double(i) - mid) * 0.8)
    }

    private func miniRing(freeGB: Double, totalGB: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 6)
                .frame(width: 68, height: 68)

            let freePercent = totalGB > 0 ? (freeGB / totalGB) : 0.0
            Circle()
                .trim(from: 0, to: freePercent)
                .stroke(theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
                .frame(width: 68, height: 68)
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.accent.opacity(0.25), radius: 4)

            VStack(spacing: 1) {
                Text(String(format: "%.0f", freeGB))
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("FREE")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        let lastScanText: String
        if scanner.scanResult != nil {
            lastScanText = "Done"
        } else {
            lastScanText = "Never"
        }

        return HStack(spacing: 4) {
            statBox(label: "STATUS", value: scanner.isScanning ? "Scanning" : (scanner.scanResult != nil ? "Done" : "Ready"), isOk: !scanner.isScanning)
            statBox(label: "ITEMS", value: "\(scanner.scanResult?.items.count ?? 0)", isOk: false)
            statBox(label: "LAST SCAN", value: lastScanText, isOk: false)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
    
    private func statBox(label: String, value: String, isOk: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(0.5)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isOk ? Color(red: 0.29, green: 0.87, blue: 0.5) : .white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
        )
    }

    private func dividerLine(_ label: String) -> some View {
        ZStack {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(1)
                .padding(.horizontal, 8)
                .background(theme.bgColor)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    // MARK: - Junk List
    private var junkListSection: some View {
        VStack(spacing: 0) {
            if scanner.isScanning {
                VStack(spacing: 6) {
                    ProgressView(value: scanner.scanProgress)
                        .progressViewStyle(.linear)
                        .tint(theme.accent)
                    Text(scanner.currentScanTask)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 8)
                
            } else if let result = scanner.scanResult, !result.items.isEmpty {
                // Grouping items to show top categories
                let itemsList = result.items.sorted { $0.sizeBytes > $1.sizeBytes }.prefix(7)
                let maxSize = itemsList.first?.sizeBytes ?? 1
                
                ForEach(Array(itemsList.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 6) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.accent.opacity(0.5))
                            .frame(width: 14)

                        Text(item.displayName)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1).truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 1.5).fill(Color.white.opacity(0.06)).frame(width: 40, height: 2.5)
                            RoundedRectangle(cornerRadius: 1.5).fill(theme.accent.opacity(0.7))
                                .frame(width: max(2, 40 * Double(item.sizeBytes) / Double(maxSize)), height: 2.5)
                        }

                        Text(item.formattedSize)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 56, alignment: .trailing)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 8)
                
            } else if scanner.scanResult != nil && scanner.scanResult!.items.isEmpty {
                 Text("No junk files found")
                     .font(.system(size: 12, design: .monospaced))
                     .foregroundStyle(.white.opacity(0.2))
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 16)
            } else {
                 Text("Press Scan to find junk files")
                     .font(.system(size: 12, design: .monospaced))
                     .foregroundStyle(.white.opacity(0.2))
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 6) {
            // Show status message if any
            if let result = cleaner.lastResult {
                Text("✅ Freed \(String(format: "%.2f GB", result.freedGB)) · \(result.deletedCount) items deleted")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.29, green: 0.87, blue: 0.5))
                    .lineLimit(1)
            } else if let error = scanner.lastError {
                 Text("❌ \(error)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                    .lineLimit(1)
            }
            
            HStack(spacing: 6) {
                if cleaner.isDeleting {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small).tint(theme.accent)
                        Text(cleaner.currentDeleteTask)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.accent)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity).frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(theme.accentDim)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.borderColor, lineWidth: 0.5))
                    )
                } else {
                    cleanButton(icon: "◎", label: "Scan") {
                        Task { await scanner.startScan() }
                    }
                    .keyboardShortcut("s", modifiers: [.command])

                    cleanButton(icon: "🗑", label: "Clean All") {
                        guard let result = scanner.scanResult else { return }
                        Task {
                            await cleaner.clean(items: result.items.filter { $0.isSelected })
                        }
                    }
                    .disabled(scanner.scanResult == nil || scanner.scanResult!.items.isEmpty || scanner.isScanning)
                    .keyboardShortcut("c", modifiers: [.command])
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private func cleanButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 17)).foregroundStyle(theme.accent)
                Text(label).font(.system(size: 13, weight: .bold)).foregroundStyle(.white.opacity(0.9))
            }
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity).frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(theme.accentDim)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.borderColor, lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Theme Section
    private var themeSection: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)

            VStack(spacing: 8) {
                GeometryReader { geo in
                    let itemWidth: CGFloat = 46
                    let totalWidth = itemWidth * CGFloat(appThemes.count) + 24
                    let maxOffset = max(0, totalWidth - geo.size.width)

                    HStack(spacing: 5) {
                        ForEach(Array(appThemes.enumerated()), id: \.offset) { i, t in
                            themePreset(t, index: i)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .offset(x: -scrollOffset)
                    .background(Color.black.opacity(0.001))
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .global)
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
                                dragStartOffset = scrollOffset
                                
                                let predictedOffset = dragStartOffset - value.predictedEndTranslation.width
                                let targetOffset = min(max(predictedOffset, 0), maxOffset)
                                
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    scrollOffset = targetOffset
                                }
                                dragStartOffset = scrollOffset
                            }
                    )
                }
                .frame(height: 38)
            }
            .padding(.vertical, 10)
        }
    }

    private func themePreset(_ t: AppTheme, index: Int) -> some View {
        let isActive = index == selectedTheme

        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(isActive ? 0.08 : 0.04))
                .frame(width: 36, height: 36)

            Circle()
                .fill(t.accent)
                .frame(width: isActive ? 18 : 15, height: isActive ? 18 : 15)
                .shadow(color: t.accent.opacity(isActive ? 0.7 : 0.3),
                        radius: isActive ? 6 : 3)

            if isActive {
                Circle()
                    .fill(t.accent)
                    .frame(width: 4, height: 4)
                    .offset(x: 12, y: 12)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? t.accent : Color.clear, lineWidth: 1.5)
                .shadow(color: isActive ? t.accent.opacity(0.5) : .clear, radius: 4)
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTheme = index }
        }
    }

    // MARK: - Footer
    private var footerSection: some View {
        HStack {
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 4) {
                    Text("⏻").font(.system(size: 11))
                    Text("Quit").font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: [.command])

            Spacer()

            Text("AUTO SCAN OFF · v1.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 0.5)
        }
    }

    // Helpers
    private var chipName: String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
        let name = String(cString: machine)
        if name.contains("M1") { return "M1" }
        if name.contains("M2") { return "M2" }
        if name.contains("M3") { return "M3" }
        if name.contains("M4") { return "M4" }
        if name.contains("M5") { return "M5" }
        return "Mac"
    }
}
