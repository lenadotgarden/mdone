import XCTest
@testable import mDone

/// Regression tests for "the sub-project tree is not shown". They start from what Vikunja
/// really sends for `GET /projects` (snake case, flat list, no Things markers) and follow it
/// through the decoder, the Inbox fallback and the tree builder.
final class ThingsProjectHierarchyTests: XCTestCase {
    private let suiteName = "ThingsProjectHierarchyTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Vikunja payload

    /// A flat page of `GET /projects` for a three level hierarchy and no marker anywhere:
    /// Work > Shorts > Daily > Episodes, Perso > Sport, Experiments > Code, and an archived
    /// project with a live child. There is no project called "Inbox" (a fresh account has
    /// one, an account that renamed or deleted it does not).
    private let json = """
    [
      {"id": 2, "title": "Work", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 0, "is_archived": false, "is_favorite": false, "position": 65536,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 3, "title": "Shorts", "description": "", "identifier": "", "hex_color": "e8e8e8",
       "parent_project_id": 2, "is_archived": false, "is_favorite": true, "position": 65536,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 4, "title": "Daily", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 3, "is_archived": false, "is_favorite": false, "position": 65536,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 5, "title": "Episodes", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 4, "is_archived": false, "is_favorite": false, "position": 65536,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 6, "title": "Perso", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 0, "is_archived": false, "is_favorite": false, "position": 131072,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 7, "title": "Sport", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 6, "is_archived": false, "is_favorite": false, "position": 65536,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 8, "title": "Experiments", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 0, "is_archived": false, "is_favorite": false, "position": 196608,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 9, "title": "Passer le code", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 8, "is_archived": false, "is_favorite": false, "position": 65536,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 10, "title": "Old", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 2, "is_archived": true, "is_favorite": false, "position": 131072,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": 11, "title": "Under old", "description": "", "identifier": "", "hex_color": "",
       "parent_project_id": 10, "is_archived": false, "is_favorite": false, "position": 65536,
       "created": "2026-01-02T10:00:00Z", "updated": "2026-01-02T10:00:00Z", "max_permission": 2, "views": []},
      {"id": -2, "title": "My Open Tasks", "description": "", "parent_project_id": 0, "position": 0}
    ]
    """

