import Foundation

/// What is dragged onto a sidebar row. Carried as a plain string so no custom
/// UTType has to be declared: `todo:42` or `project:7`.
enum ThingsDragPayload: Equatable {
    case todo(Int64)
    case project(Int64)

    var encoded: String {
        switch self {
        case .todo(let id): return "mdone-todo:\(id)"
        case .project(let id): return "mdone-project:\(id)"
        }
    }

    init?(encoded: String) {
        let parts = encoded.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, let id = Int64(parts[1]), id > 0 else { return nil }
        switch parts[0] {
        case "mdone-todo": self = .todo(id)
        case "mdone-project": self = .project(id)
        default: return nil
        }
    }
}
