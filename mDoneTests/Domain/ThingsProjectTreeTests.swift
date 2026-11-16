import XCTest
@testable import mDone

final class ThingsProjectTreeTests: XCTestCase {
    // MARK: - Helpers

    private func project(
        _ id: Int64,
        _ title: String,
        parent: Int64? = nil,
        position: Double? = nil,
        description: String? = nil,
        archived: Bool? = nil,
        favorite: Bool? = nil
    ) -> Project {
        Project(
            id: id, title: title, description: description, isArchived: archived,
            isFavorite: favorite, position: position, parentProjectId: parent
        )
    }

    private func ids(_ nodes: [ThingsProjectNode]) -> [Int64] { nodes.map { $0.id } }

    /// Shape of Lena's real data: Work, Perso, Experiments with children and no marker.
    private var lenaProjects: [Project] {
        [
            project(1, "Inbox", position: 1),
            project(10, "Work", position: 10),
            project(11, "Strategie", parent: 10, position: 2),
            project(12, "Lancer Daily", parent: 10, position: 1),
            project(20, "Perso", position: 20),
            project(21, "Sport", parent: 20),
            project(30, "Experiments", position: 30),
            project(31, "Passer le code", parent: 30),
            project(40, "Solo", position: 5)
        ]
    }

    // MARK: - Area rule

    func testRootWithChildrenIsAreaWithoutMarker() {
        let tree = ThingsProjectTree.build(projects: lenaProjects, inboxProjectID: 1)
        XCTAssertEqual(ids(tree.areas), [10, 20, 30])
        XCTAssertTrue(tree.areas.allSatisfy { $0.kind == .area })
    }

    func testRootWithoutChildrenIsLooseProject() {
        let tree = ThingsProjectTree.build(projects: lenaProjects, inboxProjectID: 1)
        XCTAssertEqual(ids(tree.looseProjects), [40])
        XCTAssertEqual(tree.looseProjects.first?.kind, .project)
    }

    func testMarkedRootWithoutChildrenIsArea() {
        let projects = [project(5, "Empty area", description: "things:area\nnotes")]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(tree.roots.first?.kind, .area)
    }

