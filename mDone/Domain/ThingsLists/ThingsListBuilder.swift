import Foundation

/// Pure list computation for the Things-style lists, from the decision table
/// of docs/things-spec/06-behaviors-rules.md (sections 2 and 4 to 9) and the
/// date conventions of 07-vikunja-mapping.md (When = `startDate`, Deadline =
/// `dueDate`, both a full-day value stored at 12:00 local).
///
/// Everything is compared by calendar day in the given `calendar`. A date that
/// is nil or Vikunja's zero date (year 1, `Date.distantPast`) counts as unset.
/// A task can appear in several lists (a Today task is also in Anytime).
///
/// Subtask masking (07, section 5) is left to the caller: pass only the tasks
/// that should be listed.
enum ThingsListBuilder {
    /// Upcoming shows one block per day for this many days starting tomorrow.
    static let upcomingDayCount = 7

    // MARK: - Public API

    /// The sections of `list`, empty sections omitted.
    ///
    /// - Parameters:
    ///   - inboxProjectID: the Inbox project, or nil when unknown (then the
    ///     Inbox is empty and Anytime excludes nothing).
    ///   - now: the current instant; "today" is its day in `calendar`.
    static func sections(
        for list: ThingsList,
        tasks: [VTask],
        inboxProjectID: Int64?,
        now: Date,
        calendar: Calendar
    ) -> [ThingsListSection] {
        let facts = prepare(tasks, calendar: calendar)
        return sections(for: list, facts: facts, inboxProjectID: inboxProjectID, now: now, calendar: calendar)
    }

    /// The number of tasks in `list` (sum over its sections).
    static func count(
        for list: ThingsList,
        tasks: [VTask],
        inboxProjectID: Int64?,
        now: Date,
        calendar: Calendar
    ) -> Int {
        let built = sections(
            for: list, tasks: tasks, inboxProjectID: inboxProjectID, now: now, calendar: calendar
        )
        return built.reduce(0) { $0 + $1.tasks.count }
    }

    /// The task count of every list.
    static func counts(
        tasks: [VTask],
        inboxProjectID: Int64?,
        now: Date,
        calendar: Calendar
    ) -> [ThingsList: Int] {
        snapshot(tasks: tasks, inboxProjectID: inboxProjectID, now: now, calendar: calendar).counts
    }

    /// Every list at once from a single pass over `tasks`: the per-task date
    /// work (start day, deadline day, reserved labels) is done once and shared
    /// by the six lists and their counts. This is what the view models cache.
    static func snapshot(
        tasks: [VTask],
        inboxProjectID: Int64?,
        now: Date,
        calendar: Calendar
    ) -> ThingsListSnapshot {
        let facts = prepare(tasks, calendar: calendar)
        var built: [ThingsList: [ThingsListSection]] = [:]
        var counts: [ThingsList: Int] = [:]
        for list in ThingsList.allCases {
            let result = sections(
                for: list, facts: facts, inboxProjectID: inboxProjectID, now: now, calendar: calendar
            )
            built[list] = result
            counts[list] = result.reduce(0) { $0 + $1.tasks.count }
        }
        return ThingsListSnapshot(sections: built, counts: counts)
    }

    // MARK: - Prepared facts

    /// A task with the values every list rule reads, computed once.
    private struct Facts {
        let task: VTask
        let startDay: Date?
        let deadlineDay: Date?
        let isSomeday: Bool
        let isEvening: Bool
    }

    /// One pass over `tasks`. Days are memoized by instant, since the full-day
    /// convention stores almost every date at 12:00.
    private static func prepare(_ tasks: [VTask], calendar: Calendar) -> [Facts] {
        var dayMemo: [TimeInterval: Date] = [:]
        func day(_ date: Date?) -> Date? {
            guard let valid = validDate(date) else { return nil }
            let key = valid.timeIntervalSinceReferenceDate
            if let known = dayMemo[key] { return known }
            let computed = calendar.startOfDay(for: valid)
            dayMemo[key] = computed
            return computed
        }
        var result: [Facts] = []
        result.reserveCapacity(tasks.count)
        for task in tasks {
            var isSomeday = false
            var isEvening = false
            if let labels = task.labels {
                for label in labels {
                    if ThingsReservedLabels.matches(label.title, ThingsReservedLabels.someday) { isSomeday = true }
                    if ThingsReservedLabels.matches(label.title, ThingsReservedLabels.evening) { isEvening = true }
                }
            }
            result.append(
                Facts(
                    task: task,
                    startDay: day(task.startDate),
                    deadlineDay: day(task.dueDate),
                    isSomeday: isSomeday,
                    isEvening: isEvening
                )
            )
        }
        return result
    }

