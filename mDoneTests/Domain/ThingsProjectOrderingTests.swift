import XCTest
@testable import mDone

final class ThingsProjectOrderingTests: XCTestCase {
    // MARK: - Helpers

    private func project(_ id: Int64, _ title: String, parent: Int64? = nil, position: Double? = nil) -> Project {
        Project(id: id, title: title, position: position, parentProjectId: parent)
    }

    private func tree(_ projects: [Project]) -> ThingsProjectTree {
        ThingsProjectTree.build(projects: projects, inboxProjectID: nil)
    }

    /// What the server state looks like once the placement is written.
    private func apply(_ placement: ThingsProjectPlacement, to projects: [Project]) -> [Project] {
        var result = projects
        for update in placement.updates {
            guard let index = result.firstIndex(where: { $0.id == update.projectID }) else { continue }
            result[index].position = update.position
            if update.projectID == placement.projectID {
                result[index].parentProjectId = placement.parentID
            }
        }
        return result
    }

    private var three: [Project] {
        [project(1, "A", position: 100), project(2, "B", position: 200), project(3, "C", position: 300)]
    }

    // MARK: - Same parent

    func testMovingBeforeASiblingTakesTheMiddlePosition() {
        let placement = ThingsProjectOrdering.placement(tree: tree(three), projectID: 3, relativeTo: 2, edge: .before)
        XCTAssertEqual(placement?.parentID, nil)
        XCTAssertEqual(placement?.updates, [ThingsProjectPlacement.Update(projectID: 3, position: 150)])
    }

    func testMovingAfterTheLastSiblingAddsTheEndGap() {
        let placement = ThingsProjectOrdering.placement(tree: tree(three), projectID: 1, relativeTo: 3, edge: .after)
        XCTAssertEqual(placement?.updates, [ThingsProjectPlacement.Update(projectID: 1, position: 300 + 65536)])
    }

    func testMovingBeforeTheFirstSiblingHalvesItsPosition() {
        let placement = ThingsProjectOrdering.placement(tree: tree(three), projectID: 3, relativeTo: 1, edge: .before)
        XCTAssertEqual(placement?.updates, [ThingsProjectPlacement.Update(projectID: 3, position: 50)])
    }

