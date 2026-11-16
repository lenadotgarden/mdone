import Foundation

/// One project or Area of the sidebar tree (07 sections 1 and 2).
struct ThingsProjectNode: Identifiable, Equatable {
    let project: Project
    /// `.area` or `.project`. Never `.inbox`: the Inbox is not part of the tree.
    let kind: ThingsProjectKind
    /// 0 for a root, 1 for a child of a root, and so on.
    let depth: Int
    /// The parent node id, nil for a root.
    let parentID: Int64?
    /// Children in Vikunja position order, archived ones excluded.
    let children: [ThingsProjectNode]

    var id: Int64 { project.id }
    var title: String { project.title }
    var isArea: Bool { kind == .area }
    var hasChildren: Bool { !children.isEmpty }
    var isFavorite: Bool { project.isFavorite == true }

    static func == (lhs: ThingsProjectNode, rhs: ThingsProjectNode) -> Bool {
        lhs.project.id == rhs.project.id
            && lhs.project.title == rhs.project.title
            && lhs.kind == rhs.kind
            && lhs.depth == rhs.depth
            && lhs.parentID == rhs.parentID
            && lhs.children == rhs.children
    }
}

/// One line of a nested sub-project list (Area or project screen).
struct ThingsProjectRow: Identifiable, Equatable {
    let node: ThingsProjectNode
    /// 0 for a direct child of the project on screen, 1 for its grandchildren, and so on.
    let depth: Int

    var id: Int64 { node.id }
}

/// The full project tree shown in the sidebar and the Area screens, on both platforms. Pure: `(projects, inbox id) -> tree`.
///
/// Rules (the Area rule is explicit and lives in `ThingsProjectTree.kind`):
/// 1. Pseudo-projects (id <= 0) and archived projects are left out. The live
///    children of an archived project are not: they surface at the root. The Inbox project is left out too, unless
///    it has visible children: a project holding a subtree is never hidden
///    (the Inbox id can be a guess, see `AppState.defaultProject`, and hiding a
///    guessed Inbox would hide its whole subtree).
/// 2. A project whose parent is unknown (shared project, parent not loaded),
///    archived, or whose parent chain loops is shown as a root.
/// 3. Siblings are ordered by Vikunja position, then title, then id.
/// 4. A ROOT project is an Area when it carries the `things:area` marker OR has
///    at least one visible child. A root without children and without marker
///    is a loose project. Every non-root project is a project, whatever its
///    description says, and may itself have children (deeper levels).
/// 5. Favorites stay where they are in the tree; `favorites` lists them.
struct ThingsProjectTree: Equatable {
    /// Root nodes in display order (areas and loose projects interleaved).
    let roots: [ThingsProjectNode]

    static let empty = ThingsProjectTree(roots: [])

    // MARK: - Build

    /// The tree of `projects`. Memoized on the content of the projects
    /// (`ThingsProjectTreeMemo`): the sidebar asks for it on every redraw, and
    /// rebuilding a tree of hundreds of projects each time was a visible cost.
    static func build(projects: [Project], inboxProjectID: Int64?) -> ThingsProjectTree {
        let key = ThingsProjectTreeMemo.fingerprint(projects: projects, inboxProjectID: inboxProjectID)
        if let hit = ThingsProjectTreeMemo.shared.lookup(key) { return hit }
        let built = buildUncached(projects: projects, inboxProjectID: inboxProjectID)
        ThingsProjectTreeMemo.shared.store(key, built)
        return built
    }

