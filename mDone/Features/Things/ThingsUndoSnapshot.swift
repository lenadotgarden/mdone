import Foundation

/// Everything needed to create a to-do again after it was deleted (Undo Delete).
///
/// Vikunja cannot undelete a task: the new task gets a new id and a fresh position
/// (it lands where the server puts a new task of that project). Title, notes, dates,
/// tags, priority, project, repeat and checklist items come back; the creation date,
/// attachments, comments, reminders and assignees do not.
struct ThingsTaskSnapshot: Equatable {
    struct ChecklistItem: Equatable {
        var title: String
        var done: Bool
    }

    var title: String
    /// The raw stored description, estimate marker included.
    var description: String?
    var dueDate: Date?
    var startDate: Date?
    var priority: Int64
    var projectID: Int64
    /// Every label of the task, the reserved This Evening and Someday ones included.
    var labelIDs: [Int64]
    var repeatAfter: Int64?
    var repeatMode: Int64?
    var done: Bool
    var checklist: [ChecklistItem]

    init(task: VTask, calendar: Calendar = .current) {
        title = task.title
        description = task.description
        dueDate = ThingsWhen.validDate(task.dueDate, calendar: calendar)
        startDate = ThingsWhen.validDate(task.startDate, calendar: calendar)
        priority = task.priority
        projectID = task.projectId
        labelIDs = (task.labels ?? []).map { $0.id }
        repeatAfter = task.repeatAfter
        repeatMode = task.repeatMode
        done = task.done
        checklist = ThingsChecklist.items(of: task).map { ChecklistItem(title: $0.title, done: $0.done) }
    }

    /// Whether the task repeats, so the recreate step must send the repeat fields.
    var hasRepeat: Bool {
        (repeatAfter ?? 0) > 0 || (repeatMode ?? 0) > 0
    }
}

/// The When of a to-do as it is stored: a start date and the two reserved labels. Undo
/// restores this raw state rather than a `ThingsWhen`, so a start date in the past or
/// at a particular time comes back exactly.
struct ThingsWhenState: Equatable {
    var startDate: Date?
    var isEvening: Bool
    var isSomeday: Bool

    init(startDate: Date?, isEvening: Bool, isSomeday: Bool) {
        self.startDate = startDate
        self.isEvening = isEvening
        self.isSomeday = isSomeday
    }

    init(task: VTask, calendar: Calendar = .current) {
        startDate = ThingsWhen.validDate(task.startDate, calendar: calendar)
        isEvening = task.hasThingsEveningLabel
        isSomeday = task.hasThingsSomedayLabel
    }
}
