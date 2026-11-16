import Foundation

/// A project or Area line of the Home screen.
struct ThingsHomeProject: Identifiable {
    let project: Project
    let kind: ThingsProjectKind
    /// 0 to 1, 0 for an Area.
    let progress: Double
    /// Projects under an Area, empty for anything else.
    let children: [ThingsHomeProject]

    var id: Int64 { project.id }
}

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

    /// Root projects that belong to no Area, in display order.
    var looseProjects: [ThingsHomeProject] {
        ThingsProjectMeta.looseProjects(in: realProjects, inboxProjectID: inboxProjectID)
            .map { entry(for: $0, kind: .project, children: []) }
    }

    /// Areas with their projects.
    var areas: [ThingsHomeProject] {
        ThingsProjectMeta.areas(in: realProjects).map { area in
            let kids = ThingsProjectMeta.children(of: area.id, in: realProjects)
                .map { entry(for: $0, kind: .project, children: []) }
            return entry(for: area, kind: .area, children: kids)
        }
    }

    /// Saved filters and pseudo-projects have negative ids and are not Things lists.
    private var realProjects: [Project] {
        appState.projects.filter { $0.id > 0 && $0.isArchived != true }
    }

    private func entry(for project: Project, kind: ThingsProjectKind, children: [ThingsHomeProject]) -> ThingsHomeProject {
        let progress = kind == .area ? 0 : lists.progress(ofProject: project.id)
        return ThingsHomeProject(project: project, kind: kind, progress: progress, children: children)
    }

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

    /// Creates a project, nested under `areaID` when given.
    @discardableResult
    func createProject(title: String, inArea areaID: Int64? = nil) async -> Project? {
        await appState.createProject(title: title, parentProjectId: areaID)
    }

    /// Creates an Area: a root project whose description starts with the marker (07 section 2).
    @discardableResult
    func createArea(title: String) async -> Project? {
        await appState.createProject(
            title: title,
            description: ThingsProjectMeta.addingAreaMarker(to: nil)
        )
    }
}
