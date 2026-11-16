import SwiftUI

/// Big list title with its icon (spec 02 section 2). Pass `progress` to show a project pie instead of the icon.
struct ThingsListHeader: View {
    let title: String
    let symbolName: String
    var tint: ThingsColorToken = .accent
    /// When set, a ThingsProjectPie replaces the symbol.
    var progress: Double? = nil

    @Environment(\.colorScheme) private var scheme

    init(title: String, symbolName: String, tint: ThingsColorToken = .accent, progress: Double? = nil) {
        self.title = title
        self.symbolName = symbolName
        self.tint = tint
        self.progress = progress
    }

    init(title: String, kind: ThingsListKind, progress: Double? = nil) {
        self.title = title
        self.symbolName = ThingsIcons.symbol(for: kind)
        self.tint = ThingsIcons.tint(for: kind)
        self.progress = progress
    }

    var body: some View {
        let palette = ThingsPalette(scheme)
        HStack(spacing: ThingsMetrics.Header.iconTitleSpacing) {
            if let progress = progress {
                ThingsProjectPie(progress: progress, size: ThingsMetrics.Pie.headerSize, tint: tint)
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: ThingsMetrics.Icon.header, weight: .semibold))
                    .foregroundStyle(palette[tint])
                    .frame(width: ThingsMetrics.Icon.header, height: ThingsMetrics.Icon.header)
                    .accessibilityHidden(true)
            }
            Text(verbatim: title)
                .font(ThingsTypography.listTitle)
                .foregroundStyle(palette[.textPrimary])
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
        .padding(.top, ThingsMetrics.Header.topPadding)
        .padding(.bottom, ThingsMetrics.Header.bottomPadding)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct ThingsListHeaderSamples: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThingsListHeader(title: "Today", kind: .today)
            ThingsListHeader(title: "Inbox", kind: .inbox)
            ThingsListHeader(title: "Upcoming", kind: .upcoming)
            ThingsListHeader(title: "Anytime", kind: .anytime)
            ThingsListHeader(title: "Someday", kind: .someday)
            ThingsListHeader(title: "Logbook", kind: .logbook)
            ThingsListHeader(title: "Website", kind: .project, progress: 0.4)
        }
    }
}

#Preview("List header light") {
    ThingsListHeaderSamples()
        .background(ThingsTheme.color(.bgPrimary, .light))
        .environment(\.colorScheme, .light)
}

#Preview("List header dark") {
    ThingsListHeaderSamples()
        .background(ThingsTheme.color(.bgPrimary, .dark))
        .environment(\.colorScheme, .dark)
}
