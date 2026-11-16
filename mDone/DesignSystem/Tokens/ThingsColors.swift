import SwiftUI

// Things-style colour tokens (docs/things-spec/01-design-tokens.md section 2).
// Provenance tags in the comments of `hexPair`:
//   MEASURED   sampled from docs/things-spec/reference/mac-dark-0N.png
//   ESTIMATED  read by eye on the same screenshots (hue right, value within a few steps)
//   DERIVED    light variant derived from the measured dark one, no light screenshot
//   UNSURE     still a guess (iOS values, light palette)
// No platform UI framework: light and dark variants are resolved from a ColorScheme.
// The dark column is the "dark warm" palette of the Mac screenshots (brown-grey,
// not the cool iOS greys). It is the default dark palette.

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
    case areaTint
    case trashGray
    case filterBarGreen
    // Neutrals
    case bgPrimary
    case bgSidebar
    case bgExpandedTodo
    case bgCalendarBox
    case bgSidebarSelection
    case textPrimary
    case textSecondary
    case textPlaceholder
    case textMutedLink
    case separator
    case checkboxBorder
    case tagPillBackground
    case tagPillBorder
    case tagPillText
    case chipFill
    case chipText
    case selectionRow
}

/// Opacity values used with the colour tokens.
enum ThingsColorOpacity {
    /// Multi-select row background, accent at 12 percent in light (UNSURE).
    static let selectionLight: Double = 0.12
    /// Kept for iOS multi-select. The Mac dark selection is the solid MEASURED colour.
    static let selectionDark: Double = 0.22
    /// Someday content is drawn at half strength (spec 2.2, VERIFIED behaviour, value UNSURE).
    static let somedayDim: Double = 0.5
    /// Opacity of the card shadow colour (black), light appearance. UNSURE.
    static let cardShadow: Double = 0.12
    /// Card shadow in the dark warm palette: nearly invisible in the screenshots,
    /// so a soft one. ESTIMATED.
    static let cardShadowDark: Double = 0.30
    /// Shadow under a row lifted by a drag. ESTIMATED.
    static let liftShadow: Double = 0.35
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

    /// Card shadow colour for this scheme.
    var cardShadowColor: Color {
        Color.black.opacity(scheme == .dark ? ThingsColorOpacity.cardShadowDark : ThingsColorOpacity.cardShadow)
    }
}

enum ThingsTheme {
    /// The colour of `token` for `scheme`.
    static func color(_ token: ThingsColorToken, _ scheme: ColorScheme, pureBlackDark: Bool = false) -> Color {
        let isDark = (scheme == .dark)
        if token == .selectionRow {
            if isDark { return rgb(0x393C3F) }   // MEASURED (list selection)
            return color(.accent, scheme).opacity(ThingsColorOpacity.selectionLight)
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
        case .accent: return (0x1E7BF4, 0x3D8FF7)            // UNSURE
        case .todayStar: return (0xFFCC00, 0xFFD60A)          // ESTIMATED dark (star glyph in the screenshots)
        case .eveningMoon: return (0x3A59D1, 0xA9B7F3)        // dark ESTIMATED (pale periwinkle moon), light UNSURE
        case .deadlineFlame: return (0xFF3B30, 0xFF453A)      // UNSURE
        case .upcomingRed: return (0xF2405D, 0xF0476B)        // dark ESTIMATED (calendar icon in sidebar and header)
        case .anytimeTeal: return (0x35B6A7, 0x3BAFA8)        // dark ESTIMATED
        case .somedayTan: return (0xD8B98A, 0xDCC48C)         // dark ESTIMATED (archive box)
        case .logbookGreen: return (0x4CC260, 0x57C26A)       // dark ESTIMATED
        case .areaGray: return (0x8E8E93, 0x8E8A88)           // dark ESTIMATED
        case .areaTint: return (0x3AA68A, 0x7CCFAE)           // dark ESTIMATED (mint cube in the Area header), light DERIVED
        case .trashGray: return (0x8E8E93, 0x8E8A88)          // dark ESTIMATED
        case .filterBarGreen: return (0x34C759, 0x30D158)     // UNSURE
        case .bgPrimary: return (0xFFFFFF, 0x302C2A)          // dark MEASURED
        case .bgSidebar: return (0xF5F6F8, 0x312D2C)          // dark MEASURED, light UNSURE
        case .bgExpandedTodo: return (0xFFFFFF, 0x3B3735)     // dark ESTIMATED (card, a step above the calendar box)
        case .bgCalendarBox: return (0xF1F1F3, 0x3F3B39)      // dark MEASURED, light DERIVED
        case .bgSidebarSelection: return (0xDADDE3, 0x3B3E42) // dark MEASURED, light DERIVED
        case .textPrimary: return (0x1D1D1F, 0xF4F2F0)        // dark ESTIMATED (warm white)
        case .textSecondary: return (0x8E8E93, 0x8F8B89)      // dark ESTIMATED (project line, notes icon)
        case .textPlaceholder: return (0xC7C7CC, 0x77726F)    // dark ESTIMATED ("Notes", card icons)
        case .textMutedLink: return (0xA0A0A5, 0x7A7674)      // dark ESTIMATED ("Hide later items")
        case .separator: return (0xE5E5EA, 0x4F4B4A)          // dark MEASURED
        case .checkboxBorder: return (0xB8BCC4, 0x7C7875)     // dark ESTIMATED
        case .tagPillBackground: return (0xEDEDF0, 0x3F3B39)  // iOS fill, UNSURE (Mac uses the outline)
        case .tagPillBorder: return (0xC7C7CC, 0x6A6664)      // dark ESTIMATED
        case .tagPillText: return (0x6D6D72, 0x9A9694)        // dark ESTIMATED
        case .chipFill: return (0xC9C9CE, 0x8F8B89)           // dark ESTIMATED (selected "All" pill)
        case .chipText: return (0x2A2A2C, 0x2B2725)           // dark ESTIMATED
        case .selectionRow: return (0x1E7BF4, 0x393C3F)       // unused here, see `color`
        }
    }
}