    private func decoded() throws -> [Project] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Project].self, from: Data(json.utf8))
    }

    private func ids(_ nodes: [ThingsProjectNode]) -> [Int64] { nodes.map { $0.id } }

    func testParentProjectIdIsDecoded() throws {
        let projects = try decoded()
        XCTAssertEqual(projects.first { $0.id == 5 }?.parentProjectId, 4)
        XCTAssertEqual(projects.first { $0.id == 4 }?.parentProjectId, 3)
        XCTAssertEqual(projects.first { $0.id == 2 }?.parentProjectId, 0)
    }

    // MARK: - Three levels

    func testThreeLevelHierarchyKeepsEveryLevelWithItsDepth() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        XCTAssertEqual(tree.node(id: 2)?.depth, 0)
        XCTAssertEqual(tree.node(id: 3)?.depth, 1)
        XCTAssertEqual(tree.node(id: 4)?.depth, 2)
        XCTAssertEqual(tree.node(id: 5)?.depth, 3)
        XCTAssertEqual(tree.node(id: 5)?.parentID, 4)
        XCTAssertEqual(tree.areas.map { $0.id }, [2, 6, 8])
        XCTAssertEqual(tree.node(id: 2)?.kind, .area)
        XCTAssertEqual(tree.node(id: 3)?.kind, .project)
        XCTAssertEqual(tree.node(id: 4)?.kind, .project)
    }

    func testEveryLiveProjectIsInTheTreeExactlyOnce() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        // 10 is archived, -2 is a pseudo project; 11 (child of the archived one) surfaces.
        XCTAssertEqual(tree.allNodes.map { $0.id }.sorted(), [2, 3, 4, 5, 6, 7, 8, 9, 11])
    }

    func testUnmarkedAreaIsAnAreaInTheTreeButNotUnderTheOldMarkerRule() throws {
        let projects = try decoded()
        let work = projects.first { $0.id == 2 }!
        // The old rule (marker only) is why the iPhone Home screen and the Area screen
        // showed no sub-projects: Lena's projects have no marker.
        XCTAssertFalse(ThingsProjectMeta.isArea(work))
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertTrue(tree.node(id: 2)?.isArea == true)
    }

    func testAreaScreenRowsListEveryDescendantRelativeToTheArea() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        let rows = tree.descendantRows(of: 2, collapsed: [])
        XCTAssertEqual(rows.map { $0.id }, [3, 4, 5])
        XCTAssertEqual(rows.map { $0.depth }, [0, 1, 2])
    }

    func testFoldingAChildHidesOnlyItsOwnSubtree() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        XCTAssertEqual(tree.descendantRows(of: 2, collapsed: [3]).map { $0.id }, [3])
        XCTAssertEqual(tree.descendantRows(of: 2, collapsed: [4]).map { $0.id }, [3, 4])
        // A fold on an unrelated project changes nothing.
        XCTAssertEqual(tree.descendantRows(of: 2, collapsed: [6]).map { $0.id }, [3, 4, 5])
        XCTAssertEqual(tree.descendantRows(of: 7, collapsed: []).map { $0.id }, [])
    }

    func testNothingIsFoldedByDefaultSoTheWholeTreeShows() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        let shown = tree.visibleNodes(collapsed: []).map { $0.id }
        XCTAssertEqual(Set(shown), Set(tree.allNodes.map { $0.id }))
        XCTAssertEqual(Set(tree.expandableIDs), [2, 3, 4, 6, 8])
    }

    func testFavoriteChildStaysUnderItsParent() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        XCTAssertEqual(tree.favorites.map { $0.id }, [3])
        XCTAssertEqual(tree.node(id: 3)?.parentID, 2)
    }

    func testArchivedProjectIsHiddenAndItsLiveChildSurfacesAtTheRoot() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        XCTAssertNil(tree.node(id: 10))
        XCTAssertEqual(tree.node(id: 11)?.depth, 0)
        XCTAssertNil(tree.node(id: 11)?.parentID)
    }

    // MARK: - Inbox fallback

    func testFallbackInboxIsTheFirstProjectWhenNoneIsCalledInbox() throws {
        let projects = try decoded()
        let resolved = DefaultProjectPreference.resolve(in: projects, defaults: defaults)
        // The fallback picks Work, the root of the biggest subtree.
        XCTAssertEqual(resolved?.id, 2)
    }

    func testAGuessedInboxNeverRemovesItsSubtreeFromTheTree() throws {
        let projects = try decoded()
        let guessed = DefaultProjectPreference.resolve(in: projects, defaults: defaults)?.id
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: guessed)
        XCTAssertNotNil(tree.node(id: 2))
        XCTAssertEqual(tree.node(id: 2)?.children.map { $0.id }, [3])
        XCTAssertNotNil(tree.node(id: 5))
        XCTAssertTrue(tree.node(id: 2)?.isArea == true)
    }

    // MARK: - Robustness

    func testOrphanCyclicAndSelfParentedProjectsAreAllShown() {
        let projects = [
            Project(id: 1, title: "Loop A", parentProjectId: 2),
            Project(id: 2, title: "Loop B", parentProjectId: 1),
            Project(id: 3, title: "Self", parentProjectId: 3),
            Project(id: 4, title: "Orphan", parentProjectId: 999),
            Project(id: 5, title: "Fine"),
            Project(id: 5, title: "Duplicate id")
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(tree.allNodes.map { $0.id }.sorted(), [1, 2, 3, 4, 5])
        XCTAssertEqual(Set(tree.allNodes.map { $0.id }).count, tree.allNodes.count)
    }

    func testDeepChainDoesNotOverflowOrLoseNodes() {
        var projects = [Project(id: 1, title: "Root")]
        for id in 2...60 {
            projects.append(Project(id: Int64(id), title: "Level \(id)", parentProjectId: Int64(id - 1)))
        }
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(tree.allNodes.count, 60)
        XCTAssertEqual(tree.node(id: 60)?.depth, 59)
        XCTAssertEqual(tree.descendantRows(of: 1, collapsed: []).count, 59)
    }

    func testSiblingsOfARootAreTheRoots() throws {
        let tree = ThingsProjectTree.build(projects: try decoded(), inboxProjectID: nil)
        XCTAssertEqual(ids(tree.siblings(ofParent: nil)), ids(tree.roots))
        XCTAssertEqual(ids(tree.siblings(ofParent: 4)), [5])
    }
}
