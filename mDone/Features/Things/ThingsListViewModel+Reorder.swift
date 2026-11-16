import Foundation

// Manual order of to-dos (docs/things-spec/04-macos-screens.md section 10, 05-macos-shortcuts.md "Deplacer").
// The order is persisted by the existing Vikunja position mechanism:
// `TaskPositioning` works the number out, `AppState.moveTask(_:toPosition:newOrder:)`
// sends it to the list view of the task's project and refetches.
//
// Lists already read it back: `ThingsListBuilder` sorts a section by `position`
// ascending (Today, Anytime, Inbox...), and `AppState.tasksForProject` follows the
// project's cached view order (projects). Positions are per project view, so in a
// list that mixes projects (Today) a to-do gets a number between the numbers of its
// new neighbours: that is consistent for the sort, even if the numbers of two
// projects were never meant to be compared.

/// What a move does: the task, the position to send, and the section in its new order.
struct ThingsReorderPlan: Equatable {
    /// The section the move happens in (a move into another section is a
    /// `ThingsSectionMovePlan`, see ThingsDropPlan.swift).
    let sectionID: String
    let task: VTask
    let position: Double
    /// The tasks of the section in their new order.
    let reordered: [VTask]

    var reorderedIDs: [Int64] { reordered.map { $0.id } }
}

/// Pure helpers behind drag and drop and the Cmd Opt arrow keys.
enum ThingsReorder {
    /// The plan for dropping the task `movingID` at `destination`, an offset in the
    /// pre-move indexing of `tasks` (SwiftUI `onMove` convention). Nil when the task
    /// is unknown or the drop changes nothing.
    static func plan(
        sectionID: String,
        tasks: [VTask],
        movingID: Int64,
        toOffset destination: Int
    ) -> ThingsReorderPlan? {
        guard let from = tasks.firstIndex(where: { $0.id == movingID }) else { return nil }
        let clamped = min(max(destination, 0), tasks.count)
        guard let move = TaskPositioning.move(tasks, fromOffsets: IndexSet(integer: from), toOffset: clamped) else {
            return nil
        }
        return ThingsReorderPlan(
            sectionID: sectionID,
            task: move.task,
            position: move.position,
            reordered: move.reordered
        )
    }

    /// The plan for moving a task `step` places (negative is up). Nil at the ends of the
    /// section.
    static func plan(
        sectionID: String,
        tasks: [VTask],
        movingID: Int64,
        by step: Int
    ) -> ThingsReorderPlan? {
        guard step != 0, let from = tasks.firstIndex(where: { $0.id == movingID }) else { return nil }
        let finalIndex = from + step
        guard finalIndex >= 0, finalIndex < tasks.count else { return nil }
        return plan(sectionID: sectionID, tasks: tasks, movingID: movingID, toOffset: destinationOffset(from: from, finalIndex: finalIndex))
    }

    /// Converts "the task ends at `finalIndex`" to the `toOffset` of `move(fromOffsets:)`.
    static func destinationOffset(from: Int, finalIndex: Int) -> Int {
        finalIndex > from ? finalIndex + 1 : finalIndex
    }

    /// `rows` sorted by `order` (task ids). Rows missing from `order` keep their place at
    /// the end. A nil or empty order returns `rows` unchanged.
    static func ordered(_ rows: [ThingsDisplayRow], by order: [Int64]?) -> [ThingsDisplayRow] {
        guard let order = order, !order.isEmpty else { return rows }
        var rank: [String: Int] = [:]
        for (index, id) in order.enumerated() {
            rank[String(id)] = index
        }
        let indexed = rows.enumerated().map { (offset: $0.offset, row: $0.element) }
        let sorted = indexed.sorted { left, right in
            let l = rank[left.row.id] ?? (order.count + left.offset)
            let r = rank[right.row.id] ?? (order.count + right.offset)
            return l < r
        }
        return sorted.map { $0.row }
    }
}

extension ThingsListViewModel {
    /// Sends a move to the server through `AppState.moveTask`. Returns true on success.
    ///
    /// `newOrder` is left nil on purpose: a section of a screen can be a subset of its
    /// project (Upcoming and Someday groups), and a partial order in the project cache
    /// would push the other to-dos to the end until the refetch. The screen keeps the
    /// dropped order itself while this call runs (`ThingsMacTodoList.orderOverride`),
    /// then `moveTask` refetches the view and the server order takes over.
    ///
    /// - Parameter appState: the `AppState` of the window (the view model keeps its own private).
    @MainActor
    @discardableResult
    func commitReorder(_ plan: ThingsReorderPlan, appState: AppState) async -> Bool {
        await appState.moveTask(plan.task, toPosition: plan.position)
    }

    /// Runs the plan of a drop. A move into another section first changes the When of the
    /// to-do (`schedule`: start date and reserved labels), then sends its position among
    /// the to-dos of the target section. Returns true when the position was saved.
    @MainActor
    @discardableResult
    func commitDrop(_ plan: ThingsDropPlan, appState: AppState) async -> Bool {
        switch plan {
        case .reorder(let reorder):
            return await commitReorder(reorder, appState: appState)
        case .changeSection(let move):
            await schedule(move.task, when: move.when)
            return await appState.moveTask(move.task, toPosition: move.position)
        }
    }
}
