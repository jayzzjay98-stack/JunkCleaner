import SwiftUI

// MARK: - Design Tokens (matching junkclean-mockup.html)
enum T {
    // Colors
    static let bgVoid   = Color(hex: "#07070f")
    static let bgBase   = Color(hex: "#0d0d1a")
    static let bgRaised = Color(hex: "#121220")
    static let bgFloat  = Color(hex: "#181828")
    static let bgHover  = Color(hex: "#1e1e32")

    static let borderDim = Color.white.opacity(0.055)
    static let borderMid = Color.white.opacity(0.09)
    static let borderHi  = Color.white.opacity(0.14)

    static let txt1 = Color(hex: "#f0efff")
    static let txt2 = Color(hex: "#f0efff").opacity(0.52)
    static let txt3 = Color(hex: "#f0efff").opacity(0.25)
    static let txt4 = Color(hex: "#f0efff").opacity(0.13)

    static let acc       = Color(hex: "#7b68ee")
    static let accLight  = Color(hex: "#9d90f5")
    static let accDim    = Color(hex: "#7b68ee").opacity(0.18)
    static let accGlow   = Color(hex: "#7b68ee").opacity(0.32)

    static let ok        = Color(hex: "#3ec98e")
    static let okGlow    = Color(hex: "#3ec98e").opacity(0.5)
    static let warn      = Color(hex: "#f97316")
    static let warnGlow  = Color(hex: "#f97316").opacity(0.5)

    // Gradients
    static let accGrad = LinearGradient(
        colors: [Color(hex: "#6c5ce7"), Color(hex: "#8b7cf8"), Color(hex: "#a78bfa")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let bgGradient = LinearGradient(
        colors: [bgVoid, bgBase],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Common Glass Background used for panels
    static let glassBg = bgRaised.opacity(0.8) // Approximation of raised surface
}

// MARK: - Glass Panel Modifier
struct GlassPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(T.bgRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(T.borderMid, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassPanel() -> some View { modifier(GlassPanel()) }
}