    func testMarkerOnNonRootIsIgnored() {
        let projects = [
            project(1, "Area", position: 1),
            project(2, "Child", parent: 1, description: "things:area")
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(tree.node(id: 2)?.kind, .project)
    }

    func testAreaWhoseOnlyChildIsArchivedBecomesLooseProject() {
        let projects = [
            project(1, "Work"),
            project(2, "Old", parent: 1, archived: true)
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(tree.roots.first?.kind, .project)
        XCTAssertTrue(tree.roots.first?.children.isEmpty ?? false)
    }

    // MARK: - Order and depth

    func testChildrenFollowPositionThenTitle() {
        let tree = ThingsProjectTree.build(projects: lenaProjects, inboxProjectID: 1)
        XCTAssertEqual(ids(tree.node(id: 10)?.children ?? []), [12, 11])
    }

    func testDepthsAndParentIDs() {
        let projects = [
            project(1, "Area"),
            project(2, "Project", parent: 1),
            project(3, "Sub", parent: 2),
            project(4, "Subsub", parent: 3)
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(tree.allNodes.map { $0.depth }, [0, 1, 2, 3])
        XCTAssertEqual(tree.node(id: 4)?.parentID, 3)
        XCTAssertEqual(tree.node(id: 2)?.kind, .project)
        XCTAssertEqual(tree.node(id: 2)?.hasChildren, true)
        XCTAssertEqual(tree.descendantIDs(of: 1), [2, 3, 4])
        XCTAssertEqual(tree.ancestorIDs(of: 4), [3, 2, 1])
    }

    // MARK: - Exclusions

    func testInboxAndPseudoProjectsExcluded() {
        let projects = [project(-1, "Favorites"), project(1, "Inbox"), project(2, "Work")]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: 1)
        XCTAssertEqual(ids(tree.allNodes), [2])
    }

    func testChildrenOfInboxMoveToRoot() {
        let projects = [project(1, "Inbox"), project(2, "Under inbox", parent: 1)]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: 1)
        XCTAssertEqual(ids(tree.roots), [2])
    }

    func testArchivedExcludedWithSubtree() {
        let projects = [
            project(1, "Area"),
            project(2, "Archived", parent: 1, archived: true),
            project(3, "Under archived", parent: 2),
            project(4, "Live", parent: 1)
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(ids(tree.allNodes), [1, 4])
    }

    func testUnknownParentIsShownAsRoot() {
        let projects = [project(5, "Shared", parent: 999)]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(ids(tree.roots), [5])
    }

    func testParentLoopDoesNotHangAndKeepsBothProjects() {
        let projects = [project(1, "A", parent: 2), project(2, "B", parent: 1)]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(Set(ids(tree.allNodes)), [1, 2])
    }

    // MARK: - Favorites and collapse

    func testFavoritesStayInTreeAndAreListed() {
        let projects = [
            project(1, "Area"),
            project(2, "Fav", parent: 1, favorite: true),
            project(3, "Plain", parent: 1)
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertEqual(ids(tree.favorites), [2])
        XCTAssertEqual(ids(tree.allNodes), [1, 2, 3])
    }

    func testVisibleNodesHideCollapsedSubtree() {
        let tree = ThingsProjectTree.build(projects: lenaProjects, inboxProjectID: 1)
        let all = tree.visibleNodes(collapsed: [])
        // Loose project first, then each Area followed by its children.
        XCTAssertEqual(ids(all), [40, 10, 12, 11, 20, 21, 30, 31])
        let folded = tree.visibleNodes(collapsed: [10])
        XCTAssertEqual(ids(folded), [40, 10, 20, 21, 30, 31])
    }

    // MARK: - Moving

    func testCanMoveRejectsCyclesAndNoOps() {
        let projects = [
            project(1, "Area"),
            project(2, "P", parent: 1),
            project(3, "Sub", parent: 2),
            project(4, "Other")
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        XCTAssertFalse(tree.canMove(projectID: 2, toParent: 2))
        XCTAssertFalse(tree.canMove(projectID: 2, toParent: 3))
        XCTAssertFalse(tree.canMove(projectID: 2, toParent: 1))
        XCTAssertTrue(tree.canMove(projectID: 2, toParent: 4))
        XCTAssertTrue(tree.canMove(projectID: 2, toParent: nil))
        XCTAssertFalse(tree.canMove(projectID: 1, toParent: nil))
    }

    func testProjectMoveTargetsExcludeSelfAndDescendants() {
        let projects = [
            project(1, "Area"),
            project(2, "P", parent: 1),
            project(3, "Sub", parent: 2),
            project(4, "Other")
        ]
        let tree = ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
        let targets = ThingsMoveTargets.forProject(tree: tree, projectID: 2, query: "")
        XCTAssertEqual(targets.map { $0.kind }, [.topLevel, .project, .area])
        XCTAssertEqual(targets.compactMap { $0.projectID }, [4, 1])
    }

    func testTodoMoveTargetsStartWithInboxAndKeepDepth() {
        let tree = ThingsProjectTree.build(projects: lenaProjects, inboxProjectID: 1)
        let inbox = lenaProjects.first { $0.id == 1 }
        let targets = ThingsMoveTargets.forTodo(tree: tree, inboxProject: inbox, query: "")
        XCTAssertEqual(targets.first?.kind, .inbox)
        XCTAssertEqual(targets.compactMap { $0.projectID }, [1, 40, 10, 12, 11, 20, 21, 30, 31])
        XCTAssertEqual(targets.first { $0.projectID == 12 }?.depth, 1)
    }

    func testMoveTargetFilterMatchesTitleOrPathIgnoringCaseAndAccents() {
        let tree = ThingsProjectTree.build(projects: lenaProjects, inboxProjectID: 1)
        let byTitle = ThingsMoveTargets.forTodo(tree: tree, inboxProject: nil, query: "strategie")
        XCTAssertEqual(byTitle.compactMap { $0.projectID }, [11])
        let byAccent = ThingsMoveTargets.forTodo(tree: tree, inboxProject: nil, query: "stratégie")
        XCTAssertEqual(byAccent.compactMap { $0.projectID }, [11])
        let byPath = ThingsMoveTargets.forTodo(tree: tree, inboxProject: nil, query: "perso sport")
        XCTAssertEqual(byPath.compactMap { $0.projectID }, [21])
        XCTAssertEqual(byPath.first?.path, "Perso")
    }

    func testClampedIndex() {
        XCTAssertEqual(ThingsMoveTargets.clampedIndex(5, count: 3), 2)
        XCTAssertEqual(ThingsMoveTargets.clampedIndex(-1, count: 3), 0)
        XCTAssertEqual(ThingsMoveTargets.clampedIndex(1, count: 0), 0)
    }

    // MARK: - Drag payload

    func testDragPayloadRoundTrip() {
        XCTAssertEqual(ThingsDragPayload(encoded: ThingsDragPayload.todo(42).encoded), .todo(42))
        XCTAssertEqual(ThingsDragPayload(encoded: ThingsDragPayload.project(7).encoded), .project(7))
        XCTAssertNil(ThingsDragPayload(encoded: "hello"))
        XCTAssertNil(ThingsDragPayload(encoded: "mdone-todo:abc"))
        XCTAssertNil(ThingsDragPayload(encoded: "other:3"))
    }
}