    private static func sections(
        for list: ThingsList,
        facts: [Facts],
        inboxProjectID: Int64?,
        now: Date,
        calendar: Calendar
    ) -> [ThingsListSection] {
        let today = calendar.startOfDay(for: now)
        switch list {
        case .inbox:
            let matching = facts.filter { isInInbox($0, inboxProjectID: inboxProjectID) }.map { $0.task }
            return single(id: "inbox", tasks: matching)
        case .today:
            return todaySections(facts: facts, today: today)
        case .upcoming:
            return upcomingSections(facts: facts, today: today, calendar: calendar)
        case .anytime:
            let matching = facts
                .filter { isAnytime($0, inboxProjectID: inboxProjectID, today: today) }
                .map { $0.task }
            return single(id: "anytime", tasks: matching)
        case .someday:
            let matching = facts.filter { !$0.task.done && $0.isSomeday }.map { $0.task }
            return single(id: "someday", tasks: matching)
        case .logbook:
            return logbookSections(tasks: facts.map { $0.task }, calendar: calendar)
        }
    }

    // MARK: - Dates

    /// `date` unless it is nil or the zero date.
    ///
    /// Vikunja's zero date decodes to `Date.distantPast`; anything before about
    /// the year 4 is treated the same way. A plain interval comparison, because
    /// asking a `Calendar` for the year of every date of every task on every
    /// build was a measurable cost.
    private static func validDate(_ date: Date?) -> Date? {
        guard let date = date else { return nil }
        if date == Date.distantPast { return nil }
        if date.timeIntervalSinceReferenceDate < -63_000_000_000 { return nil }
        return date
    }

    // MARK: - Membership rules

    /// Inbox: an open task in the Inbox project with no When. A When is a start
    /// date, the Someday label or the Evening label. A deadline alone is not a
    /// When, so the task stays in the Inbox.
    private static func isInInbox(_ fact: Facts, inboxProjectID: Int64?) -> Bool {
        guard let inboxID = inboxProjectID, !fact.task.done, fact.task.projectId == inboxID else { return false }
        if fact.startDay != nil { return false }
        if fact.isSomeday || fact.isEvening { return false }
        return true
    }

    /// Today: an open, non-Someday task whose start day is today or earlier, or
    /// whose deadline day is today or earlier.
    ///
    /// SPEC-UNSURE: a start date in the past keeps the task in Today (06 section 4
    /// and 07 section 6). A repeating task needs no rule of its own: Vikunja keeps
    /// a single instance whose dates advance, so it is in Today exactly when its
    /// start or due date reaches today.
    /// SPEC-UNSURE: the Someday label wins and removes a task from every list
    /// but Someday, even when its deadline is reached (07 section 8).
    private static func isInToday(_ fact: Facts, today: Date) -> Bool {
        guard !fact.task.done, !fact.isSomeday else { return false }
        if let start = fact.startDay, start <= today { return true }
        if let due = fact.deadlineDay, due <= today { return true }
        return false
    }

    /// Anytime: an open, non-Someday task that is not in the Inbox and has no
    /// start date in the future. A deadline, even a future one, does not hide it.
    ///
    /// SPEC-UNSURE: "not in Inbox" means not shown by the Inbox list, so a task
    /// of the Inbox project that was given a When is in Anytime (or Upcoming).
    /// Anytime is one flat section: grouping by project needs project data that
    /// this pure layer does not take.
    private static func isAnytime(_ fact: Facts, inboxProjectID: Int64?, today: Date) -> Bool {
        guard !fact.task.done, !fact.isSomeday else { return false }
        if isInInbox(fact, inboxProjectID: inboxProjectID) { return false }
        if let start = fact.startDay, start > today { return false }
        return true
    }

    // MARK: - Today

    /// Order: overdue, normal, evening.
    ///
    /// SPEC-UNSURE: tasks whose deadline day is before today go to a separate
    /// `.overdue` section, evening or not. A past start date alone is not
    /// overdue (06 section 4: they just stay in Today).
    /// SPEC-UNSURE: an evening task with a future start date is not in Today yet.
    /// It shows in Upcoming and moves to the evening section on its day
    /// (06 section 4, 07 section 7).
    private static func todaySections(facts: [Facts], today: Date) -> [ThingsListSection] {
        var overdue: [VTask] = []
        var normal: [VTask] = []
        var evening: [VTask] = []
        for fact in facts where isInToday(fact, today: today) {
            if let due = fact.deadlineDay, due < today {
                overdue.append(fact.task)
            } else if fact.isEvening {
                evening.append(fact.task)
            } else {
                normal.append(fact.task)
            }
        }
        var result: [ThingsListSection] = []
        result.append(contentsOf: single(id: "today.overdue", kind: .overdue, tasks: overdue))
        result.append(contentsOf: single(id: "today.normal", kind: .normal, tasks: normal))
        result.append(contentsOf: single(id: "today.evening", kind: .evening, tasks: evening))
        return result
    }

    // MARK: - Upcoming

