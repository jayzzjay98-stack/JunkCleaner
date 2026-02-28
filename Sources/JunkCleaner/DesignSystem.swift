import SwiftUI

// MARK: - Design Tokens (Updated to match mockup HTML)
enum DS {

    // MARK: Colors
    static let bgPrimary     = T.bgVoid
    static let bgSecondary   = T.bgBase
    static let bgTertiary    = T.bgRaised
    static let bgQuaternary  = T.bgFloat

    static let borderSubtle  = T.borderDim
    static let borderDefault = T.borderMid

    static let textPrimary   = T.txt1
    static let textSecondary = T.txt2
    static let textTertiary  = T.txt3

    // Accent palette
    static let violet        = T.acc
    static let purple        = Color(hex: "#6c5ce7")
    static let lavender      = T.accLight
    static let indigo        = Color(hex: "#8b7cf8")

    // Semantic
    static let success       = T.ok
    static let successDim    = T.ok.opacity(0.12)
    static let successBorder = T.ok.opacity(0.2)
    static let warning       = T.warn
    static let warningAmber  = Color(hex: "#fbbf24")

    // MARK: Gradients
    static let gradientAccent = T.accGrad
    
    static let gradientHeroText = LinearGradient(
        colors: [Color.white, indigo.opacity(0.8)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let gradientJunk = LinearGradient(
        colors: [warning, warningAmber],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientSuccess = LinearGradient(
        colors: [success, Color(hex: "#6ee7b7")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientDiskUsed = LinearGradient(
        colors: [violet, lavender],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientScanBar = LinearGradient(
        colors: [violet, lavender, Color(hex: "#f093fb")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientNavIndicator = T.accGrad

    // Ring gradients
    static func ringGradient(for state: RingState) -> LinearGradient {
        switch state {
        case .idle:  return T.accGrad
        case .junk:  return LinearGradient(colors: [T.warn, Color(hex: "#fbbf24")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .clean: return LinearGradient(colors: [T.ok, Color(hex: "#6ee7b7")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: Shadows
    static let shadowApp   = Color.black.opacity(0.85)
    static let glowAccent  = T.accGlow
    static let glowSuccess = T.okGlow
    static let glowJunk    = T.warnGlow

    // MARK: Corner Radii
    static let radiusApp     : CGFloat = 16 // Mockup uses 16px
    static let radiusCard    : CGFloat = 13
    static let radiusChip    : CGFloat = 12
    static let radiusItem    : CGFloat = 11
    static let radiusButton  : CGFloat = 11 // Mockup uses 11px
    static let radiusLogo    : CGFloat = 10 // Mockup uses 10px
    static let radiusNavItem : CGFloat = 9  // Mockup uses 9px
    static let radiusIcon    : CGFloat = 8  // Mockup uses 8px
    static let radiusBanner  : CGFloat = 9  // Mockup uses 9px
}

enum RingState { case idle, junk, clean }

// MARK: - Color Hex Init
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Category icon + color helpers
extension JunkType {
    var displayIcon: String {
        switch self {
        case .xcodeDerivedData, .xcodeArchives, .xcodeDocsets, .xcodeSimulators: return "hammer.fill"
        case .brewCache, .npmCache, .yarnCache, .pipCache, .gradleCache, .mavenCache, .podCache, .gemCache, .dockerImages: return "shippingbox.fill"
        case .safariCache, .chromeCache, .firefoxCache: return "network"
        case .systemLogs, .appLogs, .appCrashReports: return "doc.text.fill"
        case .trashContents: return "trash.fill"
        case .systemCaches, .appCaches: return "internaldrive.fill"
        case .iosBackups, .iosDeviceSupport: return "iphone"
        case .mailAttachments: return "envelope.fill"
        case .downloadsOld: return "arrow.down.circle.fill"
        case .systemTempFiles: return "clock.fill"
        default: return "folder.fill"
        }
    }

    var accentColor: Color {
        switch category {
        case .devTools:     return Color(hex: "#7c6af7")
        case .browsers:     return Color(hex: "#818cf8")
        case .systemJunk:   return Color(hex: "#f59e0b")
        case .appLeftovers: return Color(hex: "#a78bfa")
        case .other:        return Color(hex: "#34d399")
        }
    }
    
    var emoji: String {
        switch category {
        case .devTools:    return "🔨"
        case .browsers:    return "🌐"
        case .systemJunk:  return "💿"
        case .appLeftovers: return "🗂️"
        case .other:       return "📄"
        }
    }
}

extension JunkItem {
    var accentColor: Color { type.accentColor }
    var emoji: String { type.emoji }
}
