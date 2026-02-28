import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: NavTab

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                ForEach(NavTab.allCases.filter { $0 != .settings }, id: \.self) { tab in
                    NavItem(tab: tab, isSelected: selectedTab == tab) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.top, 12)

            Spacer()

            NavItem(tab: .settings, isSelected: selectedTab == .settings) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedTab = .settings
                }
            }
            .padding(.bottom, 12)
        }
        .frame(width: 60)
        .background(DS.bgPrimary)
    }
}

// MARK: - Nav Item
struct NavItem: View {
    let tab: NavTab
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Active indicator bar
                if isSelected {
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(DS.gradientNavIndicator)
                            .frame(width: 3, height: 18)
                            .offset(x: -1)
                        Spacer()
                    }
                }

                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DS.radiusNavItem)
                        .fill(
                            isSelected
                            ? DS.lavender.opacity(0.12)
                            : (hovering ? DS.bgTertiary : Color.clear)
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            isSelected
                            ? DS.lavender
                            : (hovering ? DS.textSecondary : DS.textTertiary)
                        )

                    // Badge dot
                    if tab.hasBadge {
                        Circle()
                            .fill(Color(hex: "#f87171"))
                            .frame(width: 5, height: 5)
                            .offset(x: 12, y: -12)
                    }
                }
            }
            .frame(width: 52, height: 44)
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.12)) { hovering = h }
        }
        .help(tab.label)
    }
}