    /// The tree without the memo. Pure.
    static func buildUncached(projects: [Project], inboxProjectID declaredInboxID: Int64?) -> ThingsProjectTree {
        let real = projects.filter { $0.id > 0 }
        // An Inbox that holds live sub-projects stays in the tree (rule 1).
        let inboxProjectID: Int64? = {
            guard let inbox = declaredInboxID else { return nil }
            let holdsChildren = real.contains {
                $0.id != inbox && $0.parentProjectId == inbox && $0.isArchived != true
            }
            return holdsChildren ? nil : inbox
        }()
        var byID: [Int64: Project] = [:]
        for project in real where byID[project.id] == nil {
            byID[project.id] = project
        }

        func parentID(of project: Project) -> Int64? {
            let raw = project.parentProjectId ?? 0
            if raw <= 0 || raw == project.id { return nil }
            if let inbox = inboxProjectID, raw == inbox { return nil }
            guard let parent = byID[raw] else { return nil }
            // An archived parent is hidden, its live children are not: they surface at the root.
            if parent.isArchived == true { return nil }
            return raw
        }

        var visible: [Project] = []
        var seen = Set<Int64>()
        for project in real {
            if seen.contains(project.id) { continue }
            seen.insert(project.id)
            if project.isArchived == true { continue }
            if let inbox = inboxProjectID, project.id == inbox { continue }
            visible.append(project)
        }

        var childrenByParent: [Int64: [Project]] = [:]
        var rootProjects: [Project] = []
        for project in visible {
            if let pid = parentID(of: project) {
                childrenByParent[pid, default: []].append(project)
            } else {
                rootProjects.append(project)
            }
        }
        rootProjects.sort(by: ordersBefore)

        var placed = Set<Int64>()
        var roots: [ThingsProjectNode] = []
        for project in rootProjects {
            roots.append(makeNode(project, depth: 0, parent: nil, childrenByParent: childrenByParent, placed: &placed))
        }
        // Projects in a parent loop are not reachable from any root: show them as roots.
        let leftovers = visible.filter { !placed.contains($0.id) }.sorted(by: ordersBefore)
        for project in leftovers where !placed.contains(project.id) {
            roots.append(makeNode(project, depth: 0, parent: nil, childrenByParent: childrenByParent, placed: &placed))
        }
        return ThingsProjectTree(roots: roots)
    }

    private static func makeNode(
        _ project: Project,
        depth: Int,
        parent: Int64?,
        childrenByParent: [Int64: [Project]],
        placed: inout Set<Int64>
    ) -> ThingsProjectNode {
        placed.insert(project.id)
        let candidates = (childrenByParent[project.id] ?? []).filter { !placed.contains($0.id) }.sorted(by: ordersBefore)
        var children: [ThingsProjectNode] = []
        for candidate in candidates where !placed.contains(candidate.id) {
            children.append(
                makeNode(candidate, depth: depth + 1, parent: project.id, childrenByParent: childrenByParent, placed: &placed)
            )
        }
        return ThingsProjectNode(
            project: project,
            kind: kind(of: project, depth: depth, hasVisibleChildren: !children.isEmpty),
            depth: depth,
            parentID: parent,
            children: children
        )
    }

    /// The Area rule. A root is an Area when it has the marker or visible children.
    static func kind(of project: Project, depth: Int, hasVisibleChildren: Bool) -> ThingsProjectKind {
        if depth > 0 { return .project }
        if ThingsProjectMeta.hasAreaMarker(project.description) || hasVisibleChildren { return .area }
        return .project
    }

    private static func ordersBefore(_ lhs: Project, _ rhs: Project) -> Bool {
        let lp = lhs.position ?? 0
        let rp = rhs.position ?? 0
        if lp != rp { return lp < rp }
        let byTitle = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if byTitle != .orderedSame { return byTitle == .orderedAscending }
        return lhs.id < rhs.id
    }

    // MARK: - Reading

    /// Root projects that are not Areas, in display order.
    var looseProjects: [ThingsProjectNode] { roots.filter { !$0.isArea } }

    /// Root Areas in display order.
    var areas: [ThingsProjectNode] { roots.filter { $0.isArea } }

    /// Every node, depth first, parents before children.
    var allNodes: [ThingsProjectNode] {
        var result: [ThingsProjectNode] = []
        for root in roots { ThingsProjectTree.append(root, to: &result) }
        return result
    }

    private static func append(_ node: ThingsProjectNode, to result: inout [ThingsProjectNode]) {
        result.append(node)
        for child in node.children { append(child, to: &result) }
    }

