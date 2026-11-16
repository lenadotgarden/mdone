import XCTest
@testable import mDone

/// Drag and drop of the Things UI: insertion slot from the pointer, plans, moves between
/// sections, optimistic arrangement, sidebar drop resolution and the payload.
final class ThingsDropPlanTests: XCTestCase {
    private func task(_ id: Int64, position: Double?, project: Int64 = 7) -> VTask {
        var task = VTask(id: id, title: "Task \(id)", done: false, priority: 0, projectId: project)
        task.position = position
        return task
    }

    private func row(_ task: VTask) -> ThingsDisplayRow {
        ThingsDisplayRow(task: task, model: ThingsTodoRowModel(id: String(task.id), title: task.title))
    }

    /// Three rows of 40 pt in section "a", a 30 pt header gap, then two rows in "b".
    private var layout: (sections: [ThingsDropLayoutSection], frames: [Int64: ThingsDropRowFrame]) {
        let sections = [
            ThingsDropLayoutSection(id: "a", rowIDs: [1, 2, 3]),
            ThingsDropLayoutSection(id: "b", rowIDs: [4, 5])
        ]
        let frames: [Int64: ThingsDropRowFrame] = [
            1: ThingsDropRowFrame(minY: 0, maxY: 40),
            2: ThingsDropRowFrame(minY: 40, maxY: 80),
            3: ThingsDropRowFrame(minY: 80, maxY: 120),
            4: ThingsDropRowFrame(minY: 150, maxY: 190),
            5: ThingsDropRowFrame(minY: 190, maxY: 230)
        ]
        return (sections, frames)
    }

    private func slot(at y: CGFloat) -> ThingsDropSlot? {
        let data = layout
        return ThingsDropGeometry.slot(sections: data.sections, frames: data.frames, pointerY: y)
    }

    // MARK: - Slot from the pointer

    func testPointerInTheUpperHalfOfARowInsertsAboveIt() {
        XCTAssertEqual(slot(at: 45), ThingsDropSlot(sectionID: "a", index: 1))
        XCTAssertEqual(slot(at: 2), ThingsDropSlot(sectionID: "a", index: 0))
    }

    func testPointerInTheLowerHalfOfARowInsertsBelowIt() {
        XCTAssertEqual(slot(at: 70), ThingsDropSlot(sectionID: "a", index: 2))
        XCTAssertEqual(slot(at: 118), ThingsDropSlot(sectionID: "a", index: 3))
    }

    func testPointerAboveEverythingIsTheTopSlot() {
        XCTAssertEqual(slot(at: -50), ThingsDropSlot(sectionID: "a", index: 0))
    }

    func testPointerBelowEverythingIsTheEndOfTheLastSection() {
        XCTAssertEqual(slot(at: 500), ThingsDropSlot(sectionID: "b", index: 2))
    }

    func testTheGapBetweenSectionsPicksTheNearerSide() {
        // The gap is 120 to 150, the boundary 135.
        XCTAssertEqual(slot(at: 125), ThingsDropSlot(sectionID: "a", index: 3))
        XCTAssertEqual(slot(at: 145), ThingsDropSlot(sectionID: "b", index: 0))
    }

    func testRowsWithoutAFrameAreSkippedButKeepTheirIndex() {
        let data = layout
        var frames = data.frames
        frames[1] = nil
        frames[2] = nil
        let result = ThingsDropGeometry.slot(sections: data.sections, frames: frames, pointerY: 85)
        XCTAssertEqual(result, ThingsDropSlot(sectionID: "a", index: 2))
    }

    func testNoFramesGivesNoSlot() {
        let data = layout
        XCTAssertNil(ThingsDropGeometry.slot(sections: data.sections, frames: [:], pointerY: 10))
        XCTAssertNil(ThingsDropGeometry.slot(sections: [], frames: data.frames, pointerY: 10))
    }

    func testOnlyTheGivenSectionsCount() {
        let data = layout
        let onlyB = [data.sections[1]]
        // The pointer over section "a" snaps to the top of "b".
        XCTAssertEqual(
            ThingsDropGeometry.slot(sections: onlyB, frames: data.frames, pointerY: 60),
            ThingsDropSlot(sectionID: "b", index: 0)
        )
    }

    // MARK: - Shift of the rows

    func testRowsBetweenTheSourceAndTheSlotCloseUpWhenDraggedDown() {
        let source = ThingsDropSource(sectionID: "a", index: 0)
        let target = ThingsDropSlot(sectionID: "a", index: 3)
        let shifts = (0..<3).map {
            ThingsDropGeometry.shift(forRowAt: $0, in: "a", source: source, slot: target, rowHeight: 40)
        }
        XCTAssertEqual(shifts, [0, -40, -40])
    }

