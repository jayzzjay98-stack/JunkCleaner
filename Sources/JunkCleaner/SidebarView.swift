import SwiftUI
import AppKit

// MARK: - Sidebar  (w-24 md:w-64 in HTML)
struct SidebarView: View {
    @State private var active: SideTab = .dashboard

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Logo (p-8) ──────────────────────────────────────────────
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(T.primaryGradient)
                        .frame(width: 32, height: 32)
                        .shadow(color: T.violet400.opacity(0.5), radius: 8)
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("NeoClean")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(T.textWhite)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 28)

            // ── Nav (flex-1, gap-2, py-8) ───────────────────────────────
            VStack(spacing: 4) {
                ForEach(SideTab.navItems) { tab in
                    SideNavRow(tab: tab, isActive: active == tab) {
                        active = tab
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // ── Bottom nav ──────────────────────────────────────────────
            Divider()
                .background(T.glassBorder)
                .padding(.horizontal, 16)

            SideNavRow(tab: .settings, isActive: active == .settings) {
                active = .settings
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 240)
        .background(
            T.glassSurface.opacity(0.3)
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(T.glassBorder)
                .frame(width: 1)
        }
    }
}

// MARK: - Tab definition
enum SideTab: String, CaseIterable, Identifiable {
    case dashboard   = "Dashboard"
    case optimizer   = "Optimization"
    case protection  = "Protection"
    case cleaner     = "Cleaner"
    case settings    = "Settings"

    var id: String { rawValue }

    static var navItems: [SideTab] { [.dashboard, .optimizer, .protection, .cleaner] }

    var icon: String {
        switch self {
        case .dashboard:  return "square.grid.2x2.fill"
        case .optimizer:  return "rocket.fill"
        case .protection: return "shield.fill"
        case .cleaner:    return "folder.badge.minus"
        case .settings:   return "gearshape.fill"
        }
    }
}

// MARK: - Nav row
struct SideNavRow: View {
    let tab: SideTab
    let isActive: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .medium))
                    .scaleEffect(hovering ? 1.10 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: hovering)
                    .frame(width: 22)
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .foregroundStyle(isActive ? T.textWhite : T.slate300.opacity(hovering ? 1 : 0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isActive
                        ? T.primary.opacity(0.20)
                        : (hovering ? T.glassHover : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isActive ? T.primary.opacity(0.30) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: isActive ? T.violet400.opacity(0.3) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.12)) { hovering = h } }
    }
}
