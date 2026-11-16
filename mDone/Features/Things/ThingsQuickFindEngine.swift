import Foundation

/// What a Quick Find result opens (spec 04 section 6).
enum ThingsQuickFindTarget: Hashable {
    case list(ThingsList)
    case project(Int64)
    case area(Int64)
    case todo(Int64)
    case tag(String)
}

/// The blocks of the result list, in display order (spec 04 section 6):
/// the default lists, then to-dos, projects and Areas, and tags.
enum ThingsQuickFindGroup: Int, CaseIterable {
    case lists
    case todos
    case projects
    case tags

    /// The section title, nil for the lists (they come without a header).
    var title: String? {
        switch self {
        case .lists: return nil
        case .todos: return String(localized: "To-Dos")
        case .projects: return String(localized: "Projects and Areas")
        case .tags: return String(localized: "Tags")
        }
    }
}

struct ThingsQuickFindResult: Identifiable, Equatable {
    let id: String
    let target: ThingsQuickFindTarget
    let title: String
    let subtitle: String?

    /// The block this result belongs to.
    var group: ThingsQuickFindGroup {
        switch target {
        case .list: return .lists
        case .todo: return .todos
        case .project, .area: return .projects
        case .tag: return .tags
        }
    }
}

/// Pure search behind Quick Find and Type Travel: default lists, open to-dos,
/// projects, Areas and tags whose title contains the query, ignoring case and
/// accents. Results come grouped (lists, to-dos, projects and Areas, tags); in a
/// group a title that starts with the text ranks first, then a word that starts
/// with it, then any match, then a title containing every word typed.
/// A to-do also matches through the tags it carries.
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
        let lists = listResults(needle)
        let projectHits = projectResults(needle, projects: projects)
        let tags = tagResults(needle, labels: labels)
        // To-dos take what is left, so a long list of them never hides the
        // projects and tags.
        let room = max(limit - lists.count - projectHits.count - tags.count, 0)
        let todos = Array(todoResults(needle, tasks: tasks, projects: projects).prefix(room))
        return Array((lists + todos + projectHits + tags).prefix(limit))
    }

    /// The results cut into their blocks, empty blocks left out.
    static func grouped(_ results: [ThingsQuickFindResult]) -> [(group: ThingsQuickFindGroup, results: [ThingsQuickFindResult])] {
        var blocks: [(group: ThingsQuickFindGroup, results: [ThingsQuickFindResult])] = []
        for group in ThingsQuickFindGroup.allCases {
            let members = results.filter { $0.group == group }
            if !members.isEmpty {
                blocks.append((group: group, results: members))
            }
        }
        return blocks
    }

    /// The open to-dos that carry `tag` (exact title, ignoring case and accents),
    /// shown when a tag is chosen in Quick Find. Order of `tasks` is kept.
    static func todos(
        taggedWith tag: String,
        tasks: [VTask],
        projects: [Project]
    ) -> [ThingsQuickFindResult] {
        let key = fold(tag)
        let open = ThingsChecklist.topLevel(tasks).filter { !$0.done }
        let tagged = open.filter { task in tagTitles(of: task).contains { fold($0) == key } }
        return tagged.map { task in
            let project = projects.first { $0.id == task.projectId }
            return ThingsQuickFindResult(
                id: "todo.\(task.id)", target: .todo(task.id), title: task.title, subtitle: project?.title
            )
        }
    }

    // MARK: - Type Travel

    /// Whether `characters` can start a Type Travel search: printable text
    /// (letters, digits, punctuation), no control, function or arrow key, and
    /// not blank. A leading space does not open the search (Space is for new
    /// to-dos, spec 05).
    static func isSearchStart(_ characters: String) -> Bool {
        guard let first = characters.unicodeScalars.first else { return false }
        if CharacterSet.whitespacesAndNewlines.contains(first) { return false }
        for scalar in characters.unicodeScalars {
            if CharacterSet.controlCharacters.contains(scalar) { return false }
            // AppKit reports arrows and function keys as private use scalars.
            if (0xF700 ... 0xF8FF).contains(scalar.value) { return false }
        }
        return true
    }

    // MARK: - Ranking

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    private static func rank(_ title: String, _ needle: String) -> Int? {
        let lower = fold(title)
        let key = fold(needle)
        if key.isEmpty { return nil }
        if lower.hasPrefix(key) { return 0 }
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
        if words.contains(where: { !$0.isEmpty && $0.hasPrefix(key) }) { return 1 }
        if lower.contains(key) { return 2 }
        let tokens = key.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if tokens.count > 1, tokens.allSatisfy({ lower.contains($0) }) { return 3 }
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