    func testRowsBetweenTheSlotAndTheSourceOpenUpWhenDraggedUp() {
        let source = ThingsDropSource(sectionID: "a", index: 2)
        let target = ThingsDropSlot(sectionID: "a", index: 0)
        let shifts = (0..<3).map {
            ThingsDropGeometry.shift(forRowAt: $0, in: "a", source: source, slot: target, rowHeight: 40)
        }
        XCTAssertEqual(shifts, [40, 40, 0])
    }

    func testNothingMovesWhenTheSlotIsNextToTheSource() {
        let source = ThingsDropSource(sectionID: "a", index: 1)
        for index in [1, 2] {
            let target = ThingsDropSlot(sectionID: "a", index: index)
            let shifts = (0..<3).map {
                ThingsDropGeometry.shift(forRowAt: $0, in: "a", source: source, slot: target, rowHeight: 40)
            }
            XCTAssertEqual(shifts, [0, 0, 0])
        }
    }

    func testAcrossSectionsTheTargetOpensAndTheSourceCloses() {
        let source = ThingsDropSource(sectionID: "a", index: 0)
        let target = ThingsDropSlot(sectionID: "b", index: 1)
        XCTAssertEqual(ThingsDropGeometry.shift(forRowAt: 1, in: "a", source: source, slot: target, rowHeight: 40), -40)
        XCTAssertEqual(ThingsDropGeometry.shift(forRowAt: 0, in: "b", source: source, slot: target, rowHeight: 40), 0)
        XCTAssertEqual(ThingsDropGeometry.shift(forRowAt: 1, in: "b", source: source, slot: target, rowHeight: 40), 40)
    }

    // MARK: - Plans

    private var sections: [ThingsSectionTasks] {
        [
            ThingsSectionTasks(id: ThingsSectionID.todayNormal, tasks: [task(1, position: 100), task(2, position: 200), task(3, position: 300)]),
            ThingsSectionTasks(id: ThingsSectionID.todayEvening, tasks: [task(4, position: 400), task(5, position: 500)])
        ]
    }

    func testDropInTheSameSectionIsAReorder() throws {
        let slot = ThingsDropSlot(sectionID: ThingsSectionID.todayNormal, index: 3)
        let plan = try XCTUnwrap(ThingsDropPlan.make(slot: slot, movingID: 1, sections: sections))
        guard case .reorder(let reorder) = plan else { return XCTFail("expected a reorder") }
        XCTAssertEqual(reorder.reorderedIDs, [2, 3, 1])
        XCTAssertEqual(plan.overrides, [ThingsSectionID.todayNormal: [2, 3, 1]])
    }

    func testDropWhereItWasIsNil() {
        let same = ThingsDropSlot(sectionID: ThingsSectionID.todayNormal, index: 1)
        XCTAssertNil(ThingsDropPlan.make(slot: same, movingID: 2, sections: sections))
        let after = ThingsDropSlot(sectionID: ThingsSectionID.todayNormal, index: 2)
        XCTAssertNil(ThingsDropPlan.make(slot: after, movingID: 2, sections: sections))
    }

    func testDropInThisEveningChangesTheWhenAndSitsBetweenItsNeighbours() throws {
        let slot = ThingsDropSlot(sectionID: ThingsSectionID.todayEvening, index: 1)
        let plan = try XCTUnwrap(ThingsDropPlan.make(slot: slot, movingID: 2, sections: sections))
        guard case .changeSection(let move) = plan else { return XCTFail("expected a section move") }
        XCTAssertEqual(move.when, ThingsWhen.thisEvening)
        XCTAssertEqual(move.position, 450, accuracy: 0.0001)
        XCTAssertEqual(move.toReordered.map { $0.id }, [4, 2, 5])
        XCTAssertEqual(move.fromIDs, [1, 3])
        XCTAssertEqual(plan.overrides, [
            ThingsSectionID.todayNormal: [1, 3],
            ThingsSectionID.todayEvening: [4, 2, 5]
        ])
    }

    func testDropAtTheEndOfTodayFromThisEveningSchedulesToday() throws {
        let slot = ThingsDropSlot(sectionID: ThingsSectionID.todayNormal, index: 3)
        let plan = try XCTUnwrap(ThingsDropPlan.make(slot: slot, movingID: 5, sections: sections))
        guard case .changeSection(let move) = plan else { return XCTFail("expected a section move") }
        XCTAssertEqual(move.when, ThingsWhen.today)
        XCTAssertEqual(move.position, 300 + TaskPositioning.endGap, accuracy: 0.0001)
    }

