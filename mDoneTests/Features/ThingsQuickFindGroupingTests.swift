import XCTest
@testable import mDone

/// Quick Find grouping, accent folding, tag filter and Type Travel start keys.
final class ThingsQuickFindGroupingTests: XCTestCase {
    private func task(_ id: Int64, _ title: String, project: Int64 = 1, done: Bool = false) -> VTask {
        VTask(id: id, title: title, done: done, priority: 0, projectId: project)
    }

    private func tagged(_ id: Int64, _ title: String, tags: [String], done: Bool = false) -> VTask {
        var result = task(id, title, done: done)
        result.labels = tags.enumerated().map { VLabel(id: Int64($0.offset + 100), title: $0.element) }
        return result
    }

    private var projects: [Project] {
        [
            Project(id: 1, title: "Inbox"),
            Project(id: 2, title: "Finish line"),
            Project(id: 3, title: "Finances", description: ThingsProjectMeta.areaMarker),
        ]
    }

    private let labels = [VLabel(id: 5, title: "Finance"), VLabel(id: 6, title: "Errand")]

    func testResultsAreGroupedTodosThenProjectsAndAreasThenTags() {
        let found = ThingsQuickFindEngine.results(
            query: "fin",
            tasks: [task(1, "Finish report")],
            projects: projects,
            labels: labels
        )
        let groups = found.map { $0.group }
        XCTAssertEqual(groups, [.todos, .projects, .projects, .tags])
        XCTAssertEqual(found.last?.target, .tag("Finance"))
        let blocks = ThingsQuickFindEngine.grouped(found)
        XCTAssertEqual(blocks.map { $0.group }, [.todos, .projects, .tags])
        XCTAssertEqual(blocks[1].results.count, 2)
    }

    func testListsComeFirstAndHaveNoHeader() {
        let found = ThingsQuickFindEngine.results(
            query: "tod", tasks: [task(1, "Todo list")], projects: [], labels: []
        )
        XCTAssertEqual(found.first?.target, .list(.today))
        XCTAssertEqual(ThingsQuickFindEngine.grouped(found).first?.group, .lists)
        XCTAssertNil(ThingsQuickFindGroup.lists.title)
    }

    func testAccentsAndCaseAreIgnored() {
        let tasks = [task(1, "Réunion équipe")]
        let found = ThingsQuickFindEngine.results(query: "REUNION", tasks: tasks, projects: [], labels: [])
        XCTAssertEqual(found.map { $0.target }, [.todo(1)])
        let accented = ThingsQuickFindEngine.results(query: "équipe", tasks: tasks, projects: [], labels: [])
        XCTAssertEqual(accented.map { $0.target }, [.todo(1)])
    }

    func testRankIsPrefixThenWordPrefixThenContains() {
        let tasks = [task(1, "Wholebread"), task(2, "A bread loaf"), task(3, "Bread first")]
        let found = ThingsQuickFindEngine.results(query: "bread", tasks: tasks, projects: [], labels: [])
        XCTAssertEqual(found.map { $0.target }, [.todo(3), .todo(2), .todo(1)])
    }

    func testEveryWordOfTheQueryMustMatch() {
        let tasks = [task(1, "Buy bread at the market"), task(2, "Buy milk")]
        let found = ThingsQuickFindEngine.results(query: "market bread", tasks: tasks, projects: [], labels: [])
        XCTAssertEqual(found.map { $0.target }, [.todo(1)])
    }

    func testATodoIsFoundThroughItsTag() {
        let tasks = [tagged(1, "Zzz", tags: ["Errand"]), task(2, "Other")]
        let found = ThingsQuickFindEngine.results(query: "err", tasks: tasks, projects: [], labels: labels)
        XCTAssertTrue(found.contains { $0.target == .todo(1) })
        XCTAssertFalse(found.contains { $0.target == .todo(2) })
    }

    func testTagsDoNotGetPushedOutByManyTodos() {
        let tasks = (1 ... 60).map { task(Int64($0), "Item \($0)") }
        let found = ThingsQuickFindEngine.results(
            query: "item", tasks: tasks, projects: [], labels: [VLabel(id: 9, title: "Item")], limit: 40
        )
        XCTAssertEqual(found.count, 40)
        XCTAssertTrue(found.contains { $0.target == .tag("Item") })
    }

    func testTodosTaggedWithAnExactTag() {
        let tasks = [
            tagged(1, "A", tags: ["Errand"]),
            tagged(2, "B", tags: ["Errand", "Home"], done: true),
            tagged(3, "C", tags: ["Errands"]),
            task(4, "D"),
            tagged(5, "E", tags: ["errand"]),
        ]
        let found = ThingsQuickFindEngine.todos(taggedWith: "ERRAND", tasks: tasks, projects: projects)
        XCTAssertEqual(found.map { $0.target }, [.todo(1), .todo(5)])
        XCTAssertEqual(found.first?.subtitle, "Inbox")
    }

    func testReservedTagsAreNeverATagFilter() {
        let tasks = [tagged(1, "A", tags: [ThingsReservedLabels.someday])]
        let found = ThingsQuickFindEngine.todos(taggedWith: ThingsReservedLabels.someday, tasks: tasks, projects: projects)
        XCTAssertTrue(found.isEmpty)
    }

    func testTypeTravelStartKeys() {
        XCTAssertTrue(ThingsQuickFindEngine.isSearchStart("a"))
        XCTAssertTrue(ThingsQuickFindEngine.isSearchStart("A"))
        XCTAssertTrue(ThingsQuickFindEngine.isSearchStart("é"))
        XCTAssertTrue(ThingsQuickFindEngine.isSearchStart("7"))
        XCTAssertTrue(ThingsQuickFindEngine.isSearchStart("/"))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart(""))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart(" "))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart("\r"))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart("\t"))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart("\u{1B}"))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart("\u{7F}"))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart("\u{F700}"))
        XCTAssertFalse(ThingsQuickFindEngine.isSearchStart("\u{F704}"))
    }
}
