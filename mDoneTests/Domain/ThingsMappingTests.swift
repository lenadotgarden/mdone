import XCTest
@testable import mDone

final class ThingsMappingTests: XCTestCase {
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

    private func date(
        _ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0,
        in calendar: Calendar
    ) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components)!
    }

    /// Monday 2026-11-16 at 10:00.
    private func now(in calendar: Calendar) -> Date {
        date(2026, 11, 16, 10, 0, in: calendar)
    }

    private func makeTask(
        id: Int64,
        done: Bool = false,
        start: Date? = nil,
        due: Date? = nil,
        labels: [String] = [],
        bucketId: Int64? = nil,
        position: Double? = nil,
        subtasks: [VTask] = []
    ) -> VTask {
        var task = VTask(id: id, title: "Task \(id)", done: done, priority: 0, projectId: 5)
        task.startDate = start
        task.dueDate = due
        task.bucketId = bucketId
        task.position = position
        if !labels.isEmpty {
            task.labels = labels.enumerated().map { VLabel(id: Int64($0.offset + 100), title: $0.element) }
        }
        if !subtasks.isEmpty {
            task.relatedTasks = ["subtask": subtasks]
        }
        return task
    }

    private func makeProject(
        id: Int64,
        title: String = "P",
        description: String? = nil,
        parent: Int64? = nil,
        position: Double? = nil,
        views: [ProjectView]? = nil
    ) -> Project {
        var project = Project(id: id, title: title)
        project.description = description
        project.parentProjectId = parent
        project.position = position
        project.views = views
        return project
    }

    private func makeBucket(id: Int64, title: String, position: Double?, tasks: [VTask]? = nil) -> Bucket {
        var bucket = Bucket(id: id, title: title)
        bucket.position = position
        bucket.tasks = tasks
        return bucket
    }

    // MARK: - ThingsWhen.resolve

    func testResolveNoStartIsNone() {
        let result = ThingsWhen.resolve(startDate: nil, labels: [], now: now(in: utc), calendar: utc)
        XCTAssertEqual(result, ThingsWhen.none)
    }

    func testResolveZeroDateIsNone() {
        let zero = Date.distantPast
        let result = ThingsWhen.resolve(startDate: zero, labels: [], now: now(in: utc), calendar: utc)
        XCTAssertEqual(result, ThingsWhen.none)
        let yearOne = date(1, 1, 1, 0, 0, in: utc)
        let again = ThingsWhen.resolve(startDate: yearOne, labels: [], now: now(in: utc), calendar: utc)
        XCTAssertEqual(again, ThingsWhen.none)
    }

    func testResolveTodayAndPastStayToday() {
        let today = ThingsWhen.resolve(
            startDate: date(2026, 11, 16, in: utc), labels: [], now: now(in: utc), calendar: utc
        )
        XCTAssertEqual(today, ThingsWhen.today)
        let past = ThingsWhen.resolve(
            startDate: date(2026, 11, 10, in: utc), labels: [], now: now(in: utc), calendar: utc
        )
        XCTAssertEqual(past, ThingsWhen.today)
    }

    func testResolveEvening() {
        let result = ThingsWhen.resolve(
            startDate: date(2026, 11, 16, in: utc),
            labels: [" Things:Evening "],
            now: now(in: utc),
            calendar: utc
        )
        XCTAssertEqual(result, ThingsWhen.thisEvening)
    }

    func testResolveEveningWithoutStartIsNone() {
        let result = ThingsWhen.resolve(
            startDate: nil, labels: [ThingsReservedLabels.evening], now: now(in: utc), calendar: utc
        )
        XCTAssertEqual(result, ThingsWhen.none)
    }

    func testResolveSomedayWinsOverStartDate() {
        let result = ThingsWhen.resolve(
            startDate: date(2026, 11, 16, in: utc),
            labels: [ThingsReservedLabels.someday, ThingsReservedLabels.evening],
            now: now(in: utc),
            calendar: utc
        )
        XCTAssertEqual(result, ThingsWhen.someday)
    }

    func testResolveFutureDateIsStartOfDay() {
        let result = ThingsWhen.resolve(
            startDate: date(2026, 11, 20, in: paris), labels: [], now: now(in: paris), calendar: paris
        )
        XCTAssertEqual(result, ThingsWhen.date(date(2026, 11, 20, 0, 0, in: paris)))
    }

    func testResolveFromTask() {
        let task = makeTask(id: 1, start: date(2026, 11, 16, in: utc), labels: ["work"])
        XCTAssertEqual(ThingsWhen.resolve(task: task, now: now(in: utc), calendar: utc), ThingsWhen.today)
    }

    // MARK: - Noon and zero date

    func testNoonLocalKeepsDayAndSetsNoon() {
        let late = date(2026, 11, 16, 23, 59, in: paris)
        let noon = noonLocal(late, calendar: paris)
        XCTAssertEqual(noon, date(2026, 11, 16, 12, 0, in: paris))
        let early = date(2026, 11, 16, 0, 0, in: paris)
        XCTAssertEqual(ThingsWhen.noonLocal(early, calendar: paris), date(2026, 11, 16, 12, 0, in: paris))
    }

    func testZeroDateHandling() {
        XCTAssertTrue(ThingsWhen.isZeroDate(nil, calendar: utc))
        XCTAssertTrue(ThingsWhen.isZeroDate(Date.distantPast, calendar: utc))
        XCTAssertFalse(ThingsWhen.isZeroDate(date(2026, 1, 1, in: utc), calendar: utc))
        XCTAssertNil(ThingsWhen.validDate(Date.distantPast, calendar: utc))
    }

    // MARK: - ThingsWhen patch

    func testPatchToday() {
        let patch = ThingsWhen.patch(for: .today, now: now(in: utc), calendar: utc)
        XCTAssertEqual(patch.startDate, ThingsDateChange.set(date(2026, 11, 16, 12, 0, in: utc)))
        XCTAssertEqual(patch.addLabels, [])
        XCTAssertEqual(patch.removeLabels, [ThingsReservedLabels.evening, ThingsReservedLabels.someday])
    }

    func testPatchEvening() {
        let patch = ThingsWhen.thisEvening.patch(now: now(in: utc), calendar: utc)
        XCTAssertEqual(patch.startDate, ThingsDateChange.set(date(2026, 11, 16, 12, 0, in: utc)))
        XCTAssertEqual(patch.addLabels, [ThingsReservedLabels.evening])
        XCTAssertEqual(patch.removeLabels, [ThingsReservedLabels.someday])
    }

    func testPatchSomedayClearsStart() {
        let patch = ThingsWhen.patch(for: .someday, now: now(in: utc), calendar: utc)
        XCTAssertEqual(patch.startDate, ThingsDateChange.clear)
        XCTAssertEqual(patch.addLabels, [ThingsReservedLabels.someday])
        XCTAssertEqual(patch.removeLabels, [ThingsReservedLabels.evening])
    }

    func testPatchDateNormalizesToNoon() {
        let day = date(2026, 12, 24, 0, 0, in: paris)
        let patch = ThingsWhen.patch(for: .date(day), now: now(in: paris), calendar: paris)
        XCTAssertEqual(patch.startDate, ThingsDateChange.set(date(2026, 12, 24, 12, 0, in: paris)))
        XCTAssertEqual(patch.addLabels, [])
    }

    func testPatchNoneClearsEverything() {
        let patch = ThingsWhen.patch(for: ThingsWhen.none, now: now(in: utc), calendar: utc)
        XCTAssertEqual(patch.startDate, ThingsDateChange.clear)
        XCTAssertEqual(patch.addLabels, [])
        XCTAssertEqual(patch.removeLabels.count, 2)
    }

    func testPatchRoundTripsThroughResolve() {
        let current = now(in: paris)
        let cases: [ThingsWhen] = [
            .today, .thisEvening, .someday, .date(date(2026, 12, 24, 0, 0, in: paris)), ThingsWhen.none
        ]
        for when in cases {
            let patch = ThingsWhen.patch(for: when, now: current, calendar: paris)
            var start: Date? = nil
            if case .set(let value) = patch.startDate { start = value }
            let labels = patch.addLabels
            let result = ThingsWhen.resolve(startDate: start, labels: labels, now: current, calendar: paris)
            XCTAssertEqual(result, when)
        }
    }

    func testMinimizedDropsNoOps() {
        let task = makeTask(id: 1, start: date(2026, 11, 16, in: utc), labels: [ThingsReservedLabels.evening, "work"])
        let patch = ThingsWhen.patch(for: .thisEvening, now: now(in: utc), calendar: utc)
        let small = patch.minimized(against: task, calendar: utc)
        XCTAssertTrue(small.isEmpty)
    }

    func testMinimizedKeepsRealChanges() {
        let task = makeTask(id: 1, start: date(2026, 11, 16, in: utc), labels: [ThingsReservedLabels.evening])
        let patch = ThingsWhen.patch(for: .someday, now: now(in: utc), calendar: utc)
        let small = patch.minimized(against: task, calendar: utc)
        XCTAssertEqual(small.startDate, ThingsDateChange.clear)
        XCTAssertEqual(small.addLabels, [ThingsReservedLabels.someday])
        XCTAssertEqual(small.removeLabels, [ThingsReservedLabels.evening])
        let bare = makeTask(id: 2)
        let clearing = ThingsWhen.patch(for: ThingsWhen.none, now: now(in: utc), calendar: utc)
        XCTAssertTrue(clearing.minimized(against: bare, calendar: utc).isEmpty)
    }

    // MARK: - ThingsDeadline

    func testDeadlineToday() {
        let due = date(2026, 11, 16, in: utc)
        XCTAssertEqual(ThingsDeadline.daysLeft(dueDate: due, now: now(in: utc), calendar: utc), 0)
        XCTAssertEqual(ThingsDeadline.text(dueDate: due, now: now(in: utc), calendar: utc), ThingsDeadlineText.today)
        XCTAssertFalse(ThingsDeadline.isOverdue(dueDate: due, now: now(in: utc), calendar: utc))
    }

    func testDeadlineDaysLeft() {
        let due = date(2026, 11, 19, in: paris)
        XCTAssertEqual(ThingsDeadline.daysLeft(dueDate: due, now: now(in: paris), calendar: paris), 3)
        XCTAssertEqual(
            ThingsDeadline.text(dueDate: due, now: now(in: paris), calendar: paris),
            ThingsDeadlineText.daysLeft(3)
        )
    }

    func testDeadlineDaysAgoAndOverdue() {
        let due = date(2026, 11, 14, in: utc)
        XCTAssertEqual(ThingsDeadline.daysLeft(dueDate: due, now: now(in: utc), calendar: utc), -2)
        XCTAssertEqual(
            ThingsDeadline.text(dueDate: due, now: now(in: utc), calendar: utc),
            ThingsDeadlineText.daysAgo(2)
        )
        XCTAssertTrue(ThingsDeadline.isOverdue(dueDate: due, now: now(in: utc), calendar: utc))
        XCTAssertFalse(ThingsDeadline.isOverdue(dueDate: due, done: true, now: now(in: utc), calendar: utc))
        let task = makeTask(id: 1, due: due)
        XCTAssertTrue(ThingsDeadline.isOverdue(task: task, now: now(in: utc), calendar: utc))
    }

    func testDeadlineAcrossDaylightSavingChange() {
        let current = date(2026, 3, 28, 10, 0, in: paris)
        let due = date(2026, 3, 30, 12, 0, in: paris)
        XCTAssertEqual(ThingsDeadline.daysLeft(dueDate: due, now: current, calendar: paris), 2)
    }

    func testDeadlineUnsetAndZero() {
        XCTAssertNil(ThingsDeadline.daysLeft(dueDate: nil, now: now(in: utc), calendar: utc))
        XCTAssertNil(ThingsDeadline.text(dueDate: Date.distantPast, now: now(in: utc), calendar: utc))
        XCTAssertFalse(ThingsDeadline.isOverdue(dueDate: Date.distantPast, now: now(in: utc), calendar: utc))
    }

    // MARK: - ThingsProjectMeta

    func testAreaMarkerDetection() {
        XCTAssertTrue(ThingsProjectMeta.hasAreaMarker("things:area"))
        XCTAssertTrue(ThingsProjectMeta.hasAreaMarker("  Things:Area  \nNotes"))
        XCTAssertTrue(ThingsProjectMeta.hasAreaMarker("things:area\r\nNotes"))
        XCTAssertFalse(ThingsProjectMeta.hasAreaMarker("Notes\nthings:area"))
        XCTAssertFalse(ThingsProjectMeta.hasAreaMarker("things:areas"))
        XCTAssertFalse(ThingsProjectMeta.hasAreaMarker(nil))
        XCTAssertFalse(ThingsProjectMeta.hasAreaMarker(""))
    }

    func testAddMarkerKeepsUserText() {
        XCTAssertEqual(ThingsProjectMeta.addingAreaMarker(to: "Hello\n\nWorld"), "things:area\nHello\n\nWorld")
        XCTAssertEqual(ThingsProjectMeta.addingAreaMarker(to: nil), "things:area")
        XCTAssertEqual(ThingsProjectMeta.addingAreaMarker(to: ""), "things:area")
        XCTAssertEqual(ThingsProjectMeta.addingAreaMarker(to: "things:area\nHi"), "things:area\nHi")
    }

    func testRemoveMarkerKeepsUserText() {
        XCTAssertEqual(ThingsProjectMeta.removingAreaMarker(from: "things:area\nHello\n\nWorld"), "Hello\n\nWorld")
        XCTAssertEqual(ThingsProjectMeta.removingAreaMarker(from: "things:area"), "")
        XCTAssertEqual(ThingsProjectMeta.removingAreaMarker(from: "  plain  \n"), "  plain  \n")
        XCTAssertEqual(ThingsProjectMeta.removingAreaMarker(from: nil), "")
    }

    func testMarkerRoundTrip() {
        let original = "  Line one\n\nLine three  "
        let added = ThingsProjectMeta.addingAreaMarker(to: original)
        XCTAssertEqual(ThingsProjectMeta.removingAreaMarker(from: added), original)
    }

    func testKindDetection() {
        let area = makeProject(id: 1, description: "things:area\nnotes")
        let plain = makeProject(id: 2, description: "notes")
        let inbox = makeProject(id: 3, description: nil)
        let nestedMarked = makeProject(id: 4, description: "things:area", parent: 1)
        let inboxMarked = makeProject(id: 5, description: "things:area")
        XCTAssertEqual(ThingsProjectMeta.kind(of: area, inboxProjectID: 3), ThingsProjectKind.area)
        XCTAssertEqual(ThingsProjectMeta.kind(of: plain, inboxProjectID: 3), ThingsProjectKind.project)
        XCTAssertEqual(ThingsProjectMeta.kind(of: inbox, inboxProjectID: 3), ThingsProjectKind.inbox)
        XCTAssertEqual(ThingsProjectMeta.kind(of: nestedMarked, inboxProjectID: 3), ThingsProjectKind.project)
        XCTAssertEqual(ThingsProjectMeta.kind(of: inboxMarked, inboxProjectID: 5), ThingsProjectKind.inbox)
        XCTAssertEqual(ThingsProjectMeta.kind(of: inbox, inboxProjectID: nil), ThingsProjectKind.project)
        let rootZero = makeProject(id: 6, description: "things:area", parent: 0)
        XCTAssertEqual(ThingsProjectMeta.kind(of: rootZero, inboxProjectID: nil), ThingsProjectKind.area)
    }

    func testHierarchyHelpers() {
        let areaB = makeProject(id: 1, title: "B", description: "things:area", position: 2)
        let areaA = makeProject(id: 2, title: "A", description: "things:area", position: 1)
        let childY = makeProject(id: 3, title: "Y", parent: 1, position: 2)
        let childX = makeProject(id: 4, title: "X", parent: 1, position: 1)
        let loose = makeProject(id: 5, title: "Loose")
        let inbox = makeProject(id: 6, title: "Inbox")
        let all = [areaB, areaA, childY, childX, loose, inbox]
        XCTAssertEqual(ThingsProjectMeta.areas(in: all).map { $0.id }, [2, 1])
        XCTAssertEqual(ThingsProjectMeta.children(of: 1, in: all).map { $0.id }, [4, 3])
        XCTAssertEqual(ThingsProjectMeta.looseProjects(in: all, inboxProjectID: 6).map { $0.id }, [5])
        XCTAssertEqual(ThingsProjectMeta.userVisibleDescription(of: areaA), "")
    }

    // MARK: - Headings

    func testHeadingsViewDetection() {
        let list = ProjectView(id: 10, title: "List", projectId: 1, viewKind: "list")
        let board = ProjectView(id: 11, title: "Kanban", projectId: 1, viewKind: "kanban")
        let headings = ProjectView(id: 12, title: " Things-Headings ", projectId: 1, viewKind: "kanban")
        let wrongKind = ProjectView(id: 13, title: "things-headings", projectId: 1, viewKind: "list")
        let project = makeProject(id: 1, views: [list, board, wrongKind, headings])
        XCTAssertEqual(ThingsHeadingMapping.headingsViewId(in: project), 12)
        XCTAssertNil(ThingsHeadingMapping.headingsViewId(in: makeProject(id: 2, views: [list, board])))
        XCTAssertNil(ThingsHeadingMapping.headingsViewId(in: makeProject(id: 3)))
    }

    func testDefaultBucketResolution() {
        let buckets = [makeBucket(id: 8, title: "B", position: 2), makeBucket(id: 7, title: "A", position: 1)]
        var view = ProjectView(id: 12, title: "things-headings", projectId: 1, viewKind: "kanban")
        XCTAssertEqual(ThingsHeadingMapping.defaultBucketId(view: view, project: nil, buckets: buckets), 7)
        view.defaultBucketId = 8
        XCTAssertEqual(ThingsHeadingMapping.defaultBucketId(view: view, project: nil, buckets: buckets), 8)
        var project = makeProject(id: 1)
        project.defaultBucketId = 7
        XCTAssertEqual(ThingsHeadingMapping.defaultBucketId(view: nil, project: project, buckets: buckets), 7)
        XCTAssertNil(ThingsHeadingMapping.defaultBucketId(view: nil, project: nil, buckets: []))
    }

    func testArchivedTitles() {
        XCTAssertTrue(ThingsHeadingMapping.isArchivedTitle("[archived] Old"))
        XCTAssertFalse(ThingsHeadingMapping.isArchivedTitle("Old"))
        XCTAssertEqual(ThingsHeadingMapping.displayTitle(of: "[Archived]  Old"), "Old")
        XCTAssertEqual(ThingsHeadingMapping.bucketTitle(forHeading: "Old", archived: true), "[archived] Old")
        XCTAssertEqual(ThingsHeadingMapping.bucketTitle(forHeading: "[archived] Old", archived: false), "Old")
    }

    func testHeadingsExcludeDefaultBucketAndSort() {
        let buckets = [
            makeBucket(id: 3, title: "Second", position: 30),
            makeBucket(id: 1, title: "", position: 10),
            makeBucket(id: 2, title: "[archived] First", position: 20)
        ]
        let headings = ThingsHeadingMapping.headings(from: buckets, defaultBucketId: 1)
        XCTAssertEqual(headings.map { $0.id }, [2, 3])
        XCTAssertEqual(headings.map { $0.title }, ["First", "Second"])
        XCTAssertEqual(headings.map { $0.isArchived }, [true, false])
    }

    func testGroupTasksByBucketInPositionOrder() {
        let buckets = [
            makeBucket(id: 3, title: "Second", position: 30),
            makeBucket(id: 1, title: "", position: 10),
            makeBucket(id: 2, title: "First", position: 20)
        ]
        let tasks = [
            makeTask(id: 10, bucketId: 2, position: 5),
            makeTask(id: 11, bucketId: 2, position: 1),
            makeTask(id: 12, bucketId: nil, position: 2),
            makeTask(id: 13, bucketId: 99, position: 1),
            makeTask(id: 14, bucketId: 1, position: 3)
        ]
        let groups = ThingsHeadingMapping.groups(tasks: tasks, buckets: buckets, defaultBucketId: 1)
        XCTAssertEqual(groups.count, 3)
        XCTAssertNil(groups[0].heading)
        XCTAssertEqual(groups[0].bucketId, 1)
        XCTAssertEqual(groups[0].tasks.map { $0.id }, [13, 12, 14])
        XCTAssertEqual(groups[1].heading?.title, "First")
        XCTAssertEqual(groups[1].tasks.map { $0.id }, [11, 10])
        XCTAssertEqual(groups[2].heading?.title, "Second")
        XCTAssertTrue(groups[2].tasks.isEmpty)
    }

    func testGroupEmbeddedBucketTasks() {
        let buckets = [
            makeBucket(id: 1, title: "", position: 1, tasks: [makeTask(id: 1, position: 2), makeTask(id: 2, position: 1)]),
            makeBucket(id: 2, title: "H", position: 2, tasks: [makeTask(id: 3)])
        ]
        let groups = ThingsHeadingMapping.groups(from: buckets, defaultBucketId: 1)
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].tasks.map { $0.id }, [2, 1])
        XCTAssertEqual(groups[1].tasks.map { $0.id }, [3])
    }

    func testGroupWithoutBuckets() {
        let groups = ThingsHeadingMapping.groups(tasks: [makeTask(id: 1)], buckets: [], defaultBucketId: nil)
        XCTAssertEqual(groups.count, 1)
        XCTAssertNil(groups[0].bucketId)
        XCTAssertEqual(groups[0].tasks.count, 1)
    }

    // MARK: - Checklist

    func testChecklistProgress() {
        let items = [
            makeTask(id: 1, done: true),
            makeTask(id: 2, done: false),
            makeTask(id: 3, done: true)
        ]
        let parent = makeTask(id: 10, subtasks: items)
        let progress = ThingsChecklist.progress(of: parent)
        XCTAssertEqual(progress, ThingsChecklistProgress(done: 2, total: 3))
        XCTAssertEqual(progress?.label, "2/3")
        XCTAssertEqual(progress?.isComplete, false)
        XCTAssertEqual(progress?.fraction ?? 0, 2.0 / 3.0, accuracy: 0.0001)
    }

    func testChecklistEmpty() {
        XCTAssertNil(ThingsChecklist.progress(of: makeTask(id: 1)))
        let empty = ThingsChecklist.progress(of: [VTask]())
        XCTAssertTrue(empty.isEmpty)
        XCTAssertFalse(empty.isComplete)
        XCTAssertEqual(empty.fraction, 0)
    }

    func testChecklistComplete() {
        let progress = ThingsChecklist.progress(of: [makeTask(id: 1, done: true)])
        XCTAssertTrue(progress.isComplete)
        XCTAssertEqual(progress.fraction, 1)
    }

    func testChecklistItemsMaskedAndOrdered() {
        var child = makeTask(id: 2, position: 2)
        child.relatedTasks = ["parenttask": [makeTask(id: 1)]]
        let plain = makeTask(id: 3)
        XCTAssertTrue(ThingsChecklist.isChecklistItem(child))
        XCTAssertEqual(ThingsChecklist.topLevel([child, plain]).map { $0.id }, [3])
        let parent = makeTask(id: 1, subtasks: [makeTask(id: 5, position: 2), makeTask(id: 4, position: 1)])
        XCTAssertEqual(ThingsChecklist.items(of: parent).map { $0.id }, [4, 5])
    }
}