    func testNoOpAndSelfDropsAreRefused() {
        let t = tree(three)
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 1, relativeTo: 2, edge: .before))
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 2, relativeTo: 1, edge: .after))
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 2, relativeTo: 2, edge: .before))
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 2, relativeTo: 99, edge: .before))
    }

    func testSiblingsWithoutPositionsAreRenumberedSoTheOrderIsExact() {
        // A fresh account: every position is nil or zero, the order comes from the titles.
        let projects = [project(1, "A"), project(2, "B"), project(3, "C")]
        guard let placement = ThingsProjectOrdering.placement(
            tree: tree(projects), projectID: 3, relativeTo: 2, edge: .before
        ) else {
            return XCTFail("expected a placement")
        }
        XCTAssertEqual(placement.updates.first?.projectID, 3)
        XCTAssertEqual(placement.updates.count, 3)
        let after = tree(apply(placement, to: projects))
        XCTAssertEqual(after.roots.map { $0.id }, [1, 3, 2])
    }

    func testAppliedPlacementProducesTheRequestedOrder() {
        let projects = three
        for (moving, target, edge, expected) in [
            (Int64(3), Int64(1), ThingsDropEdge.before, [Int64(3), 1, 2]),
            (Int64(1), Int64(2), ThingsDropEdge.after, [Int64(2), 1, 3]),
            (Int64(1), Int64(3), ThingsDropEdge.after, [Int64(2), 3, 1]),
            (Int64(2), Int64(3), ThingsDropEdge.after, [Int64(1), 3, 2])
        ] {
            guard let placement = ThingsProjectOrdering.placement(
                tree: tree(projects), projectID: moving, relativeTo: target, edge: edge
            ) else {
                XCTFail("expected a placement for \(moving) \(edge) \(target)")
                continue
            }
            XCTAssertEqual(tree(apply(placement, to: projects)).roots.map { $0.id }, expected)
        }
    }

    // MARK: - Other parent

    private var withArea: [Project] {
        [
            project(10, "Work", position: 100),
            project(11, "X", parent: 10, position: 100),
            project(12, "Y", parent: 10, position: 200),
            project(20, "Z", position: 300),
            project(21, "Q", position: 400)
        ]
    }

    func testDropBetweenTwoChildrenOfAnAreaReparentsAndOrders() {
        let projects = withArea
        guard let placement = ThingsProjectOrdering.placement(
            tree: tree(projects), projectID: 20, relativeTo: 12, edge: .before
        ) else {
            return XCTFail("expected a placement")
        }
        XCTAssertEqual(placement.parentID, 10)
        let after = tree(apply(placement, to: projects))
        XCTAssertEqual(after.node(id: 10)?.children.map { $0.id }, [11, 20, 12])
        XCTAssertEqual(after.node(id: 20)?.depth, 1)
    }

    func testNestedProjectDroppedOnARootEdgeGoesToTheTopLevel() {
        let projects = withArea
        guard let placement = ThingsProjectOrdering.placement(
            tree: tree(projects), projectID: 11, relativeTo: 21, edge: .before
        ) else {
            return XCTFail("expected a placement")
        }
        XCTAssertNil(placement.parentID)
        let after = tree(apply(placement, to: projects))
        XCTAssertEqual(after.node(id: 11)?.depth, 0)
        XCTAssertEqual(after.looseProjects.map { $0.id }, [20, 11, 21])
    }

    func testCannotDropAProjectBesideItsOwnDescendant() {
        let t = tree(withArea)
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 10, relativeTo: 11, edge: .before))
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 10, relativeTo: 12, edge: .after))
    }

    func testAreaAndLooseProjectAreNotMixedAtTheTopLevel() {
        let t = tree(withArea)
        // Work is an Area, Z is loose: the sidebar lists loose projects first, so an edge
        // drop across the two groups would not stay where it was dropped.
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 20, relativeTo: 10, edge: .before))
        XCTAssertNil(ThingsProjectOrdering.placement(tree: t, projectID: 10, relativeTo: 20, edge: .after))
        XCTAssertNotNil(ThingsProjectOrdering.placement(tree: t, projectID: 21, relativeTo: 20, edge: .before))
    }

    // MARK: - Position maths

    func testSinglePositionNeedsRoomBetweenNeighbours() {
        XCTAssertEqual(ThingsProjectOrdering.singlePosition(before: 1, after: 3), 2)
        XCTAssertNil(ThingsProjectOrdering.singlePosition(before: 5, after: 5))
        XCTAssertNil(ThingsProjectOrdering.singlePosition(before: 6, after: 5))
        XCTAssertEqual(ThingsProjectOrdering.singlePosition(before: nil, after: 8), 4)
        XCTAssertEqual(ThingsProjectOrdering.singlePosition(before: nil, after: 0), -65536)
        XCTAssertEqual(ThingsProjectOrdering.singlePosition(before: 10, after: nil), 10 + 65536)
        XCTAssertEqual(ThingsProjectOrdering.singlePosition(before: nil, after: nil), 65536)
    }

    // MARK: - Zones and drop resolution

    func testRowZonesFollowThePointerHeight() {
        XCTAssertEqual(ThingsRowDropZone.zone(y: 1, height: 24, allowsEdges: true), .before)
        XCTAssertEqual(ThingsRowDropZone.zone(y: 12, height: 24, allowsEdges: true), .into)
        XCTAssertEqual(ThingsRowDropZone.zone(y: 23, height: 24, allowsEdges: true), .after)
        XCTAssertEqual(ThingsRowDropZone.zone(y: 1, height: 24, allowsEdges: false), .into)
        XCTAssertEqual(ThingsRowDropZone.zone(y: 1, height: 0, allowsEdges: true), .into)
        XCTAssertEqual(ThingsRowDropZone.before.edge, ThingsDropEdge.before)
        XCTAssertNil(ThingsRowDropZone.into.edge)
    }

    func testResolvedZoneFallsBackToIntoWhenTheEdgeIsNotLegal() {
        let projects = [
            project(1, "Area", position: 100),
            project(3, "Child", parent: 1),
            project(2, "Loose", position: 200)
        ]
        let t = tree(projects)
        // A loose project on the edge of an Area cannot be its sibling: it nests instead.
        XCTAssertEqual(ThingsProjectDropResolver.resolvedZone(tree: t, projectID: 2, targetID: 1, zone: .before), .into)
        // A child dragged beside a loose root becomes a root sibling.
        XCTAssertEqual(ThingsProjectDropResolver.resolvedZone(tree: t, projectID: 3, targetID: 2, zone: .before), .before)
        // An Area dropped on its own child: nothing is legal.
        XCTAssertNil(ThingsProjectDropResolver.resolvedZone(tree: t, projectID: 1, targetID: 3, zone: .after))
    }

    func testDropOutcomes() {
        let t = tree(withArea)
        XCTAssertEqual(
            ThingsProjectDropResolver.outcome(tree: t, projectID: 20, targetID: 10, zone: .into),
            .reparent(projectID: 20, parentID: 10)
        )
        XCTAssertNil(ThingsProjectDropResolver.outcome(tree: t, projectID: 10, targetID: 11, zone: .into))
        XCTAssertNil(ThingsProjectDropResolver.outcome(tree: t, projectID: 11, targetID: 10, zone: .into))
        if case .place(_)? = ThingsProjectDropResolver.outcome(tree: t, projectID: 20, targetID: 12, zone: .after) {
            // expected
        } else {
            XCTFail("expected a sibling placement")
        }
    }

    // MARK: - Titles

    func testTitleNormalizationKeepsAndSpacesALeadingEmoji() {
        XCTAssertEqual(ThingsProjectTitle.normalized("  Work  "), "Work")
        XCTAssertEqual(ThingsProjectTitle.normalized("a   b"), "a b")
        XCTAssertEqual(ThingsProjectTitle.normalized("\u{1F680}Work"), "\u{1F680} Work")
        XCTAssertEqual(ThingsProjectTitle.normalized("\u{1F680} Work"), "\u{1F680} Work")
        XCTAssertEqual(ThingsProjectTitle.normalized("\u{1F680}"), "\u{1F680}")
        XCTAssertEqual(ThingsProjectTitle.normalized("2024 plan"), "2024 plan")
        XCTAssertEqual(ThingsProjectTitle.normalized("\u{A9}Copyright"), "\u{A9}Copyright")
        XCTAssertEqual(ThingsProjectTitle.normalized("   "), "")
    }

    func testLeadingEmoji() {
        XCTAssertEqual(ThingsProjectTitle.leadingEmoji(of: "\u{1F331} Experiments"), "\u{1F331}")
        XCTAssertNil(ThingsProjectTitle.leadingEmoji(of: "Experiments"))
    }
}
