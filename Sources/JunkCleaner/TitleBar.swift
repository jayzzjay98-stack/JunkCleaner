import SwiftUI

struct TitleBar: View {
    let scanner: JunkScanner

    var body: some View {
        ZStack {
            DS.bgSecondary

            // Traffic lights left
            HStack {
                TrafficLights()
                    .padding(.leading, 16)
                Spacer()
                // Free space label right
                let (_, freeGB) = scanner.getDiskInfo()
                Text(String(format: "%.0f GB free", freeGB))
                    .font(.system(size: 11, weight: .500))
                    .foregroundStyle(DS.textTertiary)
                    .padding(.trailing, 16)
            }

            // Centered title
            HStack(spacing: 7) {
                AppLogoMark()
                Text("JunkCleaner")
                    .font(.system(size: 13, weight: .600))
                    .foregroundStyle(DS.textSecondary)
            }
        }
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DS.borderSubtle)
                .frame(height: 1)
        }
        .gesture(
            DragGesture()
                .onChanged { _ in
                    NSApplication.shared.keyWindow?.performDrag(with: NSApp.currentEvent ?? NSEvent())
                }
        )
        .onTapGesture(count: 2) {
            NSApplication.shared.keyWindow?.zoom(nil)
        }
    }
}

// MARK: - Traffic Lights
struct TrafficLights: View {
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 7) {
            TrafficDot(color: Color(hex: "#ff5f57"), glowColor: Color(hex: "#ff5f57")) {
                NSApplication.shared.terminate(nil)
            }
            TrafficDot(color: Color(hex: "#febc2e"), glowColor: Color(hex: "#febc2e")) {
                NSApplication.shared.keyWindow?.miniaturize(nil)
            }
            TrafficDot(color: Color(hex: "#28c840"), glowColor: Color(hex: "#28c840")) {
                NSApplication.shared.keyWindow?.zoom(nil)
            }
        }
    }
}

struct TrafficDot: View {
    let color: Color
    let glowColor: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .scaleEffect(hovering ? 1.1 : 1.0)
            .brightness(hovering ? 0.1 : 0)
            .animation(.easeInOut(duration: 0.12), value: hovering)
            .onHover { h in hovering = h }
            .onTapGesture { action() }
    }
}

// MARK: - App Logo Mark
struct AppLogoMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.radiusLogo)
                .fill(DS.gradientAccent)
                .frame(width: 22, height: 22)
                .shadow(color: DS.glowAccent, radius: 6, x: 0, y: 2)

            Image(systemName: "trash.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
