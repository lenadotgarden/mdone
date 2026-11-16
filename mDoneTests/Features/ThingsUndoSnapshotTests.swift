import XCTest
@testable import mDone

/// What Undo Delete needs to bring a to-do back, and the stored When that Undo restores.
final class ThingsUndoSnapshotTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private func noon(_ year: Int, _ month: Int, _ day: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func task() -> VTask {
        var task = VTask(id: 7, title: "Write report", done: false, priority: 3, projectId: 42)
        task.description = "Numbers from finance"
        task.dueDate = noon(2026, 11, 20)
        task.startDate = noon(2026, 11, 17)
        task.labels = [VLabel(id: 1, title: "Office"), VLabel(id: 2, title: ThingsReservedLabels.evening)]
        task.repeatAfter = 604_800
        task.repeatMode = 0
        return task
    }

    func testSnapshotKeepsEveryFieldThatUndoDeleteRestores() {
        let snapshot = ThingsTaskSnapshot(task: task(), calendar: utc)
        XCTAssertEqual(snapshot.title, "Write report")
        XCTAssertEqual(snapshot.description, "Numbers from finance")
        XCTAssertEqual(snapshot.dueDate, noon(2026, 11, 20))
        XCTAssertEqual(snapshot.startDate, noon(2026, 11, 17))
        XCTAssertEqual(snapshot.priority, 3)
        XCTAssertEqual(snapshot.projectID, 42)
        XCTAssertEqual(snapshot.labelIDs, [1, 2])
        XCTAssertEqual(snapshot.repeatAfter, 604_800)
        XCTAssertTrue(snapshot.hasRepeat)
        XCTAssertFalse(snapshot.done)
        XCTAssertTrue(snapshot.checklist.isEmpty)
    }

    func testChecklistItemsComeBackInOrderWithTheirState() {
        var parent = task()
        var first = VTask(id: 8, title: "Draft", done: true, priority: 0, projectId: 42)
        first.position = 1
        var second = VTask(id: 9, title: "Review", done: false, priority: 0, projectId: 42)
        second.position = 2
        parent.relatedTasks = [RelationKind.subtask.rawValue: [second, first]]
        let snapshot = ThingsTaskSnapshot(task: parent, calendar: utc)
        XCTAssertEqual(snapshot.checklist, [
            ThingsTaskSnapshot.ChecklistItem(title: "Draft", done: true),
            ThingsTaskSnapshot.ChecklistItem(title: "Review", done: false)
        ])
    }

    func testAZeroDateIsNotACopiedDate() {
        var plain = VTask(id: 1, title: "x", done: false, priority: 0, projectId: 1)
        plain.dueDate = Date(timeIntervalSince1970: -62_135_596_800)
        plain.startDate = Date(timeIntervalSince1970: -62_135_596_800)
        let snapshot = ThingsTaskSnapshot(task: plain, calendar: utc)
        XCTAssertNil(snapshot.dueDate)
        XCTAssertNil(snapshot.startDate)
        XCTAssertFalse(snapshot.hasRepeat)
    }

    func testWhenStateReadsTheStartDateAndTheReservedLabels() {
        let state = ThingsWhenState(task: task(), calendar: utc)
        XCTAssertEqual(state.startDate, noon(2026, 11, 17))
        XCTAssertTrue(state.isEvening)
        XCTAssertFalse(state.isSomeday)

        var someday = VTask(id: 2, title: "y", done: false, priority: 0, projectId: 1)
        someday.labels = [VLabel(id: 5, title: ThingsReservedLabels.someday)]
        let other = ThingsWhenState(task: someday, calendar: utc)
        XCTAssertNil(other.startDate)
        XCTAssertTrue(other.isSomeday)
        XCTAssertNotEqual(state, other)
    }
}
