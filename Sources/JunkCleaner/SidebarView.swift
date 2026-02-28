import SwiftUI
import AppKit

// MARK: - Sidebar  (only Cleaner + Settings)
struct AppSidebar: View {
    @State private var activeTab: AppTab = .cleaner

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Traffic Lights (top-left, macOS style) ──────────────────
            HStack(spacing: 7) {
                SidebarTrafficDot(color: Color(hex: "#ff5f57")) { NSApplication.shared.terminate(nil) }
                SidebarTrafficDot(color: Color(hex: "#febc2e")) { NSApplication.shared.keyWindow?.miniaturize(nil) }
                SidebarTrafficDot(color: Color(hex: "#28c840")) { NSApplication.shared.keyWindow?.zoom(nil) }
            }
            .padding(.leading, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)

            // ── Logo ────────────────────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(DS.gradientAccent)
                        .frame(width: 34, height: 34)
                        .shadow(color: DS.glowAccent, radius: 8)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("NeoClean")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)

            // ── Nav Items ───────────────────────────────────────────────
            VStack(spacing: 4) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    if tab != .settings {
                        AppTabRow(tab: tab, isActive: activeTab == tab) {
                            activeTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // ── Bottom: Settings ────────────────────────────────────────
            Rectangle()
                .fill(DS.borderSubtle)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            AppTabRow(tab: .settings, isActive: activeTab == .settings) {
                activeTab = .settings
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .frame(width: 220)
        .background(DS.bgSecondary)
    }
}

// MARK: - Tab enum (only 2 items)
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
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 22)
                    .foregroundStyle(isActive ? .white : DS.textSecondary.opacity(hovering ? 1 : 0.7))
                Text(tab.rawValue)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(isActive ? .white : DS.textSecondary.opacity(hovering ? 1 : 0.7))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: DS.radiusNavItem)
                    .fill(
                        isActive
                        ? DS.violet.opacity(0.22)
                        : (hovering ? Color.white.opacity(0.04) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.radiusNavItem)
                            .strokeBorder(isActive ? DS.violet.opacity(0.35) : Color.clear, lineWidth: 1)
                    )
            )
            .shadow(color: isActive ? DS.glowAccent : .clear, radius: 6)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}

// MARK: - Traffic Dot
struct SidebarTrafficDot: View {
    let color: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .scaleEffect(hovering ? 1.15 : 1.0)
            .brightness(hovering ? 0.1 : 0)
            .animation(.easeInOut(duration: 0.12), value: hovering)
            .onHover { h in hovering = h }
            .onTapGesture { action() }
    }
}

