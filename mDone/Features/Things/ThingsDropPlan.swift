import Foundation

// What a drop of a to-do on the list means, and how the screen shows it before the
// server answers (docs/things-spec/08-drag-and-drop.md).

/// A section of the screen with its to-dos in the order shown.
struct ThingsSectionTasks: Equatable {
    let id: String
    let tasks: [VTask]
}

/// A to-do moved into another section: its When changes (`ThingsDropRules.when`) and it
/// gets a position among the to-dos of the target section.
struct ThingsSectionMovePlan: Equatable {
    let fromSectionID: String
    let toSectionID: String
    let task: VTask
    let when: ThingsWhen
    let position: Double
    /// The source section without the moved to-do, in order.
    let fromIDs: [Int64]
    /// The target section with the moved to-do in its place.
    let toReordered: [VTask]
}

enum ThingsDropPlan: Equatable {
    /// A move inside one section.
    case reorder(ThingsReorderPlan)
    /// A move into another section.
    case changeSection(ThingsSectionMovePlan)

    /// The plan for dropping `movingID` at `slot`. Nil when the to-do or the section is
    /// unknown, when the drop changes nothing, or when the two sections have no meaningful
    /// move between them.
    static func make(slot: ThingsDropSlot, movingID: Int64, sections: [ThingsSectionTasks]) -> ThingsDropPlan? {
        guard let source = sections.first(where: { section in section.tasks.contains(where: { $0.id == movingID }) }),
              let target = sections.first(where: { $0.id == slot.sectionID }),
              let task = source.tasks.first(where: { $0.id == movingID }) else { return nil }

        if source.id == target.id {
            guard let plan = ThingsReorder.plan(
                sectionID: source.id, tasks: source.tasks, movingID: movingID, toOffset: slot.index
            ) else { return nil }
            return .reorder(plan)
        }

        guard let when = ThingsDropRules.when(from: source.id, to: target.id) else { return nil }
        let index = min(max(slot.index, 0), target.tasks.count)
        let position = TaskPositioning.position(forInserting: task, at: index, into: target.tasks)
        var reordered = target.tasks
        reordered.insert(task, at: index)
        return .changeSection(ThingsSectionMovePlan(
            fromSectionID: source.id,
            toSectionID: target.id,
            task: task,
            when: when,
            position: position,
            fromIDs: source.tasks.filter { $0.id != movingID }.map { $0.id },
            toReordered: reordered
        ))
    }

    /// The task ids each touched section shows until the server answers.
    var overrides: [String: [Int64]] {
        switch self {
        case .reorder(let plan):
            return [plan.sectionID: plan.reorderedIDs]
        case .changeSection(let move):
            return [
                move.fromSectionID: move.fromIDs,
                move.toSectionID: move.toReordered.map { $0.id }
            ]
        }
    }
}

/// Applies the optimistic orders to the rows of a screen, across sections.
enum ThingsDropArrangement {
    /// The rows of each section (same count and order as `sections`) with `overrides`
    /// applied. An override is the full list of task ids a section shows, in order; it can
    /// pull in a row that belongs to another section (a to-do moved to This Evening) and the
    /// section it left loses it. A row the override does not mention stays at the end of its
    /// section, so a to-do that arrives from the server meanwhile is not lost.
    static func rows(
        for sections: [(id: String, rows: [ThingsDisplayRow])],
        overrides: [String: [Int64]]
    ) -> [[ThingsDisplayRow]] {
        var claimedBy: [String: String] = [:]
        for (sectionID, order) in overrides {
            for id in order { claimedBy[String(id)] = sectionID }
        }
        var pool: [String: ThingsDisplayRow] = [:]
        for section in sections {
            for row in section.rows { pool[row.id] = row }
        }
        return sections.map { (section: (id: String, rows: [ThingsDisplayRow])) -> [ThingsDisplayRow] in
            guard let order = overrides[section.id] else {
                return section.rows.filter { claimedBy[$0.id] == nil }
            }
            var candidates = section.rows.filter { row in
                let owner = claimedBy[row.id]
                return owner == nil || owner == section.id
            }
            let known = Set(candidates.map { $0.id })
            for id in order where !known.contains(String(id)) {
                if let row = pool[String(id)] { candidates.append(row) }
            }
            return ThingsReorder.ordered(candidates, by: order)
        }
    }
}
