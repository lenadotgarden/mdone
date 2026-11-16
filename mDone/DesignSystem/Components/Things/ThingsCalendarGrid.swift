import SwiftUI

/// How today is marked in the grid. The When popover shows a star (the Today icon of
/// Things), the Deadline popover a filled blue day.
enum ThingsCalendarTodayStyle {
    case star
    case filled
}

/// The month calendar of the When and Deadline popovers: month and year with a chevron on
/// each side, a row of weekday letters (Monday first) and the days. A day lights up under
/// the pointer, the selected day is filled, the day the keyboard sits on has a soft
/// fill. It owns no state besides the displayed month: the popover owns the selection and
/// the keyboard focus and reacts to `onPick`.
struct ThingsCalendarGrid: View {
    /// Any date inside the month shown. The chevrons change it by a month.
    @Binding var month: Date
    /// The day the to-do has now, drawn as selected.
    let selected: Date?
    /// The day the keyboard sits on.
    let focused: Date?
    var todayStyle: ThingsCalendarTodayStyle = .star
    var calendar: Calendar = .current
    var now: Date = Date()
    let onPick: (Date) -> Void

    @Environment(\.colorScheme) private var scheme

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        let layout = ThingsCalendarMonth.make(containing: month, calendar: calendar)
        let symbols = ThingsCalendarMonth.weekdaySymbols(calendar: calendar)
        return VStack(spacing: ThingsMetrics.DatePopover.cellSpacing) {
            header(layout)
            HStack(spacing: ThingsMetrics.DatePopover.cellSpacing) {
                ForEach(0..<7, id: \.self) { column in
                    Text(verbatim: symbols[column])
                        .font(ThingsTypography.calendarWeekday)
                        .foregroundStyle(palette[.textSecondary])
                        .frame(width: ThingsMetrics.DatePopover.cellSize)
                }
            }
            ForEach(Array(layout.weeks.enumerated()), id: \.offset) { entry in
                HStack(spacing: ThingsMetrics.DatePopover.cellSpacing) {
                    ForEach(0..<7, id: \.self) { column in
                        cell(entry.element[column])
                    }
                }
            }
        }
    }

    private func header(_ layout: ThingsCalendarMonth) -> some View {
        HStack(spacing: 0) {
            Text(verbatim: layout.firstOfMonth.formatted(.dateTime.month(.wide).year()))
                .font(ThingsTypography.calendarMonth)
                .foregroundStyle(palette[.textPrimary])
                .lineLimit(1)
            Spacer(minLength: 0)
            chevron("chevron.left", help: String(localized: "Previous Month")) { shiftMonth(-1) }
            chevron("chevron.right", help: String(localized: "Next Month")) { shiftMonth(1) }
        }
        .frame(height: ThingsMetrics.DatePopover.monthHeaderHeight)
        .padding(.leading, ThingsMetrics.Spacing.xs)
    }

    private func chevron(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: ThingsMetrics.Row.indicatorIconSize, weight: .semibold))
                .foregroundStyle(palette[.textSecondary])
                .frame(width: ThingsMetrics.DatePopover.rowHeight, height: ThingsMetrics.DatePopover.rowHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(Text(verbatim: help))
    }

    @ViewBuilder
    private func cell(_ day: Date?) -> some View {
        if let day = day {
            ThingsCalendarDayCell(
                day: day,
                number: calendar.component(.day, from: day),
                isToday: calendar.isDate(day, inSameDayAs: now),
                isSelected: selected.map { calendar.isDate(day, inSameDayAs: $0) } ?? false,
                isFocused: focused.map { calendar.isDate(day, inSameDayAs: $0) } ?? false,
                style: todayStyle,
                action: { onPick(calendar.startOfDay(for: day)) }
            )
        } else {
            Color.clear
                .frame(width: ThingsMetrics.DatePopover.cellSize, height: ThingsMetrics.DatePopover.cellSize)
        }
    }

    private func shiftMonth(_ months: Int) {
        month = ThingsCalendarMonth.shift(month, months: months, calendar: calendar)
    }
}

private struct ThingsCalendarDayCell: View {
    let day: Date
    let number: Int
    let isToday: Bool
    let isSelected: Bool
    let isFocused: Bool
    let style: ThingsCalendarTodayStyle
    let action: () -> Void

    @State private var isHovering = false
    @Environment(\.colorScheme) private var scheme

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    /// A solid accent fill: the selected day of the When grid, today in the Deadline grid.
    private var isAccentFilled: Bool {
        switch style {
        case .star: return isSelected
        case .filled: return isToday
        }
    }

    private var background: Color {
        if isAccentFilled { return palette[.accent] }
        if isSelected || isFocused || isHovering { return palette[.selectionRow] }
        return Color.clear
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: ThingsMetrics.DatePopover.cellCornerRadius, style: .continuous)
        return Button(action: action) {
            ZStack {
                shape.fill(background)
                if isSelected && !isAccentFilled {
                    shape.strokeBorder(palette[.accent], lineWidth: ThingsMetrics.Checkbox.borderWidth)
                }
                label
            }
            .frame(width: ThingsMetrics.DatePopover.cellSize, height: ThingsMetrics.DatePopover.cellSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(Text(verbatim: day.formatted(date: .complete, time: .omitted)))
    }

    @ViewBuilder
    private var label: some View {
        if isToday && style == .star {
            Image(systemName: ThingsIcons.today)
                .font(.system(size: ThingsMetrics.DatePopover.todayStarSize))
                .foregroundStyle(isAccentFilled ? Color.white : palette[.todayStar])
        } else {
            Text(verbatim: String(number))
                .font(ThingsTypography.calendarDay)
                .foregroundStyle(isAccentFilled ? Color.white : palette[.textPrimary])
        }
    }
}

#Preview("Calendar grid dark") {
    ThingsCalendarGridPreview()
        .padding()
        .background(ThingsTheme.color(.bgPrimary, .dark))
        .environment(\.colorScheme, .dark)
}

private struct ThingsCalendarGridPreview: View {
    @State private var month = Date()

    var body: some View {
        ThingsCalendarGrid(month: $month, selected: nil, focused: nil, onPick: { _ in })
    }
}
