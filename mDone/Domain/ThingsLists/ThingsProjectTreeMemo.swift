import Foundation

/// Single entry memo behind `ThingsProjectTree.build`, keyed by a hash of every
/// project field the tree exposes (title, parent, position, archive and
/// favorite flags, description, color, update stamp, view count) and the Inbox
/// id. Locked, because trees are also built from tests and background code.
///
/// A hash collision would serve a stale tree; with a 64 bit hash over a few
/// hundred projects that is not a practical concern, and the next edit of any
/// project changes the key again.
final class ThingsProjectTreeMemo: @unchecked Sendable {
    static let shared = ThingsProjectTreeMemo()

    private let lock = NSLock()
    private var key: Int?
    private var tree: ThingsProjectTree?
    private var misses = 0

    /// How many trees were built rather than served from the memo. Read by tests.
    var missCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return misses
    }

    func lookup(_ candidate: Int) -> ThingsProjectTree? {
        lock.lock()
        defer { lock.unlock() }
        if key == candidate { return tree }
        return nil
    }

    func store(_ candidate: Int, _ built: ThingsProjectTree) {
        lock.lock()
        defer { lock.unlock() }
        key = candidate
        tree = built
        misses += 1
    }

    static func fingerprint(projects: [Project], inboxProjectID: Int64?) -> Int {
        var hasher = Hasher()
        hasher.combine(projects.count)
        hasher.combine(inboxProjectID)
        for project in projects {
            hasher.combine(project.id)
            hasher.combine(project.title)
            hasher.combine(project.description)
            hasher.combine(project.hexColor)
            hasher.combine(project.isArchived)
            hasher.combine(project.isFavorite)
            hasher.combine(project.position)
            hasher.combine(project.parentProjectId)
            hasher.combine(project.updated)
            hasher.combine(project.views?.count)
        }
        return hasher.finalize()
    }
}
