import SwiftUI

// MARK: - Theme

public struct AppTheme {
    public let name: String
    public let accent: Color
    public let accentDim: Color
    public let bgColor: Color
    public let borderColor: Color
}

public let appThemes: [AppTheme] = [
    AppTheme(name: "AMBER",  accent: Color(red: 1.0, green: 0.55, blue: 0.0),  accentDim: Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.1), bgColor: Color(red: 0.06, green: 0.047, blue: 0.03), borderColor: Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.22)),
    AppTheme(name: "MATRIX", accent: Color(red: 0.0, green: 1.0, blue: 0.53),  accentDim: Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.08), bgColor: Color(red: 0.027, green: 0.06, blue: 0.04), borderColor: Color(red: 0.0, green: 1.0, blue: 0.53).opacity(0.2)),
    AppTheme(name: "ARCTIC", accent: Color(red: 0.0, green: 0.78, blue: 1.0),  accentDim: Color(red: 0.0, green: 0.78, blue: 1.0).opacity(0.08), bgColor: Color(red: 0.027, green: 0.05, blue: 0.07), borderColor: Color(red: 0.0, green: 0.78, blue: 1.0).opacity(0.22)),
    AppTheme(name: "COSMIC", accent: Color(red: 0.66, green: 0.33, blue: 0.97), accentDim: Color(red: 0.66, green: 0.33, blue: 0.97).opacity(0.1), bgColor: Color(red: 0.047, green: 0.03, blue: 0.07), borderColor: Color(red: 0.66, green: 0.33, blue: 0.97).opacity(0.22)),
    AppTheme(name: "ROSE",   accent: Color(red: 0.98, green: 0.44, blue: 0.52), accentDim: Color(red: 0.98, green: 0.44, blue: 0.52).opacity(0.1), bgColor: Color(red: 0.07, green: 0.03, blue: 0.06), borderColor: Color(red: 0.98, green: 0.44, blue: 0.52).opacity(0.22)),
    AppTheme(name: "GOLD",   accent: Color(red: 0.96, green: 0.77, blue: 0.09), accentDim: Color(red: 0.96, green: 0.77, blue: 0.09).opacity(0.1), bgColor: Color(red: 0.067, green: 0.055, blue: 0.016), borderColor: Color(red: 0.96, green: 0.77, blue: 0.09).opacity(0.22)),
    AppTheme(name: "CYAN",   accent: Color(red: 0.0, green: 0.9, blue: 0.8),   accentDim: Color(red: 0.0, green: 0.9, blue: 0.8).opacity(0.08), bgColor: Color(red: 0.02, green: 0.06, blue: 0.055), borderColor: Color(red: 0.0, green: 0.9, blue: 0.8).opacity(0.22)),
    AppTheme(name: "LAVA",   accent: Color(red: 1.0, green: 0.23, blue: 0.36),  accentDim: Color(red: 1.0, green: 0.23, blue: 0.36).opacity(0.1), bgColor: Color(red: 0.067, green: 0.02, blue: 0.02), borderColor: Color(red: 1.0, green: 0.23, blue: 0.36).opacity(0.22)),
    AppTheme(name: "LIME",   accent: Color(red: 0.52, green: 0.8, blue: 0.09),  accentDim: Color(red: 0.52, green: 0.8, blue: 0.09).opacity(0.1), bgColor: Color(red: 0.035, green: 0.06, blue: 0.02), borderColor: Color(red: 0.52, green: 0.8, blue: 0.09).opacity(0.22)),
    AppTheme(name: "SILVER", accent: Color(red: 0.69, green: 0.72, blue: 0.8),  accentDim: Color(red: 0.69, green: 0.72, blue: 0.8).opacity(0.1), bgColor: Color(red: 0.05, green: 0.05, blue: 0.06), borderColor: Color(red: 0.69, green: 0.72, blue: 0.8).opacity(0.2)),
    
    // 25 New Themes
    AppTheme(name: "SUN",    accent: Color(red: 1.0, green: 0.85, blue: 0.2),  accentDim: Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.1), bgColor: Color(red: 0.07, green: 0.06, blue: 0.02), borderColor: Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.22)),
    AppTheme(name: "NIGHT",  accent: Color(red: 0.1, green: 0.3, blue: 0.8),   accentDim: Color(red: 0.1, green: 0.3, blue: 0.8).opacity(0.1), bgColor: Color(red: 0.01, green: 0.02, blue: 0.06), borderColor: Color(red: 0.1, green: 0.3, blue: 0.8).opacity(0.22)),
    AppTheme(name: "FOREST", accent: Color(red: 0.1, green: 0.5, blue: 0.2),   accentDim: Color(red: 0.1, green: 0.5, blue: 0.2).opacity(0.1), bgColor: Color(red: 0.01, green: 0.04, blue: 0.02), borderColor: Color(red: 0.1, green: 0.5, blue: 0.2).opacity(0.22)),
    AppTheme(name: "BERRY",  accent: Color(red: 0.8, green: 0.2, blue: 0.6),   accentDim: Color(red: 0.8, green: 0.2, blue: 0.6).opacity(0.1), bgColor: Color(red: 0.06, green: 0.01, blue: 0.04), borderColor: Color(red: 0.8, green: 0.2, blue: 0.6).opacity(0.22)),
    AppTheme(name: "OCEAN",  accent: Color(red: 0.0, green: 0.5, blue: 1.0),   accentDim: Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.1), bgColor: Color(red: 0.01, green: 0.04, blue: 0.08), borderColor: Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.22)),
    AppTheme(name: "MINT",   accent: Color(red: 0.2, green: 0.9, blue: 0.6),   accentDim: Color(red: 0.2, green: 0.9, blue: 0.6).opacity(0.1), bgColor: Color(red: 0.02, green: 0.07, blue: 0.05), borderColor: Color(red: 0.2, green: 0.9, blue: 0.6).opacity(0.22)),
    AppTheme(name: "CORAL",  accent: Color(red: 1.0, green: 0.5, blue: 0.4),   accentDim: Color(red: 1.0, green: 0.5, blue: 0.4).opacity(0.1), bgColor: Color(red: 0.08, green: 0.04, blue: 0.03), borderColor: Color(red: 1.0, green: 0.5, blue: 0.4).opacity(0.22)),
    AppTheme(name: "PEACH",  accent: Color(red: 1.0, green: 0.7, blue: 0.5),   accentDim: Color(red: 1.0, green: 0.7, blue: 0.5).opacity(0.1), bgColor: Color(red: 0.08, green: 0.05, blue: 0.04), borderColor: Color(red: 1.0, green: 0.7, blue: 0.5).opacity(0.22)),
    AppTheme(name: "PLUM",   accent: Color(red: 0.5, green: 0.2, blue: 0.6),   accentDim: Color(red: 0.5, green: 0.2, blue: 0.6).opacity(0.1), bgColor: Color(red: 0.04, green: 0.01, blue: 0.05), borderColor: Color(red: 0.5, green: 0.2, blue: 0.6).opacity(0.22)),
    AppTheme(name: "ONYX",   accent: Color(red: 0.4, green: 0.4, blue: 0.4),   accentDim: Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.1), bgColor: Color(red: 0.03, green: 0.03, blue: 0.03), borderColor: Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.22)),
    AppTheme(name: "JADE",   accent: Color(red: 0.0, green: 0.7, blue: 0.4),   accentDim: Color(red: 0.0, green: 0.7, blue: 0.4).opacity(0.1), bgColor: Color(red: 0.01, green: 0.06, blue: 0.03), borderColor: Color(red: 0.0, green: 0.7, blue: 0.4).opacity(0.22)),
    AppTheme(name: "RUBY",   accent: Color(red: 0.9, green: 0.1, blue: 0.2),   accentDim: Color(red: 0.9, green: 0.1, blue: 0.2).opacity(0.1), bgColor: Color(red: 0.07, green: 0.01, blue: 0.02), borderColor: Color(red: 0.9, green: 0.1, blue: 0.2).opacity(0.22)),
    AppTheme(name: "TEAL",   accent: Color(red: 0.1, green: 0.6, blue: 0.6),   accentDim: Color(red: 0.1, green: 0.6, blue: 0.6).opacity(0.1), bgColor: Color(red: 0.01, green: 0.05, blue: 0.05), borderColor: Color(red: 0.1, green: 0.6, blue: 0.6).opacity(0.22)),
    AppTheme(name: "BONE",   accent: Color(red: 0.9, green: 0.9, blue: 0.8),   accentDim: Color(red: 0.9, green: 0.9, blue: 0.8).opacity(0.1), bgColor: Color(red: 0.07, green: 0.07, blue: 0.06), borderColor: Color(red: 0.9, green: 0.9, blue: 0.8).opacity(0.22)),
    AppTheme(name: "IRIS",   accent: Color(red: 0.4, green: 0.3, blue: 0.9),   accentDim: Color(red: 0.4, green: 0.3, blue: 0.9).opacity(0.1), bgColor: Color(red: 0.03, green: 0.02, blue: 0.07), borderColor: Color(red: 0.4, green: 0.3, blue: 0.9).opacity(0.22)),
    AppTheme(name: "INK",    accent: Color(red: 0.1, green: 0.1, blue: 0.3),   accentDim: Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.1), bgColor: Color(red: 0.01, green: 0.01, blue: 0.02), borderColor: Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.22)),
    AppTheme(name: "MOSS",   accent: Color(red: 0.3, green: 0.5, blue: 0.2),   accentDim: Color(red: 0.3, green: 0.5, blue: 0.2).opacity(0.1), bgColor: Color(red: 0.02, green: 0.04, blue: 0.02), borderColor: Color(red: 0.3, green: 0.5, blue: 0.2).opacity(0.22)),
    AppTheme(name: "SAND",   accent: Color(red: 0.8, green: 0.7, blue: 0.5),   accentDim: Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.1), bgColor: Color(red: 0.06, green: 0.05, blue: 0.04), borderColor: Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.22)),
    AppTheme(name: "RUST",   accent: Color(red: 0.7, green: 0.3, blue: 0.1),   accentDim: Color(red: 0.7, green: 0.3, blue: 0.1).opacity(0.1), bgColor: Color(red: 0.06, green: 0.02, blue: 0.01), borderColor: Color(red: 0.7, green: 0.3, blue: 0.1).opacity(0.22)),
    AppTheme(name: "SKY",    accent: Color(red: 0.4, green: 0.8, blue: 1.0),   accentDim: Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.1), bgColor: Color(red: 0.03, green: 0.06, blue: 0.08), borderColor: Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.22)),
    AppTheme(name: "WINE",   accent: Color(red: 0.6, green: 0.1, blue: 0.2),   accentDim: Color(red: 0.6, green: 0.1, blue: 0.2).opacity(0.1), bgColor: Color(red: 0.05, green: 0.01, blue: 0.02), borderColor: Color(red: 0.6, green: 0.1, blue: 0.2).opacity(0.22)),
    AppTheme(name: "FLORA",  accent: Color(red: 0.9, green: 0.5, blue: 0.8),   accentDim: Color(red: 0.9, green: 0.5, blue: 0.8).opacity(0.1), bgColor: Color(red: 0.07, green: 0.04, blue: 0.06), borderColor: Color(red: 0.9, green: 0.5, blue: 0.8).opacity(0.22)),
    AppTheme(name: "LEAF",   accent: Color(red: 0.4, green: 0.9, blue: 0.3),   accentDim: Color(red: 0.4, green: 0.9, blue: 0.3).opacity(0.1), bgColor: Color(red: 0.03, green: 0.07, blue: 0.02), borderColor: Color(red: 0.4, green: 0.9, blue: 0.3).opacity(0.22)),
    AppTheme(name: "DUST",   accent: Color(red: 0.6, green: 0.5, blue: 0.5),   accentDim: Color(red: 0.6, green: 0.5, blue: 0.5).opacity(0.1), bgColor: Color(red: 0.05, green: 0.04, blue: 0.04), borderColor: Color(red: 0.6, green: 0.5, blue: 0.5).opacity(0.22)),
    AppTheme(name: "ICE",    accent: Color(red: 0.7, green: 0.9, blue: 1.0),   accentDim: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.1), bgColor: Color(red: 0.05, green: 0.07, blue: 0.08), borderColor: Color(red: 0.7, green: 0.9, blue: 1.0).opacity(0.22)),
]
