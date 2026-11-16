import Foundation

/// Memoizes what the Things lists derive from the task array, so a redraw does
/// not redo it.
///
/// Computing the six lists, their counts and the per-project progress costs
/// one pass over every task plus a few sorts. The views read those values on
/// every body evaluation (the sidebar alone reads a badge per list and a
/// progress per project), so without a memo the cost is paid many times per
/// frame. The memo is keyed by what the result depends on: the task array
/// (through `tasksRevision`, which `AppState` bumps on every change), the Inbox
/// project, the calendar day and the calendar. Anything else cannot change the
/// result, because the builders only compare calendar days.
///
/// One entry is kept. Not thread safe: use it from the main actor, like the
/// view models that read it.
final class ThingsListsCache {
    /// Everything the key must match for an entry to be reused.
    struct Key: Equatable {
        let tasksRevision: UInt64
        let inboxProjectID: Int64?
        let day: Date
        let calendarID: String
    }

    /// The derived data of one key.
    struct Entry {
        /// Bumped on every rebuild, so a consumer can memoize on top of this.
        let generation: UInt64
        let key: Key
        /// The tasks the lists are built from: checklist items left out.
        let listable: [VTask]
        let snapshot: ThingsListSnapshot
        /// Finished share of the top level to-dos of each project, 0 to 1.
        let progressByProject: [Int64: Double]
    }

    private var current: Entry?
    private var nextGeneration: UInt64 = 0

    /// How many times an entry was built. Read by tests to prove reuse.
    private(set) var buildCount = 0

    init() {}

    /// The entry for these inputs, built only when they differ from the last call.
    func entry(
        tasks: [VTask],
        tasksRevision: UInt64,
        inboxProjectID: Int64?,
        now: Date,
        calendar: Calendar
    ) -> Entry {
        let key = Key(
            tasksRevision: tasksRevision,
            inboxProjectID: inboxProjectID,
            day: calendar.startOfDay(for: now),
            calendarID: "\(calendar.identifier)|\(calendar.timeZone.identifier)"
        )
        if let current, current.key == key {
            return current
        }
        let built = Self.build(tasks: tasks, key: key, now: now, calendar: calendar, generation: nextGeneration)
        nextGeneration &+= 1
        buildCount += 1
        current = built
        return built
    }

    /// Drops the entry, so the next read rebuilds.
    func invalidate() {
        current = nil
    }

    /// Pure core of `entry`, also used directly by tests and benchmarks.
    static func build(
        tasks: [VTask],
        key: Key,
        now: Date,
        calendar: Calendar,
        generation: UInt64 = 0
    ) -> Entry {
        let listable = ThingsChecklist.topLevel(tasks)
        let snapshot = ThingsListBuilder.snapshot(
            tasks: listable, inboxProjectID: key.inboxProjectID, now: now, calendar: calendar
        )
        return Entry(
            generation: generation,
            key: key,
            listable: listable,
            snapshot: snapshot,
            progressByProject: progress(of: listable)
        )
    }

    /// Done over all top level to-dos of each project, in one pass.
    static func progress(of tasks: [VTask]) -> [Int64: Double] {
        var totals: [Int64: Int] = [:]
        var finished: [Int64: Int] = [:]
        for task in tasks {
            totals[task.projectId, default: 0] += 1
            if task.done { finished[task.projectId, default: 0] += 1 }
        }
        var result: [Int64: Double] = [:]
        result.reserveCapacity(totals.count)
        for (project, total) in totals where total > 0 {
            result[project] = Double(finished[project] ?? 0) / Double(total)
        }
        return result
    }
}
