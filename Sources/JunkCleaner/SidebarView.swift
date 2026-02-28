import SwiftUI
import AppKit

// MARK: - Sidebar (Cleaner + Settings only, with traffic lights)
struct AppSidebar: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @State private var activeTab: AppTab = .cleaner

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Traffic lights ────────────────────────────────────────────
            HStack(spacing: 7) {
                SidebarDot(color: Color(hex: "#ff5f57")) { NSApplication.shared.terminate(nil) }
                SidebarDot(color: Color(hex: "#febc2e")) { NSApplication.shared.keyWindow?.miniaturize(nil) }
                SidebarDot(color: Color(hex: "#28c840")) { NSApplication.shared.keyWindow?.zoom(nil) }
            }
            .padding(.leading, 18)
            .padding(.top, 18)
            .padding(.bottom, 20)

            // ── Logo ─────────────────────────────────────────────────────
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(T.accGrad)
                        .frame(width: 36, height: 36)
                        .shadow(color: T.accGlow, radius: 10, y: 3)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("JunkClean")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(T.txt1)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)

            // ── Nav Items ───────────────────────────────────────────────
            VStack(spacing: 2) {
                AppTabRow(tab: .cleaner, isActive: activeTab == .cleaner) {
                    activeTab = .cleaner
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // ── Bottom: Settings ────────────────────────────────────────
            Rectangle()
                .fill(T.borderDim)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            AppTabRow(tab: .settings, isActive: activeTab == .settings) {
                activeTab = .settings
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 16)
        }
        .frame(width: 232)
        .background(T.bgRaised)
        .overlay(alignment: .trailing) {
            Rectangle().fill(T.borderDim).frame(width: 1)
        }
    }
}

// MARK: - Tab enum
enum AppTab: String, CaseIterable {
    case cleaner  = "Junk Cleaner"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .cleaner:  return "folder.badge.minus"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Tab Row
struct AppTabRow: View {
    let tab: AppTab
    let isActive: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 22)
                    .foregroundStyle(isActive ? T.accLight : T.txt2.opacity(hovering ? 1 : 0.7))
                
                Text(tab.rawValue)
                    .font(.system(size: 13.5, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? T.txt1 : T.txt2.opacity(hovering ? 1 : 0.7))
                
                Spacer()
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        isActive
                        ? T.accDim
                        : (hovering ? Color.white.opacity(0.038) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(
                                isActive ? T.acc.opacity(0.28) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}

// MARK: - Traffic Light Dot
struct SidebarDot: View {
    let color: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .scaleEffect(hovering ? 1.1 : 1.0)
            .brightness(hovering ? 0.1 : 0)
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .onHover { h in hovering = h }
            .onTapGesture { action() }
    }
}
