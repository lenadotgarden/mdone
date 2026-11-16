import SwiftUI

/// Look of a section header (spec 02 sections 4, 5, 10).
enum ThingsSectionHeaderStyle: Equatable {
    /// Plain semibold title.
    case standard(title: String)
    /// This Evening: moon icon and blue title.
    case evening(title: String)
    /// Project heading: accent title with a hairline under it.
    case heading(title: String)
    /// Upcoming day: big number and day label, for example 17 and "Tomorrow".
    case upcomingDay(day: String, label: String)
}

struct ThingsSectionHeader: View {
    let style: ThingsSectionHeaderStyle
    /// Optional counter or trailing text shown on the right.
    var trailingText: String? = nil

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: ThingsMetrics.Spacing.s) {
                content(palette)
                Spacer(minLength: ThingsMetrics.Spacing.s)
                if let trailingText = trailingText {
                    Text(verbatim: trailingText)
                        .font(ThingsTypography.counter)
                        .foregroundStyle(palette[.textSecondary])
                }
            }
            if case .heading = style {
                Rectangle()
                    .fill(palette[.accent])
                    .frame(height: ThingsMetrics.Header.headingRuleThickness)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
        .padding(.top, ThingsMetrics.Header.sectionTopPadding)
        .padding(.bottom, ThingsMetrics.Header.sectionBottomPadding)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func content(_ palette: ThingsPalette) -> some View {
        switch style {
        case .standard(let title):
            Text(verbatim: title)
                .font(ThingsTypography.sectionTitle)
                .foregroundStyle(palette[.textPrimary])
        case .evening(let title):
            HStack(spacing: ThingsMetrics.Spacing.s) {
                Image(systemName: ThingsIcons.evening)
                    .font(.system(size: ThingsMetrics.Icon.list * 0.75))
                    .foregroundStyle(palette[.eveningMoon])
                Text(verbatim: title)
                    .font(ThingsTypography.sectionTitle)
                    .foregroundStyle(palette[.eveningMoon])
            }
        case .heading(let title):
            Text(verbatim: title)
                .font(ThingsTypography.heading)
                .foregroundStyle(palette[.accent])
        case .upcomingDay(let day, let label):
            HStack(alignment: .firstTextBaseline, spacing: ThingsMetrics.Spacing.s) {
                Text(verbatim: day)
                    .font(ThingsTypography.upcomingDayNumber)
                    .foregroundStyle(palette[.textPrimary])
                Text(verbatim: label)
                    .font(ThingsTypography.upcomingDayName)
                    .foregroundStyle(palette[.textSecondary])
            }
        }
    }
}

private struct ThingsSectionHeaderSamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThingsSectionHeader(style: .standard(title: "Today"), trailingText: "4")
            ThingsSectionHeader(style: .evening(title: "This Evening"))
            ThingsSectionHeader(style: .heading(title: "Next actions"))
            ThingsSectionHeader(style: .upcomingDay(day: "17", label: "Tomorrow"))
        }
    }
}

#Preview("Section headers light") {
    ThingsSectionHeaderSamples()
        .padding(.bottom)
        .background(ThingsTheme.color(.bgPrimary, .light))
        .environment(\.colorScheme, .light)
}

#Preview("Section headers dark") {
    ThingsSectionHeaderSamples()
        .padding(.bottom)
        .background(ThingsTheme.color(.bgPrimary, .dark))
        .environment(\.colorScheme, .dark)
}
