import SwiftUI

/// Grey tag pill. `isActive` turns it into the green filter style (spec 01 section 2.3).
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
            .background(Capsule().fill(isActive ? palette[.filterBarGreen] : palette[.tagPillBackground]))
            .accessibilityLabel(Text(verbatim: title))
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
