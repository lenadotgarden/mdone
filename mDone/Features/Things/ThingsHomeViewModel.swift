import Foundation

/// View model of the Home screen (spec 02 section 1). A facade over `AppState`.
@Observable
@MainActor
final class ThingsHomeViewModel {
    private let appState: AppState
    /// Gives the counts and the progress, which the list view model already computes.
    private let lists: ThingsListViewModel

    init(appState: AppState) {
        self.appState = appState
        self.lists = ThingsListViewModel(list: .inbox, appState: appState)
    }

    // MARK: - Reading

    /// Counter shown next to a list. Spec 02 section 1: Inbox and Today only,
    /// nothing when zero.
    func badge(for list: ThingsList) -> Int? {
        guard list == .inbox || list == .today else { return nil }
        let count = lists.count(for: list)
        return count > 0 ? count : nil
    }

    private var inboxProjectID: Int64? { lists.inboxProjectID }

    /// The full project tree (Areas, projects, any depth). Same builder as the Mac
    /// sidebar, so both platforms show the same hierarchy.
    var tree: ThingsProjectTree {
        ThingsProjectTree.build(projects: appState.projects, inboxProjectID: inboxProjectID)
    }

    /// Share of finished to-dos of a project, 0 for an Area or an empty project.
    func progress(of node: ThingsProjectNode) -> Double {
        node.isArea ? 0 : lists.progress(ofProject: node.id)
    }

    /// Open to-dos directly in a project (the badge of a sub-project row).
    func openCount(of node: ThingsProjectNode) -> Int {
        appState.tasksForProject(node.id).filter { !$0.done }.count
    }

    /// Ids of the folded projects, read so views redraw when it changes.
    var collapsedIDs: Set<Int64> { appState.collapsedProjectIDs }

    /// Whether the children of a project are folded.
    func isFolded(_ id: Int64) -> Bool {
        !appState.isProjectExpanded(id)
    }

    func toggleFold(_ id: Int64) {
        appState.toggleProjectFold(id)
    }

    func setAllExpanded(_ expanded: Bool) {
        appState.setAllProjectsExpanded(expanded, tree: tree)
    }

    /// The parent a new project is created under when the caller names none: the
    /// Area or project on screen. Set by the screens, nil on a built-in list.
    var parentForNewProject: Int64?

    /// Open to-dos whose title contains `query`, for the search field (a light
    /// stand-in for Quick Find).
    func search(_ query: String) -> [ThingsDisplayRow] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return [] }
        let matches = ThingsChecklist.topLevel(appState.tasks).filter { task in
            !task.done && task.title.localizedCaseInsensitiveContains(needle)
        }
        let section = ThingsListSection(id: "search", kind: .normal, tasks: matches)
        let mapped = ThingsRowMapper.displaySections(
            [section], list: nil, pendingDone: [], now: Date(), calendar: Calendar.current
        )
        return mapped.first?.rows ?? []
    }

    // MARK: - Actions

    func refresh() async {
        await appState.refreshAll()
    }

    /// Creates a project, nested under `areaID` (or `parentForNewProject`) when given.
    /// The parent is unfolded so the new row is visible.
    @discardableResult
    func createProject(title: String, inArea areaID: Int64? = nil) async -> Project? {
        let parent = areaID ?? parentForNewProject
        let created = await appState.createProject(
            title: ThingsProjectTitle.normalized(title),
            parentProjectId: parent
        )
        if created != nil, let parent = parent { appState.setProjectExpanded(true, for: parent) }
        return created
    }

    /// Creates an Area: a root project whose description starts with the marker (07 section 2).
    /// The marker keeps it an Area while it is still empty; once it has children the tree
    /// rule makes it one anyway.
    @discardableResult
    func createArea(title: String) async -> Project? {
        await appState.createProject(
            title: ThingsProjectTitle.normalized(title),
            description: ThingsProjectMeta.addingAreaMarker(to: nil)
        )
    }
}
