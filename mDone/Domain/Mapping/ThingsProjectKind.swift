import Foundation

/// What a Vikunja project is in Things terms (07 sections 1, 2 and 16).
enum ThingsProjectKind: Equatable {
    /// The user's default project.
    case inbox
    /// A root project whose description starts with the `things:area` marker.
    case area
    /// Any other project.
    case project
}

enum ThingsProjectMeta {
    /// The marker line that makes a root project an Area.
    static let areaMarker = "things:area"

    // MARK: - Kind

    /// The kind of `project`. The Inbox wins over a marker.
    ///
    /// SPEC-UNSURE: a marker on a project that has a parent is ignored, since
    /// Things has only Area > Project (07 section 1).
    static func kind(of project: Project, inboxProjectID: Int64?) -> ThingsProjectKind {
        if isInbox(project, inboxProjectID: inboxProjectID) { return .inbox }
        if isArea(project) { return .area }
        return .project
    }

    /// Whether `project` is the Inbox. False when the Inbox id is unknown.
    static func isInbox(_ project: Project, inboxProjectID: Int64?) -> Bool {
        guard let inboxID = inboxProjectID else { return false }
        return project.id == inboxID
    }

    /// Whether `project` has no parent (nil or 0).
    static func isRoot(_ project: Project) -> Bool {
        (project.parentProjectId ?? 0) == 0
    }

    /// Whether `project` is a root project carrying the area marker.
    static func isArea(_ project: Project) -> Bool {
        isRoot(project) && hasAreaMarker(project.description)
    }

    // MARK: - Marker in a description

    /// Whether the first line of `description` is the area marker, ignoring
    /// case and surrounding whitespace.
    static func hasAreaMarker(_ description: String?) -> Bool {
        guard let description = description else { return false }
        let lines = description.components(separatedBy: "\n")
        guard let first = lines.first else { return false }
        return isMarkerLine(first)
    }

    /// `description` without the marker line. Only the marker line and its
    /// line break are removed; every other character is left as it was.
    /// A description without the marker is returned unchanged ("" for nil).
    static func removingAreaMarker(from description: String?) -> String {
        guard let description = description else { return "" }
        var lines = description.components(separatedBy: "\n")
        guard let first = lines.first, isMarkerLine(first) else { return description }
        lines.removeFirst()
        return lines.joined(separator: "\n")
    }

    /// `description` with the marker as its first line. Unchanged when the
    /// marker is already there. An empty or nil description becomes the
    /// marker alone.
    static func addingAreaMarker(to description: String?) -> String {
        let text = description ?? ""
        if hasAreaMarker(text) { return text }
        if text.isEmpty { return areaMarker }
        return areaMarker + "\n" + text
    }

    /// The description to show the user: marker stripped.
    static func userVisibleDescription(of project: Project) -> String {
        removingAreaMarker(from: project.description)
    }

    private static func isMarkerLine(_ line: String) -> Bool {
        let key = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return key == areaMarker
    }

    // MARK: - Hierarchy helpers

    /// Root Areas in display order (position, then title, then id).
    static func areas(in projects: [Project]) -> [Project] {
        projects.filter { isArea($0) }.sorted(by: ordersBefore)
    }

    /// The projects directly under `parentID`, in display order.
    static func children(of parentID: Int64, in projects: [Project]) -> [Project] {
        projects.filter { ($0.parentProjectId ?? 0) == parentID && $0.id != parentID }
            .sorted(by: ordersBefore)
    }

    /// Root projects that are neither an Area nor the Inbox, in display order.
    static func looseProjects(in projects: [Project], inboxProjectID: Int64?) -> [Project] {
        projects.filter { project in
            kind(of: project, inboxProjectID: inboxProjectID) == .project && isRoot(project)
        }.sorted(by: ordersBefore)
    }

    private static func ordersBefore(_ lhs: Project, _ rhs: Project) -> Bool {
        let lp = lhs.position ?? 0
        let rp = rhs.position ?? 0
        if lp != rp { return lp < rp }
        let byTitle = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if byTitle != .orderedSame { return byTitle == .orderedAscending }
        return lhs.id < rhs.id
    }
}
