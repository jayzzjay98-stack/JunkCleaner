import SwiftUI

// MARK: - Design Tokens (Updated to match mockup Pro)
enum DS {

    // MARK: Colors
    static let bgPrimary     = T.bgApp
    static let bgSecondary   = T.bgSidebar
    static let bgTertiary    = T.bgMain
    static let bgQuaternary  = T.bgSurface
    static let bgElevated    = T.bgElevated
    static let bgHover      = T.bgHover
    static let bgActive     = T.bgActive

    static let borderSubtle  = T.b1
    static let borderDefault = T.b2
    static let borderStrong  = T.b3

    static let textPrimary   = T.t1
    static let textSecondary = T.t2
    static let textTertiary  = T.t3
    static let textMuted     = T.t4

    // Accent palette
    static let purple        = T.p
    static let purpleLt      = T.pLt
    static let purpleDim     = T.pDim
    static let purpleGlow    = T.pGlow

    // Semantic
    static let success       = T.ok
    static let successGlow   = T.okGlow
    static let warning       = T.warn
    static let warningGlow   = T.warnGlow
    static let error         = T.red

    // MARK: Gradients
    static let pGrad         = T.pGrad
    
    // Ring gradients
    static func ringGradient(for state: RingState) -> LinearGradient {
        switch state {
        case .idle:  return pGrad
        case .junk:  return LinearGradient(colors: [T.warn, Color(hex: "#fbbf24")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .clean: return LinearGradient(colors: [T.ok, Color(hex: "#6ee7b7")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // MARK: Shadows
    static let shadowApp   = Color.black.opacity(0.7)
    
    // MARK: Corner Radii
    static let radiusApp     : CGFloat = 14 // Mockup uses 14px
    static let radiusCard    : CGFloat = 12
    static let radiusChip    : CGFloat = 9
    static let radiusButton  : CGFloat = 10 // Mockup uses 10px
    static let radiusLogo    : CGFloat = 10 // Mockup uses 10px
    static let radiusNavItem : CGFloat = 8  // Mockup uses 8px
    static let radiusIcon    : CGFloat = 8  // Mockup uses 8px
    static let radiusBanner  : CGFloat = 8  // Mockup uses 8px
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
        case .devTools:     return Color(hex: "#7c6af0")
        case .browsers:     return Color(hex: "#818cf8")
        case .systemJunk:   return Color(hex: "#f59e0b")
        case .appLeftovers: return Color(hex: "#a78bfa")
        case .other:        return Color(hex: "#ef4444")
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
    
    var catText: String {
        switch category {
        case .devTools:    return "developer · cache"
        case .browsers:    return "browser · cache"
        case .systemJunk:  return "system · junk"
        case .appLeftovers: return "app · leftovers"
        case .other:       return "logs · diagnostics"
        }
    }
}

extension JunkItem {
    var accentColor: Color { type.accentColor }
    var emoji: String { type.emoji }
    var catText: String { type.catText }
}
