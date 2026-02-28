import SwiftUI

// MARK: - Design Tokens (matching junkclean-pro.html)
enum T {
    // Fonts
    static let fontInter = "Inter"
    static let fontMono = "JetBrains Mono"

    // Background layers
    static let bgApp      = Color(hex: "#09090f")
    static let bgSidebar  = Color(hex: "#0f0f18")
    static let bgMain     = Color(hex: "#0b0b14")
    static let bgSurface  = Color(hex: "#13131f")
    static let bgElevated = Color(hex: "#181826")
    static let bgHover    = Color(hex: "#1c1c2c")
    static let bgActive   = Color(hex: "#1f1f30")

    // Borders
    static let b1 = Color.white.opacity(0.055)
    static let b2 = Color.white.opacity(0.09)
    static let b3 = Color.white.opacity(0.14)

    // Text
    static let t1 = Color.white.opacity(0.95)
    static let t2 = Color.white.opacity(0.50)
    static let t3 = Color.white.opacity(0.25)
    static let t4 = Color.white.opacity(0.12)

    // Accent
    static let p      = Color(hex: "#7c6af0")
    static let pLt    = Color(hex: "#9d8ff5")
    static let pDim   = Color(hex: "#7c6af0").opacity(0.15)
    static let pGlow  = Color(hex: "#7c6af0").opacity(0.30)
    
    static let pGrad = LinearGradient(
        colors: [Color(hex: "#6b5ce8"), Color(hex: "#8b7af5"), Color(hex: "#a394fa")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Semantic
    static let ok        = Color(hex: "#3dcb8a")
    static let okGlow    = Color(hex: "#3dcb8a").opacity(0.45)
    static let warn      = Color(hex: "#f97316")
    static let warnGlow  = Color(hex: "#f97316").opacity(0.45)
    static let red       = Color(hex: "#f04040")

    // Sidebar dimensions
    static let sidebarWidth: CGFloat = 228
}

// MARK: - Glass Panel Modifier
struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(T.bgSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(T.b1, lineWidth: 1)
            )
    }
}

extension View {
    func glassPanel() -> some View { modifier(GlassPanel()) }
}
