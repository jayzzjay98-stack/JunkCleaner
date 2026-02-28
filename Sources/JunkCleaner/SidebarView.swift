import SwiftUI
import AppKit

// MARK: - Sidebar (Cleaner + Settings only, Pro style)
struct AppSidebar: View {
    @Bindable var scanner: JunkScanner
    @Bindable var cleaner: JunkCleaner
    @State private var activeTab: AppTab = .cleaner

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Traffic lights ────────────────────────────────────────────
            HStack(spacing: 8) {
                SidebarDot(color: Color(hex: "#ff5f57"), shadow: Color(hex: "#ff5f57").opacity(0.4)) { NSApplication.shared.terminate(nil) }
                SidebarDot(color: Color(hex: "#febc2e"), shadow: Color(hex: "#febc2e").opacity(0.4)) { NSApplication.shared.keyWindow?.miniaturize(nil) }
                SidebarDot(color: Color(hex: "#28c840"), shadow: Color(hex: "#28c840").opacity(0.4)) { NSApplication.shared.keyWindow?.zoom(nil) }
            }
            .padding(.leading, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)

            // ── Logo ─────────────────────────────────────────────────────
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(RadialGradient(
                            colors: [Color(hex: "#1a1640"), Color(hex: "#0e0c28")],
                            center: .topLeading, startRadius: 0, endRadius: 28
                        ))
                        .frame(width: 38, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(T.p.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Custom trash icon representation
                    VStack(spacing: 1.5) {
                        Rectangle()
                            .fill(Color.white.opacity(0.85))
                            .frame(width: 14, height: 2.5)
                            .clipShape(RoundedRectangle(cornerRadius: 1))
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.75))
                            .frame(width: 12, height: 11)
                            .clipShape(RoundedRectangle(cornerRadius: 1))
                            .overlay(
                                HStack(spacing: 2) {
                                    Color.purple.opacity(0.3).frame(width: 1)
                                    Color.purple.opacity(0.3).frame(width: 1)
                                    Color.purple.opacity(0.3).frame(width: 1)
                                }
                                .padding(.vertical, 2)
                            )
                    }
                }
                .shadow(color: T.p.opacity(0.3), radius: 12)

                Text("JunkClean")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(T.t1)
                    .kerning(-0.4)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 32)

            // ── Nav Items ───────────────────────────────────────────────
            VStack(spacing: 2) {
                AppTabRow(tab: .cleaner, isActive: activeTab == .cleaner) {
                    activeTab = .cleaner
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // ── Bottom: Settings ────────────────────────────────────────
            AppTabRow(tab: .settings, isActive: activeTab == .settings) {
                activeTab = .settings
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 16)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(T.b1)
                    .frame(height: 1)
                    .padding(.horizontal, 10)
                    .offset(y: -6)
            }
        }
        .frame(width: T.sidebarWidth)
        .background(T.bgSidebar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(T.b1).frame(width: 1)
        }
    }
}

// MARK: - Tab enum
enum AppTab: String, CaseIterable {
    case cleaner  = "Junk Cleaner"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .cleaner:  return "trash"
        case .settings: return "gearshape"
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
                    .font(.system(size: 15, weight: .regular))
                    .frame(width: 18)
                    .foregroundStyle(isActive ? T.pLt : T.t2.opacity(hovering ? 1 : 0.6))
                
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? T.t1 : T.t2.opacity(hovering ? 1 : 0.7))
                    .kerning(-0.15)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isActive
                        ? T.pDim
                        : (hovering ? Color.white.opacity(0.035) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isActive ? T.p.opacity(0.24) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: isActive ? T.p.opacity(0.08) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.13)) { hovering = h } }
    }
}

// MARK: - Traffic Light Dot
struct SidebarDot: View {
    let color: Color
    let shadow: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle().strokeBorder(Color.black.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: shadow, radius: 4)
            .scaleEffect(hovering ? 1.08 : 1.0)
            .brightness(hovering ? 0.15 : 0)
            .animation(.easeInOut(duration: 0.12), value: hovering)
            .onHover { h in hovering = h }
            .onTapGesture { action() }
    }
}
