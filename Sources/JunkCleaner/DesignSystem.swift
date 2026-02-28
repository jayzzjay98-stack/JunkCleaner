import SwiftUI

// MARK: - Design Tokens
enum DS {

    // MARK: Colors
    static let bgPrimary     = Color(hex: "#0c0c12")
    static let bgSecondary   = Color(hex: "#12121c")
    static let bgTertiary    = Color(hex: "#18182a")
    static let bgQuaternary  = Color(hex: "#1e1e30")

    static let borderSubtle  = Color.white.opacity(0.06)
    static let borderDefault = Color.white.opacity(0.10)

    static let textPrimary   = Color(hex: "#f0f0ff")
    static let textSecondary = Color(hex: "#8b8baa")
    static let textTertiary  = Color(hex: "#4a4a6a")

    // Accent palette
    static let violet        = Color(hex: "#667eea")
    static let purple        = Color(hex: "#764ba2")
    static let lavender      = Color(hex: "#a78bfa")
    static let indigo        = Color(hex: "#818cf8")

    // Semantic
    static let success       = Color(hex: "#34d399")
    static let successDim    = Color(hex: "#34d399").opacity(0.12)
    static let successBorder = Color(hex: "#34d399").opacity(0.2)
    static let warning       = Color(hex: "#f97316")
    static let warningAmber  = Color(hex: "#fbbf24")

    // MARK: Gradients
    static let gradientAccent = LinearGradient(
        colors: [violet, purple, lavender],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
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
    static let gradientNavIndicator = LinearGradient(
        colors: [violet, lavender],
        startPoint: .top, endPoint: .bottom
    )

    // Ring gradients (as AngularGradient for donut)
    static func ringGradient(for state: RingState) -> AngularGradient {
        switch state {
        case .idle:
            return AngularGradient(
                colors: [violet, lavender, violet],
                center: .center, startAngle: .degrees(0), endAngle: .degrees(360)
            )
        case .junk:
            return AngularGradient(
                colors: [warning, warningAmber, warning],
                center: .center, startAngle: .degrees(0), endAngle: .degrees(360)
            )
        case .clean:
            return AngularGradient(
                colors: [success, Color(hex: "#6ee7b7"), success],
                center: .center, startAngle: .degrees(0), endAngle: .degrees(360)
            )
        }
    }

    // MARK: Shadows
    static let shadowApp   = Color.black.opacity(0.85)
    static let glowAccent  = violet.opacity(0.35)
    static let glowSuccess = success.opacity(0.3)
    static let glowJunk    = warning.opacity(0.3)

    // MARK: Corner Radii
    static let radiusApp     : CGFloat = 22
    static let radiusCard    : CGFloat = 13
    static let radiusChip    : CGFloat = 12
    static let radiusItem    : CGFloat = 11
    static let radiusButton  : CGFloat = 13
    static let radiusLogo    : CGFloat = 7
    static let radiusNavItem : CGFloat = 11
    static let radiusIcon    : CGFloat = 10
    static let radiusBanner  : CGFloat = 12
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
        case .devTools:    return DS.violet
        case .browsers:    return Color(hex: "#8b5cf6")
        case .systemJunk:  return Color(hex: "#f59e0b")
        case .appLeftovers: return Color(hex: "#06b6d4")
        case .other:       return DS.success
        }
    }
}
