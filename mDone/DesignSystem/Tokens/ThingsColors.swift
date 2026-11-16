import SwiftUI

// Things-style colour tokens (docs/things-spec/01-design-tokens.md section 2).
// Every hex below is [UNSURE] or [FROM-MEMORY] unless noted: recalibrate here only.
// No platform UI framework: light and dark variants are resolved from a ColorScheme.

/// Names of every colour a Things-style view may use.
enum ThingsColorToken: CaseIterable {
    // Accent and semantic
    case accent
    case todayStar
    case eveningMoon
    case deadlineFlame
    case upcomingRed
    case anytimeTeal
    case somedayTan
    case logbookGreen
    case areaGray
    case trashGray
    case filterBarGreen
    // Neutrals
    case bgPrimary
    case bgSidebar
    case bgExpandedTodo
    case textPrimary
    case textSecondary
    case textPlaceholder
    case separator
    case checkboxBorder
    case tagPillBackground
    case tagPillText
    case selectionRow
}

/// Opacity values used with the colour tokens.
enum ThingsColorOpacity {
    /// Multi-select row background, accent at 12 percent in light.
    static let selectionLight: Double = 0.12
    /// Multi-select row background, accent at 22 percent in dark.
    static let selectionDark: Double = 0.22
    /// Someday content is drawn at half strength (spec 2.2, VERIFIED behaviour, value UNSURE).
    static let somedayDim: Double = 0.5
    /// Opacity of the card shadow colour (black).
    static let cardShadow: Double = 0.12
}

/// Resolves tokens for one colour scheme.
struct ThingsPalette: Equatable {
    let scheme: ColorScheme
    /// Dark appearance with a pure black background (the "Black" theme, spec 2.2).
    let pureBlackDark: Bool

    init(_ scheme: ColorScheme, pureBlackDark: Bool = false) {
        self.scheme = scheme
        self.pureBlackDark = pureBlackDark
    }

    subscript(_ token: ThingsColorToken) -> Color {
        ThingsTheme.color(token, scheme, pureBlackDark: pureBlackDark)
    }
}

enum ThingsTheme {
    /// The colour of `token` for `scheme`.
    static func color(_ token: ThingsColorToken, _ scheme: ColorScheme, pureBlackDark: Bool = false) -> Color {
        let isDark = (scheme == .dark)
        if token == .selectionRow {
            let opacity = isDark ? ThingsColorOpacity.selectionDark : ThingsColorOpacity.selectionLight
            return color(.accent, scheme).opacity(opacity)
        }
        if pureBlackDark && isDark && token == .bgPrimary {
            return rgb(0x000000)
        }
        let pair = hexPair(token)
        return rgb(isDark ? pair.dark : pair.light)
    }

    /// Colour from a 0xRRGGBB value in sRGB.
    static func rgb(_ hex: UInt32, opacity: Double = 1) -> Color {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    /// The single table to recalibrate. (light, dark) as 0xRRGGBB.
    private static func hexPair(_ token: ThingsColorToken) -> (light: UInt32, dark: UInt32) {
        switch token {
        case .accent: return (0x1E7BF4, 0x3D8FF7)            // [UNSURE]
        case .todayStar: return (0xFFCC00, 0xFFD60A)          // [UNSURE]
        case .eveningMoon: return (0x3A59D1, 0x5E7CF5)        // [UNSURE]
        case .deadlineFlame: return (0xFF3B30, 0xFF453A)      // [UNSURE]
        case .upcomingRed: return (0xF2405D, 0xFF5C75)        // [UNSURE] dark is a PROPOSAL
        case .anytimeTeal: return (0x35B6A7, 0x4CCDBE)        // [UNSURE] dark is a PROPOSAL
        case .somedayTan: return (0xD8B98A, 0xE0C69D)         // [UNSURE] dark is a PROPOSAL
        case .logbookGreen: return (0x4CC260, 0x5ED172)       // [UNSURE] dark is a PROPOSAL
        case .areaGray: return (0x8E8E93, 0x98989D)           // light FROM-MEMORY
        case .trashGray: return (0x8E8E93, 0x98989D)          // [UNSURE]
        case .filterBarGreen: return (0x34C759, 0x30D158)     // [UNSURE]
        case .bgPrimary: return (0xFFFFFF, 0x1C1C1E)
        case .bgSidebar: return (0xF5F6F8, 0x2C2C2E)          // [UNSURE]
        case .bgExpandedTodo: return (0xFFFFFF, 0x2C2C2E)
        case .textPrimary: return (0x1D1D1F, 0xF2F2F7)        // [UNSURE]
        case .textSecondary: return (0x8E8E93, 0x98989D)
        case .textPlaceholder: return (0xC7C7CC, 0x48484A)
        case .separator: return (0xE5E5EA, 0x38383A)
        case .checkboxBorder: return (0xB8BCC4, 0x636366)     // [UNSURE]
        case .tagPillBackground: return (0xEDEDF0, 0x3A3A3C)
        case .tagPillText: return (0x6D6D72, 0xAEAEB2)
        case .selectionRow: return (0x1E7BF4, 0x3D8FF7)       // unused, derived from accent
        }
    }
}
