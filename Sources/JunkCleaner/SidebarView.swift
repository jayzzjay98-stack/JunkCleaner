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
            .padding(.leading, 22)
            .padding(.top, 22)
            .padding(.bottom, 22)

            // ── Logo ─────────────────────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#667eea"), Color(hex: "#764ba2"), Color(hex: "#a78bfa")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .shadow(color: Color(hex: "#667eea").opacity(0.4), radius: 8)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("NeoClean")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)

            // ── Nav: Junk Cleaner only ────────────────────────────────────
            VStack(spacing: 4) {
                AppTabRow(tab: .cleaner, isActive: activeTab == .cleaner) {
                    activeTab = .cleaner
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // ── Settings at bottom ────────────────────────────────────────
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            AppTabRow(tab: .settings, isActive: activeTab == .settings) {
                activeTab = .settings
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 18)
        }
        .frame(width: 220)
        .background(Color(hex: "#12121c"))
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
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 22)
                    .foregroundStyle(isActive ? .white : Color.white.opacity(hovering ? 0.8 : 0.45))
                Text(tab.rawValue)
                    .font(.system(size: 13.5, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(isActive ? .white : Color.white.opacity(hovering ? 0.8 : 0.45))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        isActive
                        ? Color(hex: "#667eea").opacity(0.20)
                        : (hovering ? Color.white.opacity(0.04) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .strokeBorder(
                                isActive ? Color(hex: "#667eea").opacity(0.35) : Color.clear,
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
            .scaleEffect(hovering ? 1.15 : 1.0)
            .brightness(hovering ? 0.1 : 0)
            .animation(.easeInOut(duration: 0.1), value: hovering)
            .onHover { h in hovering = h }
            .onTapGesture { action() }
    }
}
