import XCTest
@testable import mDone

/// Manual order of the Things lists: the plans behind drag and drop and the
/// Cmd Opt arrow keys, and the project line of Mac rows.
final class ThingsReorderTests: XCTestCase {
    private func task(_ id: Int64, position: Double?, project: Int64 = 7) -> VTask {
        var task = VTask(id: id, title: "Task \(id)", done: false, priority: 0, projectId: project)
        task.position = position
        return task
    }

    private var three: [VTask] {
        [task(1, position: 100), task(2, position: 200), task(3, position: 300)]
    }

    // MARK: - Plans

    func testMovingDownByOneSwapsWithTheNextAndSitsBetweenItsNeighbours() throws {
        let plan = try XCTUnwrap(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 1, by: 1))
        XCTAssertEqual(plan.reorderedIDs, [2, 1, 3])
        XCTAssertEqual(plan.task.id, 1)
        XCTAssertEqual(plan.position, 250, accuracy: 0.0001)
        XCTAssertEqual(plan.sectionID, "s")
    }

    func testMovingUpByOne() throws {
        let plan = try XCTUnwrap(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 3, by: -1))
        XCTAssertEqual(plan.reorderedIDs, [1, 3, 2])
        XCTAssertEqual(plan.position, 150, accuracy: 0.0001)
    }

    func testMovingToTheEndAddsTheEndGap() throws {
        let plan = try XCTUnwrap(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 2, by: 1))
        XCTAssertEqual(plan.reorderedIDs, [1, 3, 2])
        XCTAssertEqual(plan.position, 300 + TaskPositioning.endGap, accuracy: 0.0001)
    }

    func testMovingToTheTopHalvesTheFirstPosition() throws {
        let plan = try XCTUnwrap(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 2, by: -1))
        XCTAssertEqual(plan.reorderedIDs, [2, 1, 3])
        XCTAssertEqual(plan.position, 50, accuracy: 0.0001)
    }

    func testMovingPastTheEndsIsNil() {
        XCTAssertNil(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 1, by: -1))
        XCTAssertNil(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 3, by: 1))
        XCTAssertNil(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 99, by: 1))
        XCTAssertNil(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 1, by: 0))
    }

    func testDropOffsetUsesThePreMoveIndexing() throws {
        // Dragging the first row below the third: it ends at index 2, offset 3.
        XCTAssertEqual(ThingsReorder.destinationOffset(from: 0, finalIndex: 2), 3)
        XCTAssertEqual(ThingsReorder.destinationOffset(from: 2, finalIndex: 0), 0)
        let plan = try XCTUnwrap(ThingsReorder.plan(
            sectionID: "s", tasks: three, movingID: 1,
            toOffset: ThingsReorder.destinationOffset(from: 0, finalIndex: 2)
        ))
        XCTAssertEqual(plan.reorderedIDs, [2, 3, 1])
    }

    func testDropWhereItWasChangesNothing() {
        XCTAssertNil(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 2, toOffset: 1))
        XCTAssertNil(ThingsReorder.plan(sectionID: "s", tasks: three, movingID: 2, toOffset: 2))
    }

    // MARK: - Shown order

    func testOrderedFollowsTheGivenIDsAndKeepsUnknownRowsAtTheEnd() {
        let rows = three.map { task in
            ThingsDisplayRow(task: task, model: ThingsTodoRowModel(id: String(task.id), title: task.title))
        }
        XCTAssertEqual(ThingsReorder.ordered(rows, by: [3, 1]).map { $0.task.id }, [3, 1, 2])
        XCTAssertEqual(ThingsReorder.ordered(rows, by: nil).map { $0.task.id }, [1, 2, 3])
        XCTAssertEqual(ThingsReorder.ordered(rows, by: []).map { $0.task.id }, [1, 2, 3])
    }

    // MARK: - Project line

    func testProjectLineIsHiddenForTheInboxAndTheProjectOnScreen() {
        let titles: [Int64: String] = [1: "Inbox", 7: "Work", 8: "How to make a CPU?"]
        XCTAssertNil(ThingsRowMapper.projectLine(forProjectID: 1, titles: titles, inboxProjectID: 1, hiddenProjectID: nil))
        XCTAssertNil(ThingsRowMapper.projectLine(forProjectID: 7, titles: titles, inboxProjectID: 1, hiddenProjectID: 7))
        XCTAssertEqual(
            ThingsRowMapper.projectLine(forProjectID: 8, titles: titles, inboxProjectID: 1, hiddenProjectID: 7),
            "How to make a CPU?"
        )
        XCTAssertNil(ThingsRowMapper.projectLine(forProjectID: 99, titles: titles, inboxProjectID: 1, hiddenProjectID: nil))
    }

    func testApplyingProjectLineSetsTheSecondRowLine() {
        let rows = [task(1, position: 1, project: 8)].map { task in
            ThingsDisplayRow(task: task, model: ThingsTodoRowModel(id: String(task.id), title: task.title))
        }
        let projects = [Project(id: 8, title: "Work")]
        let mapped = ThingsRowMapper.applyingProjectLine(to: rows, projects: projects, inboxProjectID: nil)
        XCTAssertEqual(mapped.first?.model.projectLine, "Work")
        XCTAssertTrue(mapped.first?.model.hasProjectLine ?? false)
    }
}