    /// The day a task is shown at in Upcoming, nil when it is not in Upcoming.
    /// A future start date wins. Without any start date, a future deadline is
    /// used (06 section 2: a deadline-only task is also visible at its deadline).
    /// A task whose start date is today or earlier is a Today task, not Upcoming.
    private static func upcomingDay(_ fact: Facts, today: Date) -> Date? {
        guard !fact.task.done, !fact.isSomeday else { return nil }
        if let start = fact.startDay {
            return start > today ? start : nil
        }
        if let due = fact.deadlineDay, due > today {
            return due
        }
        return nil
    }

    /// One block per day for the seven days after today, then one block per
    /// month.
    ///
    /// SPEC-UNSURE: 06 section 5 says "week then month" beyond seven days. The
    /// simplest rule is used: one `.monthGroup` per calendar month, with no week
    /// level. The current month's remaining days after the seventh one form the
    /// first month group.
    private static func upcomingSections(facts: [Facts], today: Date, calendar: Calendar) -> [ThingsListSection] {
        var items: [(day: Date, task: VTask)] = []
        for fact in facts {
            if let day = upcomingDay(fact, today: today) {
                items.append((day: day, task: fact.task))
            }
        }
        items.sort { lhs, rhs in
            if lhs.day != rhs.day { return lhs.day < rhs.day }
            return inListOrder(lhs.task, rhs.task)
        }

        var result: [ThingsListSection] = []
        var currentKey: Date?
        var offsets: [Date: Int] = [:]
        for item in items {
            let offset: Int
            if let known = offsets[item.day] {
                offset = known
            } else {
                offset = calendar.dateComponents([.day], from: today, to: item.day).day ?? Int.max
                offsets[item.day] = offset
            }
            let kind: ThingsListSection.Kind
            let key: Date
            let sectionID: String
            if offset <= upcomingDayCount {
                key = item.day
                kind = .dateGroup(key)
                sectionID = "upcoming.day.\(Int(key.timeIntervalSince1970))"
            } else {
                key = monthStart(of: item.day, calendar: calendar)
                kind = .monthGroup(key)
                sectionID = "upcoming.month.\(Int(key.timeIntervalSince1970))"
            }
            if currentKey == key, !result.isEmpty {
                result[result.count - 1].tasks.append(item.task)
            } else {
                result.append(ThingsListSection(id: sectionID, kind: kind, tasks: [item.task]))
                currentKey = key
            }
        }
        return result
    }

    private static func monthStart(of date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let start = calendar.date(from: components) else { return date }
        return calendar.startOfDay(for: start)
    }

    // MARK: - Logbook

    /// When the task was completed: `doneAt`, else `updated`, nil if neither is set.
    ///
    /// SPEC-UNSURE: a done task without a usable `doneAt` falls back to its
    /// last update; with neither it goes to a trailing `.normal` section.
    private static func completionDate(_ task: VTask, calendar: Calendar) -> Date? {
        if let done = validDate(task.doneAt) { return done }
        return validDate(task.updated)
    }

    /// Done tasks (completed or cancelled), newest first, one block per day.
    private static func logbookSections(tasks: [VTask], calendar: Calendar) -> [ThingsListSection] {
        var dated: [(date: Date, task: VTask)] = []
        var undated: [VTask] = []
        for task in tasks where task.done {
            if let date = completionDate(task, calendar: calendar) {
                dated.append((date: date, task: task))
            } else {
                undated.append(task)
            }
        }
        dated.sort { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.task.id > rhs.task.id
        }

        var result: [ThingsListSection] = []
        var currentDay: Date?
        for item in dated {
            let day = calendar.startOfDay(for: item.date)
            if currentDay == day, !result.isEmpty {
                result[result.count - 1].tasks.append(item.task)
            } else {
                let sectionID = "logbook.day.\(Int(day.timeIntervalSince1970))"
                result.append(ThingsListSection(id: sectionID, kind: .dateGroup(day), tasks: [item.task]))
                currentDay = day
            }
        }
        let rest = undated.sorted { $0.id > $1.id }
        result.append(contentsOf: single(id: "logbook.undated", kind: .normal, tasks: rest))
        return result
    }

    // MARK: - Ordering and building blocks

    /// Manual order: Vikunja `position` ascending (unset last), then id.
    private static func inListOrder(_ lhs: VTask, _ rhs: VTask) -> Bool {
        let left = lhs.position ?? Double.greatestFiniteMagnitude
        let right = rhs.position ?? Double.greatestFiniteMagnitude
        if left != right { return left < right }
        return lhs.id < rhs.id
    }

    /// A one-element list holding a `.normal` section, or empty when no tasks.
    private static func single(id: String, tasks: [VTask]) -> [ThingsListSection] {
        single(id: id, kind: .normal, tasks: tasks)
    }

    private static func single(
        id: String,
        kind: ThingsListSection.Kind,
        tasks: [VTask]
    ) -> [ThingsListSection] {
        guard !tasks.isEmpty else { return [] }
        let ordered = tasks.sorted(by: inListOrder)
        return [ThingsListSection(id: id, kind: kind, tasks: ordered)]
    }
}
