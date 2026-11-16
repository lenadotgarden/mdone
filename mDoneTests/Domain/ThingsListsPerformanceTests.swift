import XCTest
@testable import mDone

/// Benchmark style guard for the pure builders: a big account (3000 tasks in
/// 200 projects) must build all lists, the project tree and the per-project
/// progress quickly, and a memoized read must be nearly free. The bounds are
/// generous on purpose (a loaded CI runner is slow); they catch an accidental
/// quadratic loop, not a few percent.
final class ThingsListsPerformanceTests: XCTestCase {
    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    private var now: Date {
        utc.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 10)) ?? Date()
    }

    private func day(_ offset: Int) -> Date {
        let base = utc.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 12)) ?? Date()
        return utc.date(byAdding: .day, value: offset, to: base) ?? base
    }

    private func makeProjects(count: Int) -> [Project] {
        var projects: [Project] = []
        for index in 1 ... count {
            let id = Int64(index)
            // Every 10th project is a root, the rest hang below an earlier one:
            // a tree about five levels deep.
            let parent: Int64? = index % 10 == 1 ? nil : id - 1
            projects.append(Project(id: id, title: "Project \(index)", position: Double(index), parentProjectId: parent))
        }
        return projects
    }

    private func makeTasks(count: Int, projects: Int) -> [VTask] {
        var tasks: [VTask] = []
        tasks.reserveCapacity(count)
        for index in 1 ... count {
            var task = VTask(
                id: Int64(index),
                title: "Task \(index)",
                done: index % 5 == 0,
                priority: 0,
                projectId: Int64(index % projects) + 1
            )
            task.position = Double(index)
            switch index % 7 {
            case 0: task.startDate = day(-3)
            case 1: task.startDate = day(index % 60 + 1)
            case 2: task.dueDate = day(index % 30 - 10)
            case 3: task.labels = [VLabel(id: 1, title: "things:someday")]
            case 4: task.labels = [VLabel(id: 2, title: "things:evening"), VLabel(id: 3, title: "home")]
            default: break
            }
            if task.done { task.doneAt = day(-(index % 90)) }
            if index % 11 == 0, index > 11 {
                var parent = VTask(id: Int64(index - 11), title: "Parent", done: false, priority: 0, projectId: task.projectId)
                parent.position = 1
                task.relatedTasks = ["parenttask": [parent]]
            }
            tasks.append(task)
        }
        return tasks
    }

    private func elapsed(_ work: () -> Void) -> TimeInterval {
        let start = Date()
        work()
        return Date().timeIntervalSince(start)
    }

    func testBuildingEverythingForALargeAccountIsFast() {
        let projects = makeProjects(count: 200)
        let tasks = makeTasks(count: 3000, projects: 200)
        let key = ThingsListsCache.Key(
            tasksRevision: 1, inboxProjectID: 1, day: utc.startOfDay(for: now), calendarID: "test"
        )

        var built: ThingsListsCache.Entry?
        let listsTime = elapsed {
            built = ThingsListsCache.build(tasks: tasks, key: key, now: now, calendar: utc)
        }
        XCTAssertLessThan(listsTime, 3.0, "Six lists, counts and progress over 3000 tasks took \(listsTime)s")
        XCTAssertGreaterThan(built?.listable.count ?? 0, 2000)
        XCTAssertFalse(built?.progressByProject.isEmpty ?? true)

        let treeTime = elapsed {
            _ = ThingsProjectTree.buildUncached(projects: projects, inboxProjectID: 1)
        }
        XCTAssertLessThan(treeTime, 2.0, "The project tree of 200 projects took \(treeTime)s")
    }

    func testRepeatedReadsOfTheCacheDoNotRebuild() {
        let tasks = makeTasks(count: 3000, projects: 200)
        let cache = ThingsListsCache()
        _ = cache.entry(tasks: tasks, tasksRevision: 7, inboxProjectID: 1, now: now, calendar: utc)
        let readTime = elapsed {
            for _ in 0 ..< 1000 {
                _ = cache.entry(tasks: tasks, tasksRevision: 7, inboxProjectID: 1, now: now, calendar: utc)
            }
        }
        XCTAssertEqual(cache.buildCount, 1)
        XCTAssertLessThan(readTime, 1.0, "1000 memoized reads took \(readTime)s")
    }

    func testProjectTreeMemoServesTheSameProjects() {
        let projects = makeProjects(count: 200)
        let memo = ThingsProjectTreeMemo.shared
        _ = ThingsProjectTree.build(projects: projects, inboxProjectID: 1)
        let misses = memo.missCount
        let readTime = elapsed {
            for _ in 0 ..< 200 {
                _ = ThingsProjectTree.build(projects: projects, inboxProjectID: 1)
            }
        }
        XCTAssertEqual(memo.missCount, misses, "Same projects must be served from the memo")
        XCTAssertLessThan(readTime, 2.0, "200 memoized tree reads took \(readTime)s")

        var renamed = projects
        renamed[5].title = "Renamed"
        let tree = ThingsProjectTree.build(projects: renamed, inboxProjectID: 1)
        XCTAssertEqual(memo.missCount, misses + 1, "An edit must rebuild")
        XCTAssertTrue(tree.allNodes.contains { $0.title == "Renamed" })
    }
}
