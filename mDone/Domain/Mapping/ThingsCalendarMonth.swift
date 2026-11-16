import Foundation

/// A month laid out for the calendar grid of the When and Deadline popovers: weeks of
/// seven days, Monday first. Pure, so the layout is unit tested without a view.
struct ThingsCalendarMonth: Equatable {
    /// Midnight of the first day of the month.
    let firstOfMonth: Date
    /// Rows of seven cells, Monday to Sunday. A cell outside the month is nil.
    let weeks: [[Date?]]

    /// The days of the month in order.
    var days: [Date] { weeks.flatMap { $0 }.compactMap { $0 } }

    /// A copy of `calendar` whose weeks start on Monday.
    static func mondayFirst(_ calendar: Calendar) -> Calendar {
        var copy = calendar
        copy.firstWeekday = 2
        return copy
    }

    /// The month that contains `date`.
    static func make(containing date: Date, calendar: Calendar) -> ThingsCalendarMonth {
        let cal = mondayFirst(calendar)
        let parts = cal.dateComponents([.year, .month], from: date)
        let first = cal.date(from: parts) ?? cal.startOfDay(for: date)
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        let weekday = cal.component(.weekday, from: first)
        let leading = (weekday - cal.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<count {
            cells.append(cal.date(byAdding: .day, value: offset, to: first))
        }
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        var weeks: [[Date?]] = []
        var index = 0
        while index < cells.count {
            weeks.append(Array(cells[index..<(index + 7)]))
            index += 7
        }
        return ThingsCalendarMonth(firstOfMonth: first, weeks: weeks)
    }

    /// One letter weekday names, Monday first.
    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = mondayFirst(calendar).veryShortStandaloneWeekdaySymbols
        if symbols.count != 7 { return ["M", "T", "W", "T", "F", "S", "S"] }
        return Array(symbols[1...6]) + [symbols[0]]
    }

    /// The first day of the month `months` away from the month of `date`.
    static func shift(_ date: Date, months: Int, calendar: Calendar) -> Date {
        let first = make(containing: date, calendar: calendar).firstOfMonth
        return calendar.date(byAdding: .month, value: months, to: first) ?? first
    }

    /// Whether two dates are in the same month.
    static func sameMonth(_ lhs: Date, _ rhs: Date, calendar: Calendar) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    enum Direction {
        case left, right, up, down
    }

    /// The day the arrow keys move the keyboard focus to: a day for left and right, a
    /// week for up and down. The result is a midnight.
    static func moveFocus(_ date: Date, _ direction: Direction, calendar: Calendar) -> Date {
        let step: Int
        switch direction {
        case .left: step = -1
        case .right: step = 1
        case .up: step = -7
        case .down: step = 7
        }
        let day = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: step, to: day) ?? day
    }
}
