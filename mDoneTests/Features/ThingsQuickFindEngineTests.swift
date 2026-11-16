import XCTest
@testable import mDone

final class ThingsQuickFindEngineTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    /// Monday 2026-11-16 at 10:00 UTC.
    private var now: Date {
        utc.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 10)) ?? Date()
    }

    private func task(_ id: Int64, _ title: String, project: Int64 = 1, done: Bool = false) -> VTask {
        VTask(id: id, title: title, done: done, priority: 0, projectId: project)
    }

    private var projects: [Project] {
        [
            Project(id: 1, title: "Inbox"),
            Project(id: 2, title: "Website"),
            Project(id: 3, title: "Finances", description: ThingsProjectMeta.areaMarker)
        ]
    }

    func testEmptyQueryFindsNothing() {
        let found = ThingsQuickFindEngine.results(query: "  ", tasks: [task(1, "Buy bread")], projects: projects, labels: [])
        XCTAssertTrue(found.isEmpty)
    }

    func testListsAreFoundByPrefix() {
        let found = ThingsQuickFindEngine.results(query: "tod", tasks: [], projects: [], labels: [])
        XCTAssertEqual(found.first?.target, .list(.today))
    }

    func testAreaAndProjectResultsKeepTheirKind() {
        let found = ThingsQuickFindEngine.results(query: "fin", tasks: [], projects: projects, labels: [])
        XCTAssertEqual(found.first?.target, .area(3))
        let site = ThingsQuickFindEngine.results(query: "web", tasks: [], projects: projects, labels: [])
        XCTAssertEqual(site.first?.target, .project(2))
    }

    func testPrefixMatchesRankBeforeContainsMatches() {
        let tasks = [task(1, "Write bread recipe"), task(2, "Bread shopping")]
        let found = ThingsQuickFindEngine.results(query: "bread", tasks: tasks, projects: projects, labels: [])
        XCTAssertEqual(found.map { $0.target }, [.todo(2), .todo(1)])
    }

    func testFinishedTodosAndReservedLabelsAreSkipped() {
        let tasks = [task(1, "Bread", done: true)]
        let labels = [VLabel(id: 1, title: ThingsReservedLabels.someday), VLabel(id: 2, title: "Errand")]
        let found = ThingsQuickFindEngine.results(query: "some", tasks: tasks, projects: [], labels: labels)
        XCTAssertFalse(found.contains { $0.target == .tag(ThingsReservedLabels.someday) })
        let bread = ThingsQuickFindEngine.results(query: "bread", tasks: tasks, projects: [], labels: [])
        XCTAssertTrue(bread.isEmpty)
        let tag = ThingsQuickFindEngine.results(query: "err", tasks: [], projects: [], labels: labels)
        XCTAssertEqual(tag.first?.target, .tag("Errand"))
    }

    func testLimitCapsTheResults() {
        let tasks = (1...10).map { task(Int64($0), "Item \($0)") }
        let found = ThingsQuickFindEngine.results(query: "item", tasks: tasks, projects: [], labels: [], limit: 3)
        XCTAssertEqual(found.count, 3)
    }

    func testRouteOfAProjectTodoIsItsProject() {
        let route = ThingsQuickFindEngine.route(for: task(1, "A", project: 2), inboxProjectID: 1, now: now, calendar: utc)
        XCTAssertEqual(route, .project(2))
    }

    func testRouteOfAnInboxTodoFollowsItsWhen() {
        var scheduled = task(1, "A")
        scheduled.startDate = utc.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 12))
        XCTAssertEqual(
            ThingsQuickFindEngine.route(for: scheduled, inboxProjectID: 1, now: now, calendar: utc),
            .list(.upcoming)
        )
        XCTAssertEqual(
            ThingsQuickFindEngine.route(for: task(2, "B"), inboxProjectID: 1, now: now, calendar: utc),
            .list(.inbox)
        )
    }

    func testRouteOfAFinishedTodoIsTheLogbook() {
        let route = ThingsQuickFindEngine.route(for: task(1, "A", project: 2, done: true), inboxProjectID: 1, now: now, calendar: utc)
        XCTAssertEqual(route, .list(.logbook))
    }
}
