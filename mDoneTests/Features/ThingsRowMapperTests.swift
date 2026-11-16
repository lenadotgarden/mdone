import XCTest
@testable import mDone

final class ThingsRowMapperTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: 0)
        return utc.date(from: components)!
    }

    /// Monday 2026-11-16 at 10:00 UTC.
    private var now: Date { date(2026, 11, 16, 10) }

    private func makeTask(
        id: Int64 = 1,
        done: Bool = false,
        due: Date? = nil,
        start: Date? = nil,
        labels: [String] = [],
        description: String? = nil,
        subtasks: [VTask] = []
    ) -> VTask {
        var task = VTask(id: id, title: "Task \(id)", done: done, priority: 0, projectId: 1)
        task.dueDate = due
        task.startDate = start
        task.description = description
        if !labels.isEmpty {
            task.labels = labels.enumerated().map { VLabel(id: Int64($0.offset + 100), title: $0.element) }
        }
        if !subtasks.isEmpty {
            task.relatedTasks = ["subtask": subtasks]
        }
        return task
    }

    // MARK: - Row model

    func testPlainTaskMapsToOpenRow() {
        let model = ThingsRowMapper.model(for: makeTask(), list: .inbox, now: now, calendar: utc)
        XCTAssertEqual(model.id, "1")
        XCTAssertEqual(model.title, "Task 1")
        XCTAssertEqual(model.checkbox, .open)
        XCTAssertFalse(model.hasNotes)
        XCTAssertTrue(model.tags.isEmpty)
        XCTAssertNil(model.deadlineDaysRemaining)
        XCTAssertNil(model.checklistLabel)
        XCTAssertFalse(model.showsTodayStar)
    }

    func testReservedLabelsAreNotTags() {
        let task = makeTask(labels: ["Home", "things:evening", " THINGS:SOMEDAY ", "things:cancelled", "Errand"])
        XCTAssertEqual(ThingsRowMapper.tags(for: task), ["Home", "Errand"])
    }

    func testDeadlineDaysRemaining() {
        let ahead = makeTask(due: date(2026, 11, 19))
        let today = makeTask(due: date(2026, 11, 16))
        let past = makeTask(due: date(2026, 11, 14))
        XCTAssertEqual(ThingsRowMapper.model(for: ahead, list: nil, now: now, calendar: utc).deadlineDaysRemaining, 3)
        XCTAssertEqual(ThingsRowMapper.model(for: today, list: nil, now: now, calendar: utc).deadlineDaysRemaining, 0)
        XCTAssertEqual(ThingsRowMapper.model(for: past, list: nil, now: now, calendar: utc).deadlineDaysRemaining, -2)
    }

    func testDoneTaskHasNoDeadlineBadge() {
        let task = makeTask(done: true, due: date(2026, 11, 14))
        let model = ThingsRowMapper.model(for: task, list: .logbook, now: now, calendar: utc)
        XCTAssertEqual(model.checkbox, .done)
        XCTAssertNil(model.deadlineDaysRemaining)
    }

    func testCancelledLabelGivesCancelledCheckboxOnlyWhenDone() {
        let finished = makeTask(done: true, labels: ["things:cancelled"])
        let open = makeTask(done: false, labels: ["things:cancelled"])
        XCTAssertEqual(ThingsRowMapper.checkboxState(for: finished, isPendingDone: false), .cancelled)
        XCTAssertEqual(ThingsRowMapper.checkboxState(for: open, isPendingDone: false), .open)
    }

    func testPendingDoneShowsDone() {
        let task = makeTask()
        XCTAssertEqual(ThingsRowMapper.checkboxState(for: task, isPendingDone: true), .done)
    }

    func testChecklistLabel() {
        var finished = makeTask(id: 10, done: true)
        finished.relatedTasks = ["parenttask": [makeTask(id: 1)]]
        let open = makeTask(id: 11)
        let parent = makeTask(id: 1, subtasks: [finished, open])
        let model = ThingsRowMapper.model(for: parent, list: .anytime, now: now, calendar: utc)
        XCTAssertEqual(model.checklistLabel, "1/2")
    }

    func testNotesDetection() {
        XCTAssertFalse(ThingsRowMapper.hasNotes(makeTask(description: nil)))
        XCTAssertFalse(ThingsRowMapper.hasNotes(makeTask(description: "  \n")))
        XCTAssertFalse(ThingsRowMapper.hasNotes(makeTask(description: "<p></p>")))
        XCTAssertTrue(ThingsRowMapper.hasNotes(makeTask(description: "Call before noon")))
    }

    func testTodayStarOnlyInAnytimeAndProjects() {
        let task = makeTask(start: date(2026, 11, 16))
        XCTAssertTrue(ThingsRowMapper.model(for: task, list: .anytime, now: now, calendar: utc).showsTodayStar)
        XCTAssertTrue(ThingsRowMapper.model(for: task, list: nil, now: now, calendar: utc).showsTodayStar)
        XCTAssertFalse(ThingsRowMapper.model(for: task, list: .today, now: now, calendar: utc).showsTodayStar)
        let later = makeTask(start: date(2026, 11, 20))
        XCTAssertFalse(ThingsRowMapper.model(for: later, list: .anytime, now: now, calendar: utc).showsTodayStar)
    }

    func testSomedayTaskIsDimmedOutsideSomedayList() {
        let task = makeTask(labels: ["things:someday"])
        XCTAssertTrue(ThingsRowMapper.model(for: task, list: nil, now: now, calendar: utc).isDimmed)
        XCTAssertFalse(ThingsRowMapper.model(for: task, list: .someday, now: now, calendar: utc).isDimmed)
    }

    // MARK: - Sections

    func testDisplaySectionsKeepIdsKindsAndPendingState() {
        let first = makeTask(id: 1)
        let second = makeTask(id: 2)
        let sections = [
            ThingsListSection(id: "today.normal", kind: .normal, tasks: [first]),
            ThingsListSection(id: "today.evening", kind: .evening, tasks: [second])
        ]
        let mapped = ThingsRowMapper.displaySections(
            sections, list: .today, pendingDone: [2], now: now, calendar: utc
        )
        XCTAssertEqual(mapped.map { $0.id }, ["today.normal", "today.evening"])
        XCTAssertEqual(mapped[1].kind, .evening)
        XCTAssertEqual(mapped[0].rows.first?.model.checkbox, .open)
        XCTAssertEqual(mapped[1].rows.first?.model.checkbox, .done)
        XCTAssertEqual(mapped[1].rows.first?.task.id, 2)
    }

    func testHeaderStyles() {
        XCTAssertNil(ThingsRowMapper.headerStyle(for: .normal, list: .today, now: now, calendar: utc))
        XCTAssertEqual(
            ThingsRowMapper.headerStyle(for: .evening, list: .today, now: now, calendar: utc),
            .evening(title: "This Evening")
        )
        let tomorrow = utc.startOfDay(for: date(2026, 11, 17))
        XCTAssertEqual(
            ThingsRowMapper.headerStyle(for: .dateGroup(tomorrow), list: .upcoming, now: now, calendar: utc),
            .upcomingDay(day: "17", label: "Tomorrow")
        )
        XCTAssertEqual(
            ThingsRowMapper.headerStyle(for: .dateGroup(tomorrow), list: .logbook, now: now, calendar: utc),
            .standard(title: "Tomorrow")
        )
    }

    func testDayLabels() {
        let today = utc.startOfDay(for: now)
        let yesterday = utc.startOfDay(for: date(2026, 11, 15))
        XCTAssertEqual(ThingsRowMapper.dayLabel(for: today, now: now, calendar: utc), "Today")
        XCTAssertEqual(ThingsRowMapper.dayLabel(for: yesterday, now: now, calendar: utc), "Yesterday")
    }
}
