import XCTest
@testable import mDone

/// Realistic data through the Things lists: nothing the user owns may fall out
/// of every list. Each fixture mirrors a shape of a real Vikunja account:
/// tasks with a future start date and a deadline, tasks in nested projects,
/// more tasks than one server page (50), finished tasks and subtasks.
final class ThingsListsCompletenessTests: XCTestCase {
    private let inboxID: Int64 = 1
    private let areaID: Int64 = 10
    private let childID: Int64 = 11
    private let grandchildID: Int64 = 12

    private let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    /// Monday 2026-11-16 at 10:00 UTC.
    private var now: Date { date(2026, 11, 16, 10) }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour)
        return utc.date(from: components)!
    }

    private func makeTask(
        _ id: Int64,
        project: Int64,
        done: Bool = false,
        start: Date? = nil,
        due: Date? = nil,
        doneAt: Date? = nil,
        labels: [String] = [],
        parent: VTask? = nil
    ) -> VTask {
        var task = VTask(id: id, title: "Task \(id)", done: done, priority: 0, projectId: project)
        task.startDate = start
        task.dueDate = due
        task.doneAt = doneAt
        task.position = Double(id)
        if !labels.isEmpty {
            task.labels = labels.enumerated().map { VLabel(id: Int64($0.offset + 500), title: $0.element) }
        }
        if let parent {
            task.relatedTasks = ["parenttask": [parent]]
        }
        return task
    }

    private func key(revision: UInt64 = 1, day: Date? = nil) -> ThingsListsCache.Key {
        ThingsListsCache.Key(
            tasksRevision: revision,
            inboxProjectID: inboxID,
            day: utc.startOfDay(for: day ?? now),
            calendarID: "test"
        )
    }

    private func entry(_ tasks: [VTask]) -> ThingsListsCache.Entry {
        ThingsListsCache.build(tasks: tasks, key: key(), now: now, calendar: utc)
    }

    private func ids(_ entry: ThingsListsCache.Entry, _ list: ThingsList) -> [Int64] {
        (entry.snapshot.sections[list] ?? []).flatMap { $0.tasks.map { $0.id } }
    }

    // MARK: - Dates

    func testFutureStartWithDeadlineIsInUpcomingOnlyAtItsStart() {
        let task = makeTask(1, project: 5, start: date(2026, 11, 25), due: date(2026, 12, 1))
        let built = entry([task])
        XCTAssertEqual(ids(built, .upcoming), [1])
        XCTAssertEqual(ids(built, .today), [])
        XCTAssertEqual(ids(built, .anytime), [], "A future start hides the task from Anytime, as in Things")
        XCTAssertEqual(built.snapshot.counts[.upcoming], 1)
    }

    func testPastStartWithFutureDeadlineIsInTodayAndAnytime() {
        let task = makeTask(1, project: 5, start: date(2026, 11, 10), due: date(2026, 12, 1))
        let built = entry([task])
        XCTAssertEqual(ids(built, .today), [1])
        XCTAssertEqual(ids(built, .anytime), [1])
        XCTAssertEqual(ids(built, .upcoming), [])
    }

    func testDeadlineOnlyInFutureIsInAnytimeAndUpcoming() {
        let task = makeTask(1, project: 5, due: date(2026, 11, 20))
        let built = entry([task])
        XCTAssertEqual(ids(built, .anytime), [1])
        XCTAssertEqual(ids(built, .upcoming), [1])
    }

    func testEveryOpenTaskIsInAtLeastOneList() {
        var tasks: [VTask] = []
        var id: Int64 = 1
        let projects: [Int64] = [inboxID, 5, areaID, childID, grandchildID]
        let starts: [Date?] = [nil, date(2026, 11, 1), date(2026, 11, 16), date(2026, 11, 30)]
        let dues: [Date?] = [nil, date(2026, 11, 2), date(2026, 11, 16), date(2027, 1, 5)]
        let labelSets: [[String]] = [[], ["things:someday"], ["things:evening"], ["home"]]
        for project in projects {
            for start in starts {
                for due in dues {
                    for labels in labelSets {
                        tasks.append(makeTask(id, project: project, start: start, due: due, labels: labels))
                        id += 1
                    }
                }
            }
        }
        let built = entry(tasks)
        var seen = Set<Int64>()
        for list in ThingsList.allCases where list != .logbook {
            seen.formUnion(ids(built, list))
        }
        let missing = tasks.map { $0.id }.filter { !seen.contains($0) }
        XCTAssertEqual(missing, [], "Open tasks missing from every list: \(missing.prefix(10))")
    }

    // MARK: - Projects

    func testTasksInNestedProjectsAreAllInAnytime() {
        let tasks = [
            makeTask(1, project: areaID),
            makeTask(2, project: childID),
            makeTask(3, project: grandchildID),
            makeTask(4, project: inboxID),
        ]
        let built = entry(tasks)
        XCTAssertEqual(Set(ids(built, .anytime)), [1, 2, 3])
        XCTAssertEqual(ids(built, .inbox), [4])
    }

    func testProgressCountsNestedProjectsSeparately() {
        let tasks = [
            makeTask(1, project: childID, done: true),
            makeTask(2, project: childID),
            makeTask(3, project: grandchildID, done: true),
        ]
        let built = entry(tasks)
        XCTAssertEqual(built.progressByProject[childID] ?? -1, 0.5, accuracy: 0.0001)
        XCTAssertEqual(built.progressByProject[grandchildID] ?? -1, 1, accuracy: 0.0001)
        XCTAssertNil(built.progressByProject[areaID])
    }

    // MARK: - Volume

    func testMoreThanOnePageOfTasksAllAppear() {
        let tasks = (1 ... 130).map { makeTask(Int64($0), project: 5) }
        let built = entry(tasks)
        XCTAssertEqual(ids(built, .anytime).count, 130)
        XCTAssertEqual(built.snapshot.counts[.anytime], 130)
    }

    func testDoneTasksOnlyAppearInTheLogbook() {
        let open = (1 ... 5).map { makeTask(Int64($0), project: 5) }
        let finished = (101 ... 160).map {
            makeTask(Int64($0), project: 5, done: true, doneAt: date(2026, 11, 10))
        }
        let built = entry(open + finished)
        XCTAssertEqual(built.snapshot.counts[.logbook], 60)
        XCTAssertEqual(built.snapshot.counts[.anytime], 5)
        XCTAssertEqual(built.snapshot.counts[.today], 0)
    }

    // MARK: - Subtasks

    func testPlainChecklistStepsAreHiddenButRealSubtasksStayVisible() {
        let parent = makeTask(1, project: 5)
        let plainStep = makeTask(2, project: 5, parent: parent)
        let datedStep = makeTask(3, project: 5, due: date(2026, 11, 20), parent: parent)
        let taggedStep = makeTask(4, project: 5, labels: ["errand"], parent: parent)
        let otherProjectStep = makeTask(5, project: 6, parent: parent)
        let doneParent = makeTask(6, project: 5, done: true)
        let orphanOfDoneParent = makeTask(7, project: 5, parent: doneParent)
        let doneStepOfDoneParent = makeTask(8, project: 5, done: true, parent: doneParent)

        let tasks = [parent, plainStep, datedStep, taggedStep, otherProjectStep,
                     doneParent, orphanOfDoneParent, doneStepOfDoneParent]
        let built = entry(tasks)
        let listed = Set(built.listable.map { $0.id })
        XCTAssertFalse(listed.contains(2), "A plain step stays a checklist item")
        XCTAssertFalse(listed.contains(8), "A finished step of a finished parent stays hidden")
        XCTAssertTrue(listed.contains(3), "A subtask with a deadline is a real to-do")
        XCTAssertTrue(listed.contains(4), "A subtask with a tag is a real to-do")
        XCTAssertTrue(listed.contains(5), "A subtask in another project is a real to-do")
        XCTAssertTrue(listed.contains(7), "An open subtask of a finished parent must not vanish")
        XCTAssertTrue(listed.contains(1))
    }

    // MARK: - Inbox

    func testInboxKeepsDeadlineOnlyTasksAndDropsScheduledOnes() {
        let tasks = [
            makeTask(1, project: inboxID),
            makeTask(2, project: inboxID, due: date(2026, 12, 24)),
            makeTask(3, project: inboxID, start: date(2026, 11, 20)),
            makeTask(4, project: inboxID, labels: ["things:someday"]),
        ]
        let built = entry(tasks)
        XCTAssertEqual(ids(built, .inbox), [1, 2])
        XCTAssertEqual(ids(built, .someday), [4])
        XCTAssertEqual(ids(built, .upcoming).sorted(), [2, 3])
    }

    // MARK: - Memo

    func testCacheReusesTheEntryUntilAnInputChanges() {
        let cache = ThingsListsCache()
        let tasks = [makeTask(1, project: 5)]
        let first = cache.entry(tasks: tasks, tasksRevision: 1, inboxProjectID: inboxID, now: now, calendar: utc)
        let again = cache.entry(tasks: tasks, tasksRevision: 1, inboxProjectID: inboxID, now: now, calendar: utc)
        XCTAssertEqual(cache.buildCount, 1)
        XCTAssertEqual(first.generation, again.generation)

        _ = cache.entry(tasks: tasks, tasksRevision: 2, inboxProjectID: inboxID, now: now, calendar: utc)
        XCTAssertEqual(cache.buildCount, 2, "A new task revision rebuilds")

        _ = cache.entry(tasks: tasks, tasksRevision: 2, inboxProjectID: 9, now: now, calendar: utc)
        XCTAssertEqual(cache.buildCount, 3, "A new Inbox project rebuilds")

        let tomorrow = utc.date(byAdding: .day, value: 1, to: now) ?? now
        _ = cache.entry(tasks: tasks, tasksRevision: 2, inboxProjectID: 9, now: tomorrow, calendar: utc)
        XCTAssertEqual(cache.buildCount, 4, "A new day rebuilds")

        let laterToday = utc.date(byAdding: .hour, value: 1, to: tomorrow) ?? tomorrow
        _ = cache.entry(tasks: tasks, tasksRevision: 2, inboxProjectID: 9, now: laterToday, calendar: utc)
        XCTAssertEqual(cache.buildCount, 4, "The same day reuses")
    }

    func testCountsAgreeWithTheSectionsOfEachList() {
        let tasks = [
            makeTask(1, project: inboxID),
            makeTask(2, project: 5, start: date(2026, 11, 16)),
            makeTask(3, project: 5, start: date(2026, 12, 2), due: date(2026, 12, 9)),
            makeTask(4, project: 5, done: true, doneAt: date(2026, 11, 14)),
            makeTask(5, project: 5, labels: ["things:someday"]),
        ]
        for list in ThingsList.allCases {
            let direct = ThingsListBuilder.count(
                for: list, tasks: tasks, inboxProjectID: inboxID, now: now, calendar: utc
            )
            let viaSnapshot = entry(tasks).snapshot.counts[list]
            XCTAssertEqual(direct, viaSnapshot, "\(list)")
        }
    }
}