    func testMovesBetweenUnrelatedSectionsAreRefused() {
        let data = [
            ThingsSectionTasks(id: ThingsSectionID.todayOverdue, tasks: [task(1, position: 1)]),
            ThingsSectionTasks(id: ThingsSectionID.todayNormal, tasks: [task(2, position: 2)])
        ]
        let slot = ThingsDropSlot(sectionID: ThingsSectionID.todayNormal, index: 0)
        XCTAssertNil(ThingsDropPlan.make(slot: slot, movingID: 1, sections: data))
        XCTAssertNil(ThingsDropPlan.make(slot: slot, movingID: 99, sections: data))
        XCTAssertNil(ThingsDropPlan.make(slot: ThingsDropSlot(sectionID: "nope", index: 0), movingID: 2, sections: data))
    }

    // MARK: - Section rules

    func testSectionRoles() {
        XCTAssertEqual(ThingsSectionID.role(of: "today.normal"), .todayNormal)
        XCTAssertEqual(ThingsSectionID.role(of: "today.evening"), .todayEvening)
        XCTAssertEqual(ThingsSectionID.role(of: ThingsSectionID.project(12)), .projectMain(12))
        XCTAssertEqual(ThingsSectionID.role(of: ThingsSectionID.projectSomeday(12)), .projectSomeday(12))
        XCTAssertEqual(ThingsSectionID.role(of: ThingsSectionID.projectUpcoming(12)), .other)
        XCTAssertEqual(ThingsSectionID.role(of: ThingsSectionID.projectLogged(12)), .other)
        XCTAssertEqual(ThingsSectionID.role(of: "inbox"), .other)
    }

    func testProjectMainAndSomedayGroupAreLinkedOnlyWithinTheSameProject() {
        XCTAssertEqual(
            ThingsDropRules.when(from: ThingsSectionID.project(3), to: ThingsSectionID.projectSomeday(3)),
            ThingsWhen.someday
        )
        XCTAssertEqual(
            ThingsDropRules.when(from: ThingsSectionID.projectSomeday(3), to: ThingsSectionID.project(3)),
            ThingsWhen.none
        )
        XCTAssertNil(ThingsDropRules.when(from: ThingsSectionID.project(3), to: ThingsSectionID.projectSomeday(4)))
        XCTAssertNil(ThingsDropRules.when(from: ThingsSectionID.project(3), to: ThingsSectionID.projectUpcoming(3)))
        XCTAssertNil(ThingsDropRules.when(from: ThingsSectionID.todayNormal, to: ThingsSectionID.todayNormal))
        XCTAssertNil(ThingsDropRules.when(from: ThingsSectionID.todayOverdue, to: ThingsSectionID.todayEvening))
    }

    func testMovesListsTheReachableSectionsInOrder() {
        let ids = [ThingsSectionID.todayOverdue, ThingsSectionID.todayNormal, ThingsSectionID.todayEvening]
        XCTAssertEqual(
            ThingsDropRules.moves(from: ThingsSectionID.todayNormal, among: ids),
            [ThingsSectionMove(sectionID: ThingsSectionID.todayEvening, when: ThingsWhen.thisEvening)]
        )
        XCTAssertEqual(ThingsDropRules.moves(from: ThingsSectionID.todayOverdue, among: ids), [])
    }

    // MARK: - Optimistic arrangement

    func testArrangementReordersInsideASection() {
        let rows = [[1, 2, 3].map { row(task($0, position: Double($0))) }]
        let result = ThingsDropArrangement.rows(
            for: [(id: "a", rows: rows[0])],
            overrides: ["a": [3, 1, 2]]
        )
        XCTAssertEqual(result[0].map { $0.task.id }, [3, 1, 2])
    }

    func testArrangementMovesARowAcrossSections() {
        let a = [1, 2, 3].map { row(task($0, position: Double($0))) }
        let b = [4, 5].map { row(task($0, position: Double($0))) }
        let result = ThingsDropArrangement.rows(
            for: [(id: "a", rows: a), (id: "b", rows: b)],
            overrides: ["a": [1, 3], "b": [4, 2, 5]]
        )
        XCTAssertEqual(result[0].map { $0.task.id }, [1, 3])
        XCTAssertEqual(result[1].map { $0.task.id }, [4, 2, 5])
    }

