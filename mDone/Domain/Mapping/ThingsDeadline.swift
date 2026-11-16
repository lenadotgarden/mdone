import Foundation

/// The wording kind of a deadline for the UI. The caller localizes it.
enum ThingsDeadlineText: Equatable {
    case today
    /// Days until the deadline, always 1 or more.
    case daysLeft(Int)
    /// Days since the deadline, always 1 or more.
    case daysAgo(Int)
}

/// Deadline helpers. A deadline is `dueDate`, stored at 12:00 local, and is
/// compared by calendar day only (07 section 6).
enum ThingsDeadline {
    /// The start of the deadline day, nil when `dueDate` is unset or the zero date.
    static func day(of dueDate: Date?, calendar: Calendar) -> Date? {
        guard let valid = ThingsWhen.validDate(dueDate, calendar: calendar) else { return nil }
        return calendar.startOfDay(for: valid)
    }

    /// Whole calendar days from today to the deadline day: positive when the
    /// deadline is ahead, 0 today, negative when past. Nil when no deadline.
    static func daysLeft(dueDate: Date?, now: Date, calendar: Calendar) -> Int? {
        guard let deadlineDay = day(of: dueDate, calendar: calendar) else { return nil }
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: today, to: deadlineDay).day
    }

    /// Whether the deadline day is before today. A done task is never overdue.
    static func isOverdue(dueDate: Date?, done: Bool = false, now: Date, calendar: Calendar) -> Bool {
        if done { return false }
        guard let left = daysLeft(dueDate: dueDate, now: now, calendar: calendar) else { return false }
        return left < 0
    }

    /// Whether `task` is overdue.
    static func isOverdue(task: VTask, now: Date, calendar: Calendar) -> Bool {
        isOverdue(dueDate: task.dueDate, done: task.done, now: now, calendar: calendar)
    }

    /// The text kind for a deadline, nil when there is none.
    static func text(dueDate: Date?, now: Date, calendar: Calendar) -> ThingsDeadlineText? {
        guard let left = daysLeft(dueDate: dueDate, now: now, calendar: calendar) else { return nil }
        if left == 0 { return .today }
        if left > 0 { return .daysLeft(left) }
        return .daysAgo(-left)
    }

    /// The text kind for `task`'s deadline.
    static func text(task: VTask, now: Date, calendar: Calendar) -> ThingsDeadlineText? {
        text(dueDate: task.dueDate, now: now, calendar: calendar)
    }
}
