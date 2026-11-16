import Foundation

/// Which side of a sibling a dragged project lands on.
enum ThingsDropEdge: Equatable {
    case before
    case after
}

/// Where a project goes after a drop between two rows: its parent and the
/// Vikunja `position` values to write.
struct ThingsProjectPlacement: Equatable {
    struct Update: Equatable {
        let projectID: Int64
        let position: Double
    }

    let projectID: Int64
    /// The new parent, nil for the top level.
    let parentID: Int64?
    /// Positions to write, the moved project first. Usually one entry; when the
    /// siblings share positions (a fresh account has all zeros) every sibling
    /// whose position changes is listed so the saved order is exact.
    let updates: [Update]
}

/// Sibling ordering of projects, pure. Vikunja orders projects by `position`
/// (float, ascending); a project dropped between two siblings gets a position
/// between theirs, the same way to-dos do (`TaskPositioning`).
enum ThingsProjectOrdering {
    /// Gap between renumbered siblings. Same as the to-do gap.
    static let renumberGap: Double = TaskPositioning.endGap

    /// The placement for dropping `projectID` before or after the sibling `targetID`.
    /// Nil when the drop is illegal (self, a descendant of the project, a loop) or
    /// changes nothing, or when it would mix an Area and a loose project at the top
    /// level (the sidebar shows loose projects first, then Areas).
    static func placement(
        tree: ThingsProjectTree,
        projectID: Int64,
        relativeTo targetID: Int64,
        edge: ThingsDropEdge
    ) -> ThingsProjectPlacement? {
        guard projectID != targetID else { return nil }
        guard let moving = tree.node(id: projectID), let target = tree.node(id: targetID) else { return nil }
        if tree.descendantIDs(of: projectID).contains(targetID) { return nil }

        let parentID = target.parentID
        var siblings = tree.siblings(ofParent: parentID)
        if parentID == nil {
            let movingWillBeArea = ThingsProjectTree.kind(
                of: moving.project, depth: 0, hasVisibleChildren: moving.hasChildren
            ) == .area
            if target.isArea != movingWillBeArea { return nil }
            siblings = siblings.filter { $0.isArea == movingWillBeArea }
        }

        let others = siblings.filter { $0.id != projectID }
        guard let targetIndex = others.firstIndex(where: { $0.id == targetID }) else { return nil }
        let insertIndex = edge == .before ? targetIndex : targetIndex + 1

        // No change: same parent and same place among the siblings.
        if parentID == moving.parentID {
            var reordered = others
            reordered.insert(moving, at: insertIndex)
            if reordered.map({ $0.id }) == siblings.map({ $0.id }) { return nil }
        }

        var beforePosition: Double?
        if insertIndex > 0 { beforePosition = others[insertIndex - 1].project.position ?? 0 }
        var afterPosition: Double?
        if insertIndex < others.count { afterPosition = others[insertIndex].project.position ?? 0 }

        if let single = singlePosition(before: beforePosition, after: afterPosition) {
            return ThingsProjectPlacement(
                projectID: projectID,
                parentID: parentID,
                updates: [ThingsProjectPlacement.Update(projectID: projectID, position: single)]
            )
        }

        // Neighbours share a position (or none is left between them): renumber.
        var ordered = others
        ordered.insert(moving, at: insertIndex)
        var updates: [ThingsProjectPlacement.Update] = []
        for (index, node) in ordered.enumerated() {
            let position = Double(index + 1) * renumberGap
            if node.id == projectID {
                updates.insert(ThingsProjectPlacement.Update(projectID: node.id, position: position), at: 0)
            } else if node.project.position != position {
                updates.append(ThingsProjectPlacement.Update(projectID: node.id, position: position))
            }
        }
        return ThingsProjectPlacement(projectID: projectID, parentID: parentID, updates: updates)
    }

    /// A position strictly between the neighbours, nil when there is no room.
    static func singlePosition(before: Double?, after: Double?) -> Double? {
        switch (before, after) {
        case (nil, nil):
            return renumberGap
        case let (nil, after?):
            return after > 0 ? after / 2 : after - renumberGap
        case let (before?, nil):
            return before + renumberGap
        case let (before?, after?):
            guard before < after else { return nil }
            let middle = before + (after - before) / 2
            return (middle > before && middle < after) ? middle : nil
        }
    }

