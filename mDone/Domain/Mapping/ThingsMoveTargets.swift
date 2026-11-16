import Foundation

/// One line of the Move popover (Shift Cmd M, spec 04 section 4).
struct ThingsMoveTarget: Identifiable, Equatable {
    enum Kind: Equatable {
        case inbox
        /// "No Area": a project goes to the top level.
        case topLevel
        case area
        case project
    }

    let kind: Kind
    /// The Vikunja project id to move into. Nil for `.topLevel`.
    let projectID: Int64?
    let title: String
    /// Ancestor titles joined with " / ", empty for a root. Shown when searching.
    let path: String
    /// Indentation level in the unfiltered list.
    let depth: Int

    var id: String {
        switch kind {
        case .inbox: return "inbox"
        case .topLevel: return "top"
        case .area, .project: return "p\(projectID ?? 0)"
        }
    }
}

/// Pure builder of the Move popover lines.
enum ThingsMoveTargets {
    /// Targets for a to-do: the Inbox, then the whole tree (Areas hold to-dos too).
    /// An empty `query` keeps the tree order and depth; a query flattens and filters.
    static func forTodo(
        tree: ThingsProjectTree,
        inboxProject: Project?,
        query: String
    ) -> [ThingsMoveTarget] {
        var result: [ThingsMoveTarget] = []
        if let inbox = inboxProject {
            result.append(ThingsMoveTarget(kind: .inbox, projectID: inbox.id, title: inboxTitle, path: "", depth: 0))
        }
        result.append(contentsOf: treeTargets(tree: tree, excluding: [], query: query))
        return filter(result, query: query)
    }

    /// Targets for a project: "No Area" (top level), then every node except the
    /// project itself and its descendants (no cycles).
    static func forProject(
        tree: ThingsProjectTree,
        projectID: Int64,
        query: String
    ) -> [ThingsMoveTarget] {
        var excluded = tree.descendantIDs(of: projectID)
        excluded.insert(projectID)
        var result: [ThingsMoveTarget] = []
        result.append(ThingsMoveTarget(kind: .topLevel, projectID: nil, title: topLevelTitle, path: "", depth: 0))
        result.append(contentsOf: treeTargets(tree: tree, excluding: excluded, query: query))
        return filter(result, query: query)
    }

    static let inboxTitle = "Inbox"
    static let topLevelTitle = "No Area"

    private static func treeTargets(
        tree: ThingsProjectTree,
        excluding excluded: Set<Int64>,
        query: String
    ) -> [ThingsMoveTarget] {
        var result: [ThingsMoveTarget] = []
        // Loose projects first, then Areas, the order of the sidebar.
        for root in tree.looseProjects + tree.areas {
            collect(root, path: [], excluding: excluded, into: &result)
        }
        return result
    }

    private static func collect(
        _ node: ThingsProjectNode,
        path: [String],
        excluding excluded: Set<Int64>,
        into result: inout [ThingsMoveTarget]
    ) {
        if excluded.contains(node.id) { return }
        result.append(
            ThingsMoveTarget(
                kind: node.isArea ? .area : .project,
                projectID: node.id,
                title: node.title,
                path: path.joined(separator: " / "),
                depth: node.depth
            )
        )
        for child in node.children {
            collect(child, path: path + [node.title], excluding: excluded, into: &result)
        }
    }

    /// Keeps the targets whose title or path contains every word of `query`,
    /// ignoring case and accents. Empty query: unchanged.
    static func filter(_ targets: [ThingsMoveTarget], query: String) -> [ThingsMoveTarget] {
        let words = query
            .split(whereSeparator: { $0.isWhitespace })
            .map { String($0) }
        if words.isEmpty { return targets }
        return targets.filter { target in
            let haystack = target.title + " " + target.path
            return words.allSatisfy { word in
                haystack.range(of: word, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
    }

    /// Index of the row to highlight after the list changed: stays in range.
    static func clampedIndex(_ index: Int, count: Int) -> Int {
        if count <= 0 { return 0 }
        return min(max(index, 0), count - 1)
    }
}
