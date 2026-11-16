import SwiftUI

/// Look of a section header (spec 02 sections 4, 5, 10).
enum ThingsSectionHeaderStyle: Equatable {
    /// Plain semibold title.
    case standard(title: String)
    /// This Evening: moon icon and title.
    case evening(title: String)
    /// Project heading: accent title with a hairline under it.
    case heading(title: String)
    /// Upcoming day: big number and day label, for example 17 and "Tomorrow".
    case upcomingDay(day: String, label: String)
    /// Icon, title and rule, such as "Upcoming" (calendar) and "Someday" (box)
    /// inside a project (mac-dark-03.png).
    case icon(title: String, symbolName: String, tint: ThingsColorToken)
}

/// Section header. Mac (MEASURED on mac-dark-01 and 03): a 14 pt icon, the title
/// in 14 pt bold white, then a hairline rule 6 pt below that spans the list
/// width minus 7 pt each side. iOS keeps the plain layout.
struct ThingsSectionHeader: View {
    let style: ThingsSectionHeaderStyle
    /// Optional counter or trailing text shown on the right.
    var trailingText: String? = nil

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        VStack(alignment: .leading, spacing: ruleGap) {
            HStack(alignment: .center, spacing: ThingsMetrics.Spacing.s) {
                content(palette)
                Spacer(minLength: ThingsMetrics.Spacing.s)
                if let trailingText = trailingText {
                    Text(verbatim: trailingText)
                        .font(ThingsTypography.counter)
                        .foregroundStyle(palette[.textSecondary])
                }
            }
            .padding(.leading, contentLeading)
            rule(palette)
        }
        .padding(.horizontal, outerPadding)
        .padding(.top, ThingsMetrics.Header.sectionTopPadding)
        .padding(.bottom, ThingsMetrics.Header.sectionBottomPadding)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Layout per platform

    private var ruleGap: CGFloat {
        ThingsPlatform.value(ios: ThingsMetrics.Spacing.xs, mac: ThingsMetrics.Header.sectionRuleGap)
    }

    /// Mac: the header content starts 8 pt in (icon x), the rule 7 pt in.
    private var contentLeading: CGFloat {
        ThingsPlatform.value(ios: 0, mac: 1)
    }

    private var outerPadding: CGFloat {
        ThingsPlatform.value(ios: ThingsMetrics.Layout.listHorizontalMargin, mac: ThingsMetrics.Header.sectionRuleInset)
    }

    @ViewBuilder
    private func rule(_ palette: ThingsPalette) -> some View {
        #if os(macOS)
        Rectangle()
            .fill(palette[.separator])
            .frame(height: ThingsMetrics.Header.sectionRuleThickness)
            .accessibilityHidden(true)
        #else
        if case .heading = style {
            Rectangle()
                .fill(palette[.accent])
                .frame(height: ThingsMetrics.Header.headingRuleThickness)
                .accessibilityHidden(true)
        }
        #endif
    }

    // MARK: - Content

    private var titleColorToken: ThingsColorToken {
        ThingsPlatform.value(ios: ThingsColorToken.eveningMoon, mac: ThingsColorToken.textPrimary)
    }

    @ViewBuilder
    private func content(_ palette: ThingsPalette) -> some View {
        switch style {
        case .standard(let title):
            Text(verbatim: title)
                .font(ThingsTypography.sectionTitle)
                .foregroundStyle(palette[.textPrimary])
        case .evening(let title):
            HStack(spacing: iconTitleGap) {
                Image(systemName: ThingsIcons.evening)
                    .font(.system(size: iconSize))
                    .foregroundStyle(palette[.eveningMoon])
                Text(verbatim: title)
                    .font(ThingsTypography.sectionTitle)
                    .foregroundStyle(palette[titleColorToken])
            }
        case .icon(let title, let symbolName, let tint):
            HStack(spacing: iconTitleGap) {
                Image(systemName: symbolName)
                    .font(.system(size: iconSize))
                    .foregroundStyle(palette[tint])
                Text(verbatim: title)
                    .font(ThingsTypography.sectionTitle)
                    .foregroundStyle(palette[.textPrimary])
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

    /// iOS icon sizes as before (list size x 0.75), Mac MEASURED 14 pt.
    private var iconSize: CGFloat {
        ThingsPlatform.value(ios: ThingsMetrics.Icon.list * 0.75, mac: ThingsMetrics.Icon.section)
    }

    /// Mac MEASURED: icon 30..44, title at 53, so 9 pt.
    private var iconTitleGap: CGFloat {
        ThingsPlatform.value(ios: ThingsMetrics.Spacing.s, mac: 9)
    }
}

private struct ThingsSectionHeaderSamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThingsSectionHeader(style: .standard(title: "Today"), trailingText: "4")
            ThingsSectionHeader(style: .evening(title: "This Evening"))
            ThingsSectionHeader(style: .heading(title: "Next actions"))
            ThingsSectionHeader(style: .upcomingDay(day: "17", label: "Tomorrow"))
            ThingsSectionHeader(style: .icon(title: "Upcoming", symbolName: ThingsIcons.upcoming, tint: .upcomingRed))
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