    /// Whether the drop is legal, for the hover highlight.
    static func canPlace(
        tree: ThingsProjectTree,
        projectID: Int64,
        relativeTo targetID: Int64,
        edge: ThingsDropEdge
    ) -> Bool {
        placement(tree: tree, projectID: projectID, relativeTo: targetID, edge: edge) != nil
    }
}

/// Where the pointer is on a row while a project hovers it: the top edge means
/// "before", the bottom edge "after", the middle "into" (re-parent).
enum ThingsRowDropZone: Equatable {
    case before
    case into
    case after

    /// - Parameters:
    ///   - y: pointer height inside the row, 0 at the top.
    ///   - height: row height.
    ///   - allowsEdges: false for rows that only accept "into" (Areas for a to-do).
    static func zone(y: Double, height: Double, allowsEdges: Bool) -> ThingsRowDropZone {
        guard allowsEdges, height > 0 else { return .into }
        let edge = min(height * 0.28, 8)
        if y < edge { return .before }
        if y > height - edge { return .after }
        return .into
    }

    var edge: ThingsDropEdge? {
        switch self {
        case .before: return ThingsDropEdge.before
        case .after: return ThingsDropEdge.after
        case .into: return nil
        }
    }
}

/// What dropping a project on a row means.
enum ThingsProjectDropOutcome: Equatable {
    /// Becomes a child of `parentID` (dropped on the middle of a row).
    case reparent(projectID: Int64, parentID: Int64)
    /// Lands between two siblings (dropped on the top or bottom edge of a row).
    case place(ThingsProjectPlacement)
}

/// Decides what a project dropped on a row does. One place for the hover feedback and the
/// drop, on the sidebar and on the sub-project list of an Area screen.
enum ThingsProjectDropResolver {
    static func outcome(
        tree: ThingsProjectTree,
        projectID: Int64,
        targetID: Int64,
        zone: ThingsRowDropZone
    ) -> ThingsProjectDropOutcome? {
        if let edge = zone.edge {
            guard let placement = ThingsProjectOrdering.placement(
                tree: tree, projectID: projectID, relativeTo: targetID, edge: edge
            ) else { return nil }
            return .place(placement)
        }
        guard tree.canMove(projectID: projectID, toParent: targetID) else { return nil }
        return .reparent(projectID: projectID, parentID: targetID)
    }

    /// The zone to show and use: the asked one when it is legal, else "into" when that is
    /// legal (a drop on the edge of a row that cannot be a sibling nests instead), else nil.
    static func resolvedZone(
        tree: ThingsProjectTree,
        projectID: Int64,
        targetID: Int64,
        zone: ThingsRowDropZone
    ) -> ThingsRowDropZone? {
        if outcome(tree: tree, projectID: projectID, targetID: targetID, zone: zone) != nil { return zone }
        if zone != .into,
           outcome(tree: tree, projectID: projectID, targetID: targetID, zone: .into) != nil {
            return .into
        }
        return nil
    }
}

/// Normalizes the title typed for a new project or Area. The emoji of a title is part of
/// the text (Things shows it as the Area icon, mac-dark-01.png): a leading emoji gets one
/// space after it, spaces are trimmed and runs of spaces collapse.
enum ThingsProjectTitle {
    static func normalized(_ raw: String) -> String {
        let words = raw.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
        var text = words.joined(separator: " ")
        guard let first = text.first, isEmoji(first), text.count > 1 else { return text }
        let afterFirst = text.index(after: text.startIndex)
        if text[afterFirst] != " " {
            text.insert(" ", at: afterFirst)
        }
        return text
    }

    /// The leading emoji of a title, nil when it has none.
    static func leadingEmoji(of title: String) -> String? {
        guard let first = title.trimmingCharacters(in: .whitespaces).first, isEmoji(first) else { return nil }
        return String(first)
    }

    private static func isEmoji(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        if scalar.properties.isEmojiPresentation { return true }
        // Text-style symbols such as digits are "emoji" too: only count the ones above U+00FF
        // that carry the emoji flag and a variation selector or a pictographic range.
        return scalar.properties.isEmoji && scalar.value > 0x238C
    }
}
