import XCTest
@testable import mDone

final class ThingsListBuilderTests: XCTestCase {
    private let inboxID: Int64 = 1
    private let otherID: Int64 = 2

    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    private let paris: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris") ?? TimeZone(secondsFromGMT: 3600) ?? .current
        return calendar
    }()

    // MARK: - Helpers

    /// A local date in `calendar`. Defaults to the 12:00 full-day convention.
    private func date(
        _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, _ second: Int = 0,
        in calendar: Calendar
    ) -> Date {
        let components = DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        )
        return calendar.date(from: components)!
    }

    /// Monday 2026-11-16 at 10:00 in `calendar`.
    private func now(in calendar: Calendar) -> Date {
        date(2026, 11, 16, 10, 0, in: calendar)
    }

    private func makeTask(
        id: Int64,
        project: Int64? = nil,
        done: Bool = false,
        start: Date? = nil,
        due: Date? = nil,
        doneAt: Date? = nil,
        updated: Date? = nil,
        labels: [String] = [],
        repeatAfter: Int64? = nil,
        position: Double? = nil
    ) -> VTask {
        var task = VTask(id: id, title: "Task \(id)", done: done, priority: 0, projectId: project ?? otherID)
        task.startDate = start
        task.dueDate = due
        task.doneAt = doneAt
        task.updated = updated
        task.repeatAfter = repeatAfter
        task.position = position
        if !labels.isEmpty {
            task.labels = labels.enumerated().map { VLabel(id: Int64($0.offset + 100), title: $0.element) }
        }
        return task
    }

    private func sections(
        _ list: ThingsList,
        _ tasks: [VTask],
        calendar: Calendar? = nil,
        at moment: Date? = nil,
        inbox: Int64? = 1
    ) -> [ThingsListSection] {
        let cal = calendar ?? utc
        return ThingsListBuilder.sections(
            for: list, tasks: tasks, inboxProjectID: inbox, now: moment ?? now(in: cal), calendar: cal
        )
    }

    private func ids(_ built: [ThingsListSection]) -> [Int64] {
        built.flatMap { $0.tasks.map { $0.id } }
    }

    private func sectionIDs(_ section: ThingsListSection?) -> [Int64] {
        (section?.tasks ?? []).map { $0.id }
    }

    private func section(_ built: [ThingsListSection], _ kind: ThingsListSection.Kind) -> ThingsListSection? {
        built.first { $0.kind == kind }
    }

    // MARK: - Reserved labels

    func testReservedLabelsMatchCaseInsensitivelyAndTrimmed() {
        let task = makeTask(id: 1, labels: ["Things:Evening", "  THINGS:someday "])
        XCTAssertTrue(task.hasThingsEveningLabel)
        XCTAssertTrue(task.hasThingsSomedayLabel)
        XCTAssertFalse(task.hasThingsCancelledLabel)
        XCTAssertTrue(makeTask(id: 2, labels: ["things:cancelled"]).hasThingsCancelledLabel)
        XCTAssertFalse(makeTask(id: 3, labels: ["evening"]).hasThingsEveningLabel)
        XCTAssertFalse(makeTask(id: 4).hasThingsSomedayLabel)
    }

    func testIsReserved() {
        XCTAssertTrue(ThingsReservedLabels.isReserved("things:evening"))
        XCTAssertTrue(ThingsReservedLabels.isReserved("Things:Cancelled"))
        XCTAssertFalse(ThingsReservedLabels.isReserved("Current"))
    }

    // MARK: - Inbox

    func testInboxHoldsOpenInboxTasksWithoutWhen() {
        let tasks = [
            makeTask(id: 1, project: inboxID),
            makeTask(id: 2, project: inboxID, due: date(2026, 12, 1, in: utc)),
            makeTask(id: 3, project: inboxID, start: date(2026, 11, 16, in: utc)),
            makeTask(id: 4, project: inboxID, labels: ["things:someday"]),
            makeTask(id: 5, project: inboxID, labels: ["things:evening"]),
            makeTask(id: 6, project: otherID),
            makeTask(id: 7, project: inboxID, done: true),
        ]
        XCTAssertEqual(ids(sections(.inbox, tasks)), [1, 2])
    }

    func testInboxEmptyWithoutInboxProject() {
        let tasks = [makeTask(id: 1, project: inboxID)]
        XCTAssertTrue(sections(.inbox, tasks, inbox: nil).isEmpty)
    }

    func testInboxIgnoresZeroStartDate() {
        let tasks = [makeTask(id: 1, project: inboxID, start: Date.distantPast)]
        XCTAssertEqual(ids(sections(.inbox, tasks)), [1])
    }

    // MARK: - Today

    func testTodayIncludesStartTodayAndPastStart() {
        let tasks = [
            makeTask(id: 1, start: date(2026, 11, 16, in: utc)),
            makeTask(id: 2, start: date(2026, 11, 10, in: utc)),
            makeTask(id: 3, start: date(2026, 11, 17, in: utc)),
            makeTask(id: 4),
        ]
        let built = sections(.today, tasks)
        XCTAssertEqual(built.count, 1)
        XCTAssertEqual(built.first?.kind, ThingsListSection.Kind.normal)
        XCTAssertEqual(ids(built), [1, 2])
    }

    func testTodayIncludesDeadlineTodayAndOverdueSeparately() {
        let tasks = [
            makeTask(id: 1, due: date(2026, 11, 16, in: utc)),
            makeTask(id: 2, due: date(2026, 11, 14, in: utc)),
            makeTask(id: 3, due: date(2026, 11, 20, in: utc)),
        ]
        let built = sections(.today, tasks)
        XCTAssertEqual(built.map { $0.kind }, [.overdue, .normal])
        XCTAssertEqual(sectionIDs(section(built, .overdue)), [2])
        XCTAssertEqual(sectionIDs(section(built, .normal)), [1])
    }

    func testPastStartAloneIsNotOverdue() {
        let tasks = [makeTask(id: 1, start: date(2026, 11, 10, in: utc))]
        XCTAssertEqual(sections(.today, tasks).map { $0.kind }, [.normal])
    }

    func testTodayEveningSection() {
        let tasks = [
            makeTask(id: 1, start: date(2026, 11, 16, in: utc)),
            makeTask(id: 2, start: date(2026, 11, 16, in: utc), labels: ["things:evening"]),
            makeTask(id: 3, due: date(2026, 11, 16, in: utc), labels: ["Things:Evening"]),
        ]
        let built = sections(.today, tasks)
        XCTAssertEqual(built.map { $0.kind }, [.normal, .evening])
        XCTAssertEqual(sectionIDs(section(built, .normal)), [1])
        XCTAssertEqual(sectionIDs(section(built, .evening)), [2, 3])
    }

    func testEveningTaskForFutureDayIsNotInTodayYet() {
        let tasks = [makeTask(id: 1, start: date(2026, 11, 18, in: utc), labels: ["things:evening"])]
        XCTAssertTrue(sections(.today, tasks).isEmpty)
        XCTAssertEqual(ids(sections(.upcoming, tasks)), [1])
    }

    func testTodayRepeatingTaskFollowsItsCurrentDates() {
        let tasks = [
            makeTask(id: 1, due: date(2026, 11, 16, in: utc), repeatAfter: 86400),
            makeTask(id: 2, due: date(2026, 11, 17, in: utc), repeatAfter: 86400),
        ]
        XCTAssertEqual(ids(sections(.today, tasks)), [1])
    }

    func testTodayExcludesSomedayAndDone() {
        let tasks = [
            makeTask(id: 1, start: date(2026, 11, 16, in: utc), labels: ["things:someday"]),
            makeTask(id: 2, done: true, start: date(2026, 11, 16, in: utc)),
            makeTask(id: 3, done: true, due: date(2026, 11, 10, in: utc)),
        ]
        XCTAssertTrue(sections(.today, tasks).isEmpty)
    }

    func testTodayTreatsZeroDatesAsUnset() {
        let tasks = [makeTask(id: 1, start: Date.distantPast, due: Date.distantPast)]
        XCTAssertTrue(sections(.today, tasks).isEmpty)
    }

    func testTodayOrdersByPositionThenId() {
        let day = date(2026, 11, 16, in: utc)
        let tasks = [
            makeTask(id: 3, start: day, position: 20),
            makeTask(id: 2, start: day),
            makeTask(id: 1, start: day, position: 10),
            makeTask(id: 4, start: day),
        ]
        XCTAssertEqual(ids(sections(.today, tasks)), [1, 3, 2, 4])
    }

    // MARK: - Midnight boundaries

    func testLastSecondOfTodayIsTodayAndFirstSecondOfTomorrowIsNot() {
        for calendar in [utc, paris] {
            let tasks = [
                makeTask(id: 1, start: date(2026, 11, 16, 23, 59, 59, in: calendar)),
                makeTask(id: 2, start: date(2026, 11, 17, 0, 0, 0, in: calendar)),
                makeTask(id: 3, start: date(2026, 11, 16, 0, 0, 0, in: calendar)),
            ]
            XCTAssertEqual(ids(sections(.today, tasks, calendar: calendar)), [1, 3])
            XCTAssertEqual(ids(sections(.upcoming, tasks, calendar: calendar)), [2])
        }
    }

    func testSameInstantFallsOnDifferentDaysInUTCAndParis() {
        // 22:30Z is 22:30 on Nov 16 in UTC and 23:30 on Nov 16 in Paris.
        // 23:30Z is still Nov 16 in UTC but 00:30 on Nov 17 in Paris.
        let moment = date(2026, 11, 16, 22, 30, in: utc)
        let task = makeTask(id: 1, start: date(2026, 11, 16, 23, 30, in: utc))
        XCTAssertEqual(ids(sections(.today, [task], calendar: utc, at: moment)), [1])
        XCTAssertTrue(sections(.today, [task], calendar: paris, at: moment).isEmpty)
        XCTAssertEqual(ids(sections(.upcoming, [task], calendar: paris, at: moment)), [1])
    }

    func testAtMidnightTheNewDayPullsStartedTasksIntoToday() {
        let task = makeTask(id: 1, start: date(2026, 11, 17, in: paris))
        let before = date(2026, 11, 16, 23, 59, 59, in: paris)
        let after = date(2026, 11, 17, 0, 0, 0, in: paris)
        XCTAssertTrue(sections(.today, [task], calendar: paris, at: before).isEmpty)
        XCTAssertEqual(ids(sections(.today, [task], calendar: paris, at: after)), [1])
    }

    func testDeadlineBecomesOverdueAtMidnight() {
        let task = makeTask(id: 1, due: date(2026, 11, 16, in: paris))
        let before = date(2026, 11, 16, 23, 59, 59, in: paris)
        let after = date(2026, 11, 17, 0, 0, 0, in: paris)
        XCTAssertEqual(sections(.today, [task], calendar: paris, at: before).map { $0.kind }, [.normal])
        XCTAssertEqual(sections(.today, [task], calendar: paris, at: after).map { $0.kind }, [.overdue])
    }

    // MARK: - Upcoming

    func testUpcomingGroupsByDayForSevenDays() {
        let tasks = [
            makeTask(id: 1, start: date(2026, 11, 17, in: utc)),
            makeTask(id: 2, start: date(2026, 11, 17, in: utc)),
            makeTask(id: 3, start: date(2026, 11, 23, in: utc)),
            makeTask(id: 4, start: date(2026, 11, 20, in: utc)),
        ]
        let built = sections(.upcoming, tasks)
        XCTAssertEqual(built.map { $0.kind }, [
            .dateGroup(utc.startOfDay(for: date(2026, 11, 17, in: utc))),
            .dateGroup(utc.startOfDay(for: date(2026, 11, 20, in: utc))),
            .dateGroup(utc.startOfDay(for: date(2026, 11, 23, in: utc))),
        ])
        XCTAssertEqual(built.map { sectionIDs($0) }, [[1, 2], [4], [3]])
    }

    func testUpcomingGroupsByMonthBeyondSevenDays() {
        let tasks = [
            makeTask(id: 1, start: date(2026, 11, 24, in: utc)),
            makeTask(id: 2, start: date(2026, 11, 30, in: utc)),
            makeTask(id: 3, start: date(2026, 12, 5, in: utc)),
            makeTask(id: 4, start: date(2027, 1, 2, in: utc)),
            makeTask(id: 5, start: date(2026, 11, 17, in: utc)),
        ]
        let built = sections(.upcoming, tasks)
        XCTAssertEqual(built.map { $0.kind }, [
            .dateGroup(utc.startOfDay(for: date(2026, 11, 17, in: utc))),
            .monthGroup(utc.startOfDay(for: date(2026, 11, 1, in: utc))),
            .monthGroup(utc.startOfDay(for: date(2026, 12, 1, in: utc))),
            .monthGroup(utc.startOfDay(for: date(2027, 1, 1, in: utc))),
        ])
        XCTAssertEqual(built.map { sectionIDs($0) }, [[5], [1, 2], [3], [4]])
    }

    func testUpcomingDayBoundaryAtEightDays() {
        let tasks = [
            makeTask(id: 1, start: date(2026, 11, 23, in: paris)),
            makeTask(id: 2, start: date(2026, 11, 24, in: paris)),
        ]
        let built = sections(.upcoming, tasks, calendar: paris)
        XCTAssertEqual(built.count, 2)
        if case .dateGroup = built[0].kind {} else { XCTFail("day 7 must be a day group") }
        if case .monthGroup = built[1].kind {} else { XCTFail("day 8 must be a month group") }
    }

    func testUpcomingFutureDeadlineWithoutStart() {
        let tasks = [
            makeTask(id: 1, due: date(2026, 11, 19, in: utc)),
            makeTask(id: 2, start: date(2026, 11, 18, in: utc), due: date(2026, 11, 25, in: utc)),
        ]
        let built = sections(.upcoming, tasks)
        XCTAssertEqual(built.map { sectionIDs($0) }, [[2], [1]])
    }

    func testUpcomingExcludesSomedayTodayDoneAndUndated() {
        let tasks = [
            makeTask(id: 1, start: date(2026, 11, 18, in: utc), labels: ["things:someday"]),
            makeTask(id: 2, start: date(2026, 11, 16, in: utc)),
            makeTask(id: 3, done: true, start: date(2026, 11, 18, in: utc)),
            makeTask(id: 4),
            makeTask(id: 5, due: date(2026, 11, 18, in: utc), labels: ["things:someday"]),
        ]
        XCTAssertTrue(sections(.upcoming, tasks).isEmpty)
    }

    func testUpcomingSortsWithinDayByPosition() {
        let day = date(2026, 11, 18, in: utc)
        let tasks = [
            makeTask(id: 1, start: day, position: 5),
            makeTask(id: 2, start: day, position: 1),
        ]
        XCTAssertEqual(ids(sections(.upcoming, tasks)), [2, 1])
    }

    // MARK: - Anytime

    func testAnytimeRows() {
        let tasks = [
            makeTask(id: 1),
            makeTask(id: 2, start: date(2026, 11, 10, in: utc)),
            makeTask(id: 3, start: date(2026, 11, 16, in: utc)),
            makeTask(id: 4, due: date(2026, 12, 25, in: utc)),
            makeTask(id: 5, start: date(2026, 11, 17, in: utc)),
            makeTask(id: 6, labels: ["things:someday"]),
            makeTask(id: 7, project: inboxID),
            makeTask(id: 8, project: inboxID, start: date(2026, 11, 10, in: utc)),
            makeTask(id: 9, done: true),
            makeTask(id: 10, due: date(2026, 11, 1, in: utc)),
        ]
        let built = sections(.anytime, tasks)
        XCTAssertEqual(built.count, 1)
        XCTAssertEqual(ids(built), [1, 2, 3, 4, 8, 10])
    }

    func testAnytimeWithoutInboxProjectExcludesNothingByProject() {
        let tasks = [makeTask(id: 1, project: inboxID)]
        XCTAssertEqual(ids(sections(.anytime, tasks, inbox: nil)), [1])
    }

    // MARK: - Someday

    func testSomedayHoldsLabelledOpenTasksIgnoringDates() {
        let tasks = [
            makeTask(id: 1, labels: ["things:someday"]),
            makeTask(id: 2, start: date(2026, 11, 18, in: utc), labels: ["Things:Someday"]),
            makeTask(id: 3, labels: ["things:someday"], position: nil).withDone(),
            makeTask(id: 4),
            makeTask(id: 5, project: inboxID, labels: ["things:someday"]),
        ]
        XCTAssertEqual(ids(sections(.someday, tasks)), [1, 2, 5])
    }

    // MARK: - Logbook

    func testLogbookGroupsByDayNewestFirst() {
        let tasks = [
            makeTask(id: 1, done: true, doneAt: date(2026, 11, 15, 9, 0, in: utc)),
            makeTask(id: 2, done: true, doneAt: date(2026, 11, 16, 8, 0, in: utc)),
            makeTask(id: 3, done: true, doneAt: date(2026, 11, 16, 18, 0, in: utc)),
            makeTask(id: 4, done: true, doneAt: date(2026, 11, 1, 12, 0, in: utc), labels: ["things:cancelled"]),
            makeTask(id: 5, start: date(2026, 11, 16, in: utc)),
        ]
        let built = sections(.logbook, tasks)
        XCTAssertEqual(built.map { $0.kind }, [
            .dateGroup(utc.startOfDay(for: date(2026, 11, 16, in: utc))),
            .dateGroup(utc.startOfDay(for: date(2026, 11, 15, in: utc))),
            .dateGroup(utc.startOfDay(for: date(2026, 11, 1, in: utc))),
        ])
        XCTAssertEqual(built.map { sectionIDs($0) }, [[3, 2], [1], [4]])
    }

    func testLogbookGroupsByLocalDayNotUTCDay() {
        // 23:30Z on Nov 15 is already Nov 16 in Paris.
        let tasks = [
            makeTask(id: 1, done: true, doneAt: date(2026, 11, 15, 23, 30, in: utc)),
            makeTask(id: 2, done: true, doneAt: date(2026, 11, 16, 12, 0, in: paris)),
        ]
        XCTAssertEqual(sections(.logbook, tasks, calendar: paris).count, 1)
        XCTAssertEqual(sections(.logbook, tasks, calendar: utc).count, 2)
    }

    func testLogbookFallsBackToUpdatedThenTrailingSection() {
        let tasks = [
            makeTask(id: 1, done: true, doneAt: Date.distantPast, updated: date(2026, 11, 14, 10, 0, in: utc)),
            makeTask(id: 2, done: true, doneAt: date(2026, 11, 15, 10, 0, in: utc)),
            makeTask(id: 3, done: true),
        ]
        let built = sections(.logbook, tasks)
        XCTAssertEqual(built.map { sectionIDs($0) }, [[2], [1], [3]])
        XCTAssertEqual(built.last?.kind, ThingsListSection.Kind.normal)
    }

    // MARK: - Done tasks excluded elsewhere

    func testDoneTasksAppearOnlyInLogbook() {
        let day = date(2026, 11, 16, in: utc)
        let tasks = [
            makeTask(id: 1, project: inboxID, done: true),
            makeTask(id: 2, done: true, start: day),
            makeTask(id: 3, done: true, due: day),
            makeTask(id: 4, done: true, start: date(2026, 11, 20, in: utc)),
            makeTask(id: 5, done: true),
            makeTask(id: 6, done: true, labels: ["things:someday"]),
        ]
        for list in ThingsList.allCases where list != .logbook {
            XCTAssertTrue(sections(list, tasks).isEmpty, "\(list) must not show done tasks")
        }
        XCTAssertEqual(Set(ids(sections(.logbook, tasks))), [1, 2, 3, 4, 5, 6])
    }

    // MARK: - Counts and misc

    func testCounts() {
        let day = date(2026, 11, 16, in: utc)
        let tasks = [
            makeTask(id: 1, project: inboxID),
            makeTask(id: 2, start: day),
            makeTask(id: 3, due: date(2026, 11, 10, in: utc)),
            makeTask(id: 4, start: date(2026, 11, 18, in: utc)),
            makeTask(id: 5, labels: ["things:someday"]),
            makeTask(id: 6, done: true, doneAt: day),
        ]
        let counts = ThingsListBuilder.counts(tasks: tasks, inboxProjectID: inboxID, now: now(in: utc), calendar: utc)
        XCTAssertEqual(counts[.inbox], 1)
        XCTAssertEqual(counts[.today], 2)
        XCTAssertEqual(counts[.upcoming], 1)
        XCTAssertEqual(counts[.anytime], 2)
        XCTAssertEqual(counts[.someday], 1)
        XCTAssertEqual(counts[.logbook], 1)
        XCTAssertEqual(
            ThingsListBuilder.count(for: .today, tasks: tasks, inboxProjectID: inboxID, now: now(in: utc), calendar: utc),
            2
        )
    }

    func testEmptyInputGivesNoSections() {
        for list in ThingsList.allCases {
            XCTAssertTrue(sections(list, []).isEmpty)
        }
    }

    func testListsAreIdentifiableAndComplete() {
        XCTAssertEqual(ThingsList.allCases.count, 6)
        XCTAssertEqual(Set(ThingsList.allCases.map { $0.id }).count, 6)
    }
}

private extension VTask {
    func withDone() -> VTask {
        var copy = self
        copy.done = true
        return copy
    }
}
