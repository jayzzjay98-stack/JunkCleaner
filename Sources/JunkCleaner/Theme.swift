import SwiftUI



// MARK: - Design Tokens (matching HTML exactly)
enum T {
    // Background gradient: #0f172a → #1e1b4b → #312e81
    static let bg0 = Color(hex: "#0f172a")
    static let bg1 = Color(hex: "#1e1b4b")
    static let bg2 = Color(hex: "#312e81")

    // Primary purple
    static let primary    = Color(hex: "#5211d4")
    static let indigo500  = Color(hex: "#6366f1")
    static let violet400  = Color(hex: "#a78bfa")
    static let blue500    = Color(hex: "#3b82f6")
    static let blue400    = Color(hex: "#60a5fa")

    // Semantic
    static let green400   = Color(hex: "#4ade80")
    static let orange400  = Color(hex: "#fb923c")
    static let cyan400    = Color(hex: "#22d3ee")
    static let teal500    = Color(hex: "#14b8a6")
    static let purple400  = Color(hex: "#c084fc")
    static let pink500    = Color(hex: "#ec4899")

    // Text
    static let textWhite  = Color.white
    static let textDim    = Color(hex: "#a5b4fc").opacity(0.6)   // indigo-200/60
    static let textFaint  = Color(hex: "#a5b4fc").opacity(0.4)   // indigo-200/40
    static let textMuted  = Color(hex: "#a5b4fc").opacity(0.5)
    static let slate300   = Color(hex: "#cbd5e1")

    // Glass surfaces (from HTML CSS)
    static let glassBg     = Color(hex: "#1e1b4b").opacity(0.4)   // rgba(30,27,75,0.4)
    static let glassBorder = Color.white.opacity(0.08)             // rgba(255,255,255,0.08)
    static let glassSurface = Color.white.opacity(0.05)            // rgba(255,255,255,0.05)
    static let glassHover  = Color.white.opacity(0.05)

    // Gradients
    static let bgGradient = LinearGradient(
        colors: [bg0, bg1, bg2],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let primaryGradient = LinearGradient(
        colors: [primary, blue500],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cpuBarGradient = LinearGradient(
        colors: [blue400, indigo500],
        startPoint: .leading, endPoint: .trailing
    )
    static let memBarGradient = LinearGradient(
        colors: [purple400, pink500],
        startPoint: .leading, endPoint: .trailing
    )
    static let diskBarGradient = LinearGradient(
        colors: [cyan400, teal500],
        startPoint: .leading, endPoint: .trailing
    )
    static let glassButtonGradient = LinearGradient(
        colors: [Color.white.opacity(0.10), Color.white.opacity(0.05)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Glass Panel (matches .glass-panel in HTML)
struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(T.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(T.glassBorder, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassPanel() -> some View { modifier(GlassPanel()) }
}
