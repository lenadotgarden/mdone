import Foundation

// Drag and drop of the Things UI: targets, rules and the action a drop means
// (docs/things-spec/08-drag-and-drop.md). Everything here is pure: no SwiftUI, no
// AppState. The geometry (insertion slot) lives in ThingsDropGeometry.swift and the
// plans in ThingsDropPlan.swift. The Mac views only translate pointer events into
// these types and run the result.

/// A sidebar row a payload can be dropped on.
enum ThingsDropTarget: Equatable {
    case list(ThingsList)
    /// A project or an Area.
    case project(Int64)
}

/// What a drop on a sidebar row does.
enum ThingsDropAction: Equatable {
    /// Moves the to-do to a project, an Area or the Inbox project.
    case moveTodo(taskID: Int64, toProject: Int64)
    /// Changes the When of the to-do (Today, Someday).
    case scheduleTodo(taskID: Int64, when: ThingsWhen)
    /// Puts a project or an Area under another one.
    case reparentProject(projectID: Int64, toParent: Int64)
}

/// The facts the resolver needs, read from the app state by the caller.
struct ThingsDropFacts: Equatable {
    /// Project of the dragged to-do, nil when the to-do is unknown.
    var taskProjectID: Int64?
    /// Current When of the dragged to-do, nil when the to-do is unknown.
    var taskWhen: ThingsWhen?
    /// The Inbox project, nil when there is none.
    var inboxProjectID: Int64?
    /// Whether the dragged project may be put under the target (no cycle, a real change).
    var canReparent: Bool
}

/// Decides what a payload dropped on a sidebar row does. One place for both the hover
/// highlight (a nil result means "no highlight, refuse") and the drop itself.
enum ThingsDropResolver {
    static func action(
        for payload: ThingsDragPayload,
        on target: ThingsDropTarget,
        facts: ThingsDropFacts
    ) -> ThingsDropAction? {
        switch payload {
        case .todo(let taskID):
            guard let currentProject = facts.taskProjectID else { return nil }
            switch target {
            case .project(let projectID):
                guard currentProject != projectID else { return nil }
                return .moveTodo(taskID: taskID, toProject: projectID)
            case .list(let list):
                return todoOnList(taskID: taskID, currentProject: currentProject, list: list, facts: facts)
            }
        case .project(let projectID):
            guard case .project(let parentID) = target, facts.canReparent else { return nil }
            return .reparentProject(projectID: projectID, toParent: parentID)
        }
    }

    private static func todoOnList(
        taskID: Int64,
        currentProject: Int64,
        list: ThingsList,
        facts: ThingsDropFacts
    ) -> ThingsDropAction? {
        switch list {
        case .inbox:
            guard let inbox = facts.inboxProjectID, currentProject != inbox else { return nil }
            return .moveTodo(taskID: taskID, toProject: inbox)
        case .today:
            guard facts.taskWhen != ThingsWhen.today else { return nil }
            return .scheduleTodo(taskID: taskID, when: ThingsWhen.today)
        case .someday:
            guard facts.taskWhen != ThingsWhen.someday else { return nil }
            return .scheduleTodo(taskID: taskID, when: ThingsWhen.someday)
        case .upcoming, .anytime, .logbook:
            return nil
        }
    }
}

/// Ids of the list sections that matter for drag and drop. The Today ids must match
/// `ThingsListBuilder`; the project ids are built by `ThingsMacProjectScreen`.
enum ThingsSectionID {
    static let todayOverdue = "today.overdue"
    static let todayNormal = "today.normal"
    static let todayEvening = "today.evening"

    private static let projectPrefix = "project."
    private static let somedaySuffix = ".someday"

    static func project(_ id: Int64) -> String { projectPrefix + String(id) }

    static func projectSomeday(_ id: Int64) -> String { projectPrefix + String(id) + somedaySuffix }

    static func projectUpcoming(_ id: Int64) -> String { projectPrefix + String(id) + ".upcoming" }

    static func projectLogged(_ id: Int64) -> String { projectPrefix + String(id) + ".logged" }

    /// What a section id stands for.
    enum Role: Equatable {
        case todayNormal
        case todayEvening
        case projectMain(Int64)
        case projectSomeday(Int64)
        case other
    }

    static func role(of sectionID: String) -> Role {
        if sectionID == todayNormal { return .todayNormal }
        if sectionID == todayEvening { return .todayEvening }
        if sectionID.hasPrefix(projectPrefix) {
            let rest = String(sectionID.dropFirst(projectPrefix.count))
            if rest.hasSuffix(somedaySuffix), let id = Int64(String(rest.dropLast(somedaySuffix.count))) {
                return .projectSomeday(id)
            }
            if let id = Int64(rest) { return .projectMain(id) }
        }
        return .other
    }
}

/// A move of a to-do into another section of the same screen, and the When it implies.
struct ThingsSectionMove: Equatable {
    let sectionID: String
    let when: ThingsWhen
}

/// Which moves between sections make sense (the rest are refused).
enum ThingsDropRules {
    /// The When a to-do takes when it moves from section `from` to section `to`, nil when
    /// the move means nothing:
    /// - Today to This Evening and back (the `things:evening` label);
    /// - a project's open to-dos to its Someday group and back (Someday label, or no When).
    /// Overdue, Upcoming and Logged sections are never a source or a target: their place
    /// comes from a deadline, a date or completion, not from a drop.
    static func when(from: String, to: String) -> ThingsWhen? {
        guard from != to else { return nil }
        switch (ThingsSectionID.role(of: from), ThingsSectionID.role(of: to)) {
        case (.todayNormal, .todayEvening):
            return ThingsWhen.thisEvening
        case (.todayEvening, .todayNormal):
            return ThingsWhen.today
        case (.projectMain(let a), .projectSomeday(let b)) where a == b:
            return ThingsWhen.someday
        case (.projectSomeday(let a), .projectMain(let b)) where a == b:
            return ThingsWhen.none
        default:
            return nil
        }
    }

    /// The moves a to-do of section `from` can make to the other sections of the screen,
    /// in the order of `among`. Backs the accessibility actions and the context menu.
    static func moves(from: String, among sectionIDs: [String]) -> [ThingsSectionMove] {
        sectionIDs.compactMap { (id: String) -> ThingsSectionMove? in
            guard let implied = ThingsDropRules.when(from: from, to: id) else { return nil }
            return ThingsSectionMove(sectionID: id, when: implied)
        }
    }
}
