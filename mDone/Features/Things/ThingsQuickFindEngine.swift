import Foundation

/// What a Quick Find result opens (spec 04 section 6).
enum ThingsQuickFindTarget: Hashable {
    case list(ThingsList)
    case project(Int64)
    case area(Int64)
    case todo(Int64)
    case tag(String)
}

struct ThingsQuickFindResult: Identifiable, Equatable {
    let id: String
    let target: ThingsQuickFindTarget
    let title: String
    let subtitle: String?
}

/// Pure search behind Quick Find: lists, areas, projects, tags and open to-dos
/// whose title or tag contains the query. Prefix matches rank first.
/// Type Travel (typing anywhere opens the search) is a TODO, see DEVIATIONS.md.
enum ThingsQuickFindEngine {
    static func results(
        query: String,
        tasks: [VTask],
        projects: [Project],
        labels: [VLabel],
        limit: Int = 40
    ) -> [ThingsQuickFindResult] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return [] }
        var found: [ThingsQuickFindResult] = []
        found += listResults(needle)
        found += projectResults(needle, projects: projects)
        found += tagResults(needle, labels: labels)
        found += todoResults(needle, tasks: tasks, projects: projects)
        return Array(found.prefix(limit))
    }

    private static func rank(_ title: String, _ needle: String) -> Int? {
        let lower = title.lowercased()
        let key = needle.lowercased()
        if lower.hasPrefix(key) { return 0 }
        if lower.contains(key) { return 1 }
        return nil
    }

    private static func sortedByRank<T>(_ items: [(T, String)], _ needle: String) -> [T] {
        var ranked: [(item: T, rank: Int, index: Int)] = []
        for (index, entry) in items.enumerated() {
            if let value = rank(entry.1, needle) {
                ranked.append((entry.0, value, index))
            }
        }
        ranked.sort { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            return lhs.index < rhs.index
        }
        return ranked.map { $0.item }
    }

    private static func listResults(_ needle: String) -> [ThingsQuickFindResult] {
        let pairs = ThingsList.allCases.map { ($0, $0.title) }
        return sortedByRank(pairs, needle).map { list in
            ThingsQuickFindResult(id: "list.\(list.rawValue)", target: .list(list), title: list.title, subtitle: nil)
        }
    }

    private static func projectResults(_ needle: String, projects: [Project]) -> [ThingsQuickFindResult] {
        let real = projects.filter { $0.id > 0 && $0.isArchived != true }
        let pairs = real.map { ($0, $0.title) }
        return sortedByRank(pairs, needle).map { project in
            let isArea = ThingsProjectMeta.isArea(project)
            return ThingsQuickFindResult(
                id: "project.\(project.id)",
                target: isArea ? .area(project.id) : .project(project.id),
                title: project.title,
                subtitle: isArea ? String(localized: "Area") : String(localized: "Project")
            )
        }
    }

    private static func tagResults(_ needle: String, labels: [VLabel]) -> [ThingsQuickFindResult] {
        let visible = labels.filter { !ThingsReservedLabels.isReserved($0.title) }
        let pairs = visible.map { ($0, $0.title) }
        return sortedByRank(pairs, needle).map { label in
            ThingsQuickFindResult(
                id: "tag.\(label.id)", target: .tag(label.title), title: label.title, subtitle: String(localized: "Tag")
            )
        }
    }

    private static func todoResults(_ needle: String, tasks: [VTask], projects: [Project]) -> [ThingsQuickFindResult] {
        let open = ThingsChecklist.topLevel(tasks).filter { !$0.done }
        let matching = open.filter { task in
            rank(task.title, needle) != nil || tagTitles(of: task).contains { rank($0, needle) != nil }
        }
        let pairs = matching.map { ($0, $0.title) }
        let byTitle = sortedByRank(pairs, needle)
        let byTag = matching.filter { task in !byTitle.contains(where: { $0.id == task.id }) }
        return (byTitle + byTag).map { task in
            let project = projects.first { $0.id == task.projectId }
            return ThingsQuickFindResult(
                id: "todo.\(task.id)", target: .todo(task.id), title: task.title, subtitle: project?.title
            )
        }
    }

    private static func tagTitles(of task: VTask) -> [String] {
        task.thingsLabelTitles.filter { !ThingsReservedLabels.isReserved($0) }
    }

    // MARK: - Where a to-do lives

    /// The list or project that shows `task`, so Quick Find can open it.
    /// A to-do of the Inbox project follows its When (06 section 16): Today,
    /// Upcoming or Someday once scheduled, Inbox otherwise. A finished to-do is in the Logbook.
    static func route(for task: VTask, inboxProjectID: Int64?, now: Date, calendar: Calendar) -> ThingsRoute {
        if task.done { return .list(.logbook) }
        if task.projectId != inboxProjectID { return .project(task.projectId) }
        switch ThingsWhen.resolve(task: task, now: now, calendar: calendar) {
        case .today, .thisEvening: return .list(.today)
        case .date: return .list(.upcoming)
        case .someday: return .list(.someday)
        case .none: return .list(.inbox)
        }
    }
}