    func testArrangementCanEmptyASection() {
        let a = [row(task(1, position: 1))]
        let b = [row(task(2, position: 2))]
        let result = ThingsDropArrangement.rows(
            for: [(id: "a", rows: a), (id: "b", rows: b)],
            overrides: ["a": [], "b": [2, 1]]
        )
        XCTAssertEqual(result[0].map { $0.task.id }, [])
        XCTAssertEqual(result[1].map { $0.task.id }, [2, 1])
    }

    func testArrangementKeepsRowsTheOverrideDoesNotKnow() {
        let a = [1, 2].map { row(task($0, position: Double($0))) }
        let result = ThingsDropArrangement.rows(for: [(id: "a", rows: a)], overrides: ["a": [2]])
        XCTAssertEqual(result[0].map { $0.task.id }, [2, 1])
    }

    // MARK: - Sidebar drops

    private func facts(
        project: Int64? = 7,
        when: ThingsWhen? = ThingsWhen.none,
        inbox: Int64? = 1,
        canReparent: Bool = true
    ) -> ThingsDropFacts {
        ThingsDropFacts(taskProjectID: project, taskWhen: when, inboxProjectID: inbox, canReparent: canReparent)
    }

    func testTodoOnAProjectMovesItUnlessItIsThere() {
        XCTAssertEqual(
            ThingsDropResolver.action(for: .todo(5), on: .project(9), facts: facts()),
            .moveTodo(taskID: 5, toProject: 9)
        )
        XCTAssertNil(ThingsDropResolver.action(for: .todo(5), on: .project(7), facts: facts()))
        XCTAssertNil(ThingsDropResolver.action(for: .todo(5), on: .project(9), facts: facts(project: nil)))
    }

    func testTodoOnInboxTodayAndSomeday() {
        XCTAssertEqual(
            ThingsDropResolver.action(for: .todo(5), on: .list(.inbox), facts: facts()),
            .moveTodo(taskID: 5, toProject: 1)
        )
        XCTAssertNil(ThingsDropResolver.action(for: .todo(5), on: .list(.inbox), facts: facts(project: 1)))
        XCTAssertNil(ThingsDropResolver.action(for: .todo(5), on: .list(.inbox), facts: facts(inbox: nil)))
        XCTAssertEqual(
            ThingsDropResolver.action(for: .todo(5), on: .list(.today), facts: facts()),
            .scheduleTodo(taskID: 5, when: ThingsWhen.today)
        )
        XCTAssertEqual(
            ThingsDropResolver.action(for: .todo(5), on: .list(.today), facts: facts(when: ThingsWhen.thisEvening)),
            .scheduleTodo(taskID: 5, when: ThingsWhen.today)
        )
        XCTAssertNil(ThingsDropResolver.action(for: .todo(5), on: .list(.today), facts: facts(when: ThingsWhen.today)))
        XCTAssertEqual(
            ThingsDropResolver.action(for: .todo(5), on: .list(.someday), facts: facts()),
            .scheduleTodo(taskID: 5, when: ThingsWhen.someday)
        )
        XCTAssertNil(ThingsDropResolver.action(for: .todo(5), on: .list(.someday), facts: facts(when: ThingsWhen.someday)))
    }

    func testTodoOnOtherListsIsRefused() {
        for list in [ThingsList.upcoming, ThingsList.anytime, ThingsList.logbook] {
            XCTAssertNil(ThingsDropResolver.action(for: .todo(5), on: .list(list), facts: facts()))
        }
    }

    func testProjectOnlyGoesOntoAProjectAndOnlyWhenLegal() {
        XCTAssertEqual(
            ThingsDropResolver.action(for: .project(3), on: .project(9), facts: facts()),
            .reparentProject(projectID: 3, toParent: 9)
        )
        XCTAssertNil(ThingsDropResolver.action(for: .project(3), on: .project(9), facts: facts(canReparent: false)))
        XCTAssertNil(ThingsDropResolver.action(for: .project(3), on: .list(.today), facts: facts()))
    }

    // MARK: - Payload

    func testPayloadAccessorsAndRoundTrip() {
        XCTAssertEqual(ThingsDragPayload.todo(4).todoID, 4)
        XCTAssertNil(ThingsDragPayload.todo(4).projectID)
        XCTAssertEqual(ThingsDragPayload.project(8).projectID, 8)
        XCTAssertNil(ThingsDragPayload.project(8).todoID)
        XCTAssertEqual(ThingsDragPayload(encoded: ThingsDragPayload.todo(4).encoded), .todo(4))
    }

    func testTheItemProviderCarriesTheEncodedPayloadAsText() {
        let provider = ThingsDragItem.provider(for: .todo(42))
        XCTAssertTrue(provider.canLoadObject(ofClass: String.self))
    }
}
