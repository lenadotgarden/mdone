import SwiftUI

/// Tag pill. iOS: grey filled capsule. Mac: outlined capsule, as in the captures
/// (MEASURED 16 pt high, 0.75 pt grey stroke, no fill). `isActive` turns it into
/// the green filter style (spec 01 section 2.3).
struct ThingsTagChip: View {
    let title: String
    var isActive: Bool = false

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        Text(verbatim: title)
            .font(ThingsTypography.tagPill)
            .foregroundStyle(isActive ? Color.white : palette[.tagPillText])
            .lineLimit(1)
            .padding(.horizontal, ThingsMetrics.Chip.horizontalPadding)
            .padding(.vertical, ThingsMetrics.Chip.verticalPadding)
            .background(background(palette))
            .overlay(outline(palette))
            .accessibilityLabel(Text(verbatim: title))
    }

    @ViewBuilder
    private func background(_ palette: ThingsPalette) -> some View {
        #if os(macOS)
        Capsule().fill(isActive ? palette[.filterBarGreen] : Color.clear)
        #else
        Capsule().fill(isActive ? palette[.filterBarGreen] : palette[.tagPillBackground])
        #endif
    }

    @ViewBuilder
    private func outline(_ palette: ThingsPalette) -> some View {
        #if os(macOS)
        if !isActive {
            Capsule().strokeBorder(palette[.tagPillBorder], lineWidth: ThingsMetrics.Chip.tagBorderWidth)
        }
        #else
        EmptyView()
        #endif
    }
}

#Preview("Tag chips light") {
    HStack {
        ThingsTagChip(title: "Home")
        ThingsTagChip(title: "Errand")
        ThingsTagChip(title: "Important", isActive: true)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .light))
    .environment(\.colorScheme, .light)
}

#Preview("Tag chips dark") {
    HStack {
        ThingsTagChip(title: "Home")
        ThingsTagChip(title: "Errand")
        ThingsTagChip(title: "Important", isActive: true)
    }
    .padding()
    .background(ThingsTheme.color(.bgPrimary, .dark))
    .environment(\.colorScheme, .dark)
}
