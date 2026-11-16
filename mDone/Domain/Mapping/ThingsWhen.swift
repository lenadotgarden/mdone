import Foundation

/// How a task's Things "When" is read from Vikunja data
/// (docs/things-spec/07-vikunja-mapping.md, sections 6 to 8).
///
/// - `startDate` holds the day, stored at 12:00 local.
/// - The `things:evening` label turns Today into This Evening.
/// - The `things:someday` label wins over any start date.
enum ThingsWhen: Equatable {
    case today
    case thisEvening
    case someday
    /// A future day. The payload is the start of that local day.
    case date(Date)
    case none

    // MARK: - Reading

    /// The When of a task.
    ///
    /// SPEC-UNSURE: a start day before today still reads as `.today` (the task
    /// stays in Today, 06 section 4).
    /// SPEC-UNSURE: `things:evening` only counts when a start date is set (07
    /// section 7). On a future day the enum has no evening case, so it reads as
    /// `.date`, and the label itself is left alone by the patch builder only
    /// when the caller does not change the When.
    static func resolve(
        startDate: Date?,
        labels: [String],
        now: Date,
        calendar: Calendar
    ) -> ThingsWhen {
        if ThingsReservedLabels.contains(ThingsReservedLabels.someday, in: labels) {
            return .someday
        }
        guard let start = validDate(startDate, calendar: calendar) else {
            return .none
        }
        let day = calendar.startOfDay(for: start)
        let today = calendar.startOfDay(for: now)
        if day <= today {
            let evening = ThingsReservedLabels.contains(ThingsReservedLabels.evening, in: labels)
            return evening ? .thisEvening : .today
        }
        return .date(day)
    }

    /// The When of `task`.
    static func resolve(task: VTask, now: Date, calendar: Calendar) -> ThingsWhen {
        resolve(
            startDate: task.startDate,
            labels: task.thingsLabelTitles,
            now: now,
            calendar: calendar
        )
    }

    // MARK: - Writing

    /// What to change on a task so that its When becomes `when`.
    static func patch(for when: ThingsWhen, now: Date, calendar: Calendar) -> ThingsWhenPatch {
        let evening = ThingsReservedLabels.evening
        let someday = ThingsReservedLabels.someday
        switch when {
        case .today:
            return ThingsWhenPatch(
                startDate: .set(noonLocal(now, calendar: calendar)),
                addLabels: [],
                removeLabels: [evening, someday]
            )
        case .thisEvening:
            return ThingsWhenPatch(
                startDate: .set(noonLocal(now, calendar: calendar)),
                addLabels: [evening],
                removeLabels: [someday]
            )
        case .someday:
            return ThingsWhenPatch(
                startDate: .clear,
                addLabels: [someday],
                removeLabels: [evening]
            )
        case .date(let day):
            return ThingsWhenPatch(
                startDate: .set(noonLocal(day, calendar: calendar)),
                addLabels: [],
                removeLabels: [evening, someday]
            )
        case .none:
            return ThingsWhenPatch(
                startDate: .clear,
                addLabels: [],
                removeLabels: [evening, someday]
            )
        }
    }

    /// The patch that makes this When true. See `patch(for:now:calendar:)`.
    func patch(now: Date, calendar: Calendar) -> ThingsWhenPatch {
        ThingsWhen.patch(for: self, now: now, calendar: calendar)
    }

    // MARK: - Dates

    /// `date` moved to 12:00 of its local day. Falls back to `date` itself in
    /// the unlikely case the calendar cannot build that time.
    static func noonLocal(_ date: Date, calendar: Calendar) -> Date {
        let day = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? date
    }

    /// Whether `date` is unset: nil, `Date.distantPast`, or Vikunja's zero
    /// date (year 1).
    static func isZeroDate(_ date: Date?, calendar: Calendar) -> Bool {
        guard let date = date else { return true }
        if date == Date.distantPast { return true }
        return calendar.component(.year, from: date) <= 1
    }

    /// `date` unless it is unset (see `isZeroDate`).
    static func validDate(_ date: Date?, calendar: Calendar) -> Date? {
        if isZeroDate(date, calendar: calendar) { return nil }
        return date
    }
}

/// Free function form of `ThingsWhen.noonLocal`.
func noonLocal(_ date: Date, calendar: Calendar) -> Date {
    ThingsWhen.noonLocal(date, calendar: calendar)
}

/// What to do with a date field.
enum ThingsDateChange: Equatable {
    /// Leave the field as it is.
    case unchanged
    /// Set the field to this value.
    case set(Date)
    /// Clear the field (send null).
    case clear
}

/// The change that turns a task's current When into a wanted one. UI code
/// applies it without ever naming a reserved label title.
struct ThingsWhenPatch: Equatable {
    var startDate: ThingsDateChange
    /// Reserved label titles to attach.
    var addLabels: [String]
    /// Reserved label titles to detach.
    var removeLabels: [String]

    /// True when applying the patch changes nothing.
    var isEmpty: Bool {
        startDate == .unchanged && addLabels.isEmpty && removeLabels.isEmpty
    }

    /// The same patch reduced to what actually differs on `task`: a start date
    /// it already has is `.unchanged`, labels already present are not added
    /// again, labels it lacks are not removed.
    func minimized(against task: VTask, calendar: Calendar) -> ThingsWhenPatch {
        var result = self
        let current = ThingsWhen.validDate(task.startDate, calendar: calendar)
        switch startDate {
        case .unchanged:
            break
        case .clear:
            if current == nil {
                result.startDate = .unchanged
            }
        case .set(let wanted):
            if let existing = current, existing == wanted {
                result.startDate = .unchanged
            }
        }
        let titles = task.thingsLabelTitles
        result.addLabels = addLabels.filter { !ThingsReservedLabels.contains($0, in: titles) }
        result.removeLabels = removeLabels.filter { ThingsReservedLabels.contains($0, in: titles) }
        return result
    }
}