    /// Favorite projects, in tree order.
    var favorites: [ThingsProjectNode] { allNodes.filter { $0.isFavorite } }

    func node(id: Int64) -> ThingsProjectNode? {
        allNodes.first { $0.id == id }
    }

    /// The siblings of a parent: its children, or the roots for nil.
    func siblings(ofParent parentID: Int64?) -> [ThingsProjectNode] {
        guard let parentID = parentID else { return roots }
        return node(id: parentID)?.children ?? []
    }

    /// The descendants of `id` as rows, depth first, relative to `id` (a direct
    /// child has depth 0), skipping everything below a collapsed node. This is the
    /// nested sub-project list shown at the top of an Area or project screen.
    func descendantRows(of id: Int64, collapsed: Set<Int64>) -> [ThingsProjectRow] {
        guard let start = node(id: id) else { return [] }
        var result: [ThingsProjectRow] = []
        for child in start.children {
            ThingsProjectTree.appendRows(child, depth: 0, collapsed: collapsed, to: &result)
        }
        return result
    }

    private static func appendRows(
        _ node: ThingsProjectNode,
        depth: Int,
        collapsed: Set<Int64>,
        to result: inout [ThingsProjectRow]
    ) {
        result.append(ThingsProjectRow(node: node, depth: depth))
        if collapsed.contains(node.id) { return }
        for child in node.children {
            appendRows(child, depth: depth + 1, collapsed: collapsed, to: &result)
        }
    }

    /// Ids of nodes that have children, to collapse them all.
    var expandableIDs: [Int64] { allNodes.filter { $0.hasChildren }.map { $0.id } }

    /// Ids of every node below `id` (not including `id`).
    func descendantIDs(of id: Int64) -> Set<Int64> {
        guard let start = node(id: id) else { return [] }
        var result = Set<Int64>()
        var stack = start.children
        while let next = stack.popLast() {
            result.insert(next.id)
            stack.append(contentsOf: next.children)
        }
        return result
    }

    /// Ids of the ancestors of `id`, nearest first.
    func ancestorIDs(of id: Int64) -> [Int64] {
        var result: [Int64] = []
        var current = node(id: id)?.parentID
        var steps = 0
        while let pid = current, steps <= allNodes.count {
            result.append(pid)
            current = node(id: pid)?.parentID
            steps += 1
        }
        return result
    }

    /// Nodes in display order, skipping everything below a collapsed node.
    func visibleNodes(collapsed: Set<Int64>) -> [ThingsProjectNode] {
        var result: [ThingsProjectNode] = []
        for root in looseProjects { ThingsProjectTree.appendVisible(root, collapsed: collapsed, to: &result) }
        for root in areas { ThingsProjectTree.appendVisible(root, collapsed: collapsed, to: &result) }
        return result
    }

    /// `node` followed by its descendants, skipping everything below a collapsed node.
    func visibleSubtree(of node: ThingsProjectNode, collapsed: Set<Int64>) -> [ThingsProjectNode] {
        var result: [ThingsProjectNode] = []
        ThingsProjectTree.appendVisible(node, collapsed: collapsed, to: &result)
        return result
    }

    private static func appendVisible(_ node: ThingsProjectNode, collapsed: Set<Int64>, to result: inout [ThingsProjectNode]) {
        result.append(node)
        if collapsed.contains(node.id) { return }
        for child in node.children { appendVisible(child, collapsed: collapsed, to: &result) }
    }

    /// Whether moving `projectID` under `parentID` (nil = top level) is legal:
    /// not under itself or a descendant, and a real change.
    func canMove(projectID: Int64, toParent parentID: Int64?) -> Bool {
        guard let current = node(id: projectID) else { return false }
        if let target = parentID {
            if target == projectID { return false }
            if descendantIDs(of: projectID).contains(target) { return false }
            if node(id: target) == nil { return false }
        }
        return current.parentID != parentID
    }
}
