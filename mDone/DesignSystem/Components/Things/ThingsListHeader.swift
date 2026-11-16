import SwiftUI

/// Big list title with its icon (spec 02 section 2). Pass `progress` to show a project pie instead of the icon.
/// Mac (MEASURED on mac-dark-01 and 03): icon 22 pt, title 22 pt bold, 8 pt apart,
/// an optional trailing view (the "..." menu of a project) 10 pt after the title.
struct ThingsListHeader: View {
    let title: String
    let symbolName: String
    var tint: ThingsColorToken = .accent
    /// When set, a ThingsProjectPie replaces the symbol.
    var progress: Double? = nil
    /// Shown after the title, for example the "..." menu of a project.
    var trailing: AnyView? = nil
    /// Overrides the space under the title (the Today box sits 13 pt below it).
    var bottomPadding: CGFloat? = nil

    @Environment(\.colorScheme) private var scheme

    init(title: String, symbolName: String, tint: ThingsColorToken = .accent, progress: Double? = nil, trailing: AnyView? = nil, bottomPadding: CGFloat? = nil) {
        self.bottomPadding = bottomPadding
        self.title = title
        self.symbolName = symbolName
        self.tint = tint
        self.progress = progress
        self.trailing = trailing
    }

    init(title: String, kind: ThingsListKind, progress: Double? = nil, trailing: AnyView? = nil, bottomPadding: CGFloat? = nil) {
        self.bottomPadding = bottomPadding
        self.title = title
        self.symbolName = ThingsIcons.symbol(for: kind)
        self.tint = (kind == .area) ? ThingsColorToken.areaTint : ThingsIcons.tint(for: kind)
        self.progress = progress
        self.trailing = trailing
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
            if let trailing = trailing {
                trailing
                    .padding(.leading, ThingsMetrics.Spacing.xs)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
        .padding(.top, ThingsMetrics.Header.topPadding)
        .padding(.bottom, bottomPadding ?? ThingsMetrics.Header.bottomPadding)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The "..." button next to a project title (mac-dark-03.png). Three grey dots in a
/// borderless menu; the items are the caller's.
struct ThingsMoreMenu<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) private var scheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Menu {
            content
        } label: {
            Image(systemName: ThingsIcons.moreDots)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ThingsPalette(scheme)[.textSecondary])
                .frame(width: 24, height: 18)
                .contentShape(Rectangle())
        }
        #if os(macOS)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        #endif
        .fixedSize()
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
