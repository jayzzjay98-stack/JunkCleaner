import SwiftUI
import AppKit

struct MainContentView: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @Binding var showResult: Bool

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            // Content grid: 8 cols sphere + 4 cols stats
            GeometryReader { geo in
                HStack(alignment: .top, spacing: 28) {
                    // Left: sphere + scan (~66%)
                    CenterStageView(scanner: scanner, cleaner: cleaner, showResult: $showResult)
                        .frame(maxWidth: .infinity)

                    // Right: stat cards (~34%)
                    RightPanelView(scanner: scanner, cleaner: cleaner)
                        .frame(width: min(320, geo.size.width * 0.35))
                }
                .padding(28)
            }
        }
    }
}

// MARK: - Top Bar  (h-20)
struct TopBar: View {
    var body: some View {
        HStack {
            // System info
            VStack(alignment: .leading, spacing: 3) {
                Text("System Overview")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(T.textWhite)
                Text("MacBook Pro · macOS Sonoma")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(T.textDim)
            }

            Spacer()

            // Notification button
            Button {} label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(T.textWhite.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(T.glassButtonGradient)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)

            Divider()
                .background(T.glassBorder)
                .frame(height: 32)
                .padding(.horizontal, 8)

            // User info
            VStack(alignment: .trailing, spacing: 2) {
                Text("Alex's Mac")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(T.textWhite)
                Text("Pro Version")
                    .font(.system(size: 11))
                    .foregroundStyle(T.textDim)
            }

            // Avatar
            ZStack {
                Circle()
                    .fill(T.primaryGradient)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .strokeBorder(T.primary.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: T.violet400.opacity(0.4), radius: 6)
                Text("A")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Traffic lights
            HStack(spacing: 7) {
                TDot(color: Color(hex: "#ff5f57")) { NSApplication.shared.terminate(nil) }
                TDot(color: Color(hex: "#febc2e")) { NSApplication.shared.keyWindow?.miniaturize(nil) }
                TDot(color: Color(hex: "#28c840")) { NSApplication.shared.keyWindow?.zoom(nil) }
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal, 28)
        .frame(height: 72)
        .overlay(alignment: .bottom) {
            Rectangle().fill(T.glassBorder).frame(height: 1)
        }
    }
}

// Small traffic dot
struct TDot: View {
    let color: Color
    let action: () -> Void
    @State private var h = false
    var body: some View {
        Circle().fill(color).frame(width: 12, height: 12)
            .scaleEffect(h ? 1.1 : 1).brightness(h ? 0.08 : 0)
            .animation(.easeInOut(duration: 0.12), value: h)
            .onHover { v in h = v }.onTapGesture { action() }
    }
}
