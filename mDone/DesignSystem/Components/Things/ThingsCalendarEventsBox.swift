import SwiftUI

/// One calendar event line of the Today box: a coloured bar and a title.
struct ThingsCalendarEventLine: Identifiable, Equatable {
    var id: String
    var title: String
    /// The calendar colour as 0xRRGGBB. Nil uses the secondary text colour.
    var barHex: UInt32? = nil
}

/// The rounded box of calendar events above the Today list (mac-dark-01.png,
/// MEASURED: 1000 x 66 pt for three lines, radius about 10 pt, text 12 pt, 16 pt line pitch,
/// 3 pt colour bar, fill #3F3B39 in dark).
struct ThingsCalendarEventsBox: View {
    let lines: [ThingsCalendarEventLine]

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(lines) { line in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(barColor(line, palette))
                        .frame(width: ThingsMetrics.CalendarBox.barWidth, height: ThingsMetrics.CalendarBox.barHeight)
                    Text(verbatim: line.title)
                        .font(ThingsTypography.calendarEvent)
                        .foregroundStyle(palette[.textPrimary])
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .frame(height: ThingsMetrics.CalendarBox.linePitch)
            }
        }
        .padding(.horizontal, ThingsMetrics.CalendarBox.horizontalPadding)
        .padding(.vertical, ThingsMetrics.CalendarBox.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: ThingsMetrics.CalendarBox.cornerRadius, style: .continuous)
                .fill(palette[.bgCalendarBox])
        )
        .padding(.horizontal, ThingsMetrics.CalendarBox.outerInset)
        .accessibilityElement(children: .combine)
    }

    private func barColor(_ line: ThingsCalendarEventLine, _ palette: ThingsPalette) -> Color {
        if let hex = line.barHex { return ThingsTheme.rgb(hex) }
        return palette[.textSecondary]
    }
}

/// The tag filter bar under the list title: "All", then one chip per tag, then a "..."
/// (mac-dark-01.png, MEASURED: pills 20 pt high, 12 pt semibold; the selected one is
/// a filled grey capsule with dark text, the others plain grey text).
struct ThingsFilterBar: View {
    let tags: [String]
    /// The selected tag, nil for "All".
    let selection: String?
    let onSelect: (String?) -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        HStack(spacing: ThingsMetrics.Spacing.s) {
            chip(title: String(localized: "All"), isSelected: selection == nil, palette: palette) {
                onSelect(nil)
            }
            ForEach(tags, id: \.self) { tag in
                chip(title: tag, isSelected: selection == tag, palette: palette) {
                    onSelect(tag)
                }
            }
            Image(systemName: ThingsIcons.moreDots)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(palette[.textSecondary])
                .padding(.horizontal, ThingsMetrics.Spacing.xs)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
    }

    private func chip(title: String, isSelected: Bool, palette: ThingsPalette, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(ThingsTypography.filterChip)
                .foregroundStyle(isSelected ? palette[.chipText] : palette[.textSecondary])
                .lineLimit(1)
                .padding(.horizontal, 7)
                .frame(height: ThingsMetrics.Chip.filterHeight)
                .background(Capsule().fill(isSelected ? palette[.chipFill] : Color.clear))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A quiet link at the end of a list: "Hide later items", "Show 3 logged items".
struct ThingsFooterLink: View {
    let title: String
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(ThingsTypography.footerLink)
                .foregroundStyle(ThingsPalette(scheme)[.textMutedLink])
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
    }
}
