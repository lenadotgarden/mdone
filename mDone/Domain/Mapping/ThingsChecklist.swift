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

    /// Whether `task` is a checklist item, i.e. has a parent task. Such tasks
    /// are hidden from the lists.
    static func isChecklistItem(_ task: VTask) -> Bool {
        task.hasParentTask
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
