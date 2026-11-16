import Foundation

/// Progress of a checklist (the subtasks of a to-do, 07 section 5).
struct ThingsChecklistProgress: Equatable {
    let done: Int
    let total: Int

    var isEmpty: Bool { total == 0 }

    /// All items done. False for an empty checklist.
    var isComplete: Bool { total > 0 && done == total }

    /// 0 to 1, 0 for an empty checklist.
    var fraction: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    /// Plain "done/total" text such as "2/5".
    var label: String { "\(done)/\(total)" }
}

enum ThingsChecklist {
    /// Progress over `items`.
    static func progress(of items: [VTask]) -> ThingsChecklistProgress {
        ThingsChecklistProgress(done: items.filter { $0.done }.count, total: items.count)
    }

    /// Progress over the direct subtasks of `task`. Nil when it has none.
    static func progress(of task: VTask) -> ThingsChecklistProgress? {
        let items = task.subtasks
        if items.isEmpty { return nil }
        return progress(of: items)
    }

    /// Whether `task` is a checklist item: a plain step of a parent to-do. Such
    /// tasks are hidden from the lists (07 section 5), because the parent
    /// already shows them.
    ///
    /// Only a plain step counts. A Vikunja subtask is a full task, and users
    /// who build real subtasks (in another project than the parent, with their
    /// own dates or labels, or still open under a finished parent) would see
    /// them vanish from every list if every task with a parent were hidden.
    /// So a subtask stays visible as a to-do of its own when any of these holds:
    /// - it lives in another project than its parent,
    /// - it has a start date, a deadline or a label (Things forbids all three
    ///   on a checklist item, so the user meant a real to-do),
    /// - it is still open while its parent is done.
    static func isChecklistItem(_ task: VTask) -> Bool {
        let parents = task.parentTasks
        if parents.isEmpty { return false }
        if hasDate(task.startDate) || hasDate(task.dueDate) { return false }
        if let labels = task.labels, !labels.isEmpty { return false }
        return parents.contains { parent in
            parent.projectId == task.projectId && (task.done || !parent.done)
        }
    }

    /// A date that is set: not nil and not Vikunja's zero date (year 1).
    private static func hasDate(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        // Anything before about the year 4 is the zero date or garbage.
        return date.timeIntervalSinceReferenceDate > -63_000_000_000
    }

    /// `tasks` without the checklist items.
    static func topLevel(_ tasks: [VTask]) -> [VTask] {
        tasks.filter { !isChecklistItem($0) }
    }

    /// The checklist items of `task` in display order: position, then id.
    static func items(of task: VTask) -> [VTask] {
        task.subtasks.sorted { lhs, rhs in
            let lp = lhs.position ?? 0
            let rp = rhs.position ?? 0
            if lp != rp { return lp < rp }
            return lhs.id < rhs.id
        }
    }
}
