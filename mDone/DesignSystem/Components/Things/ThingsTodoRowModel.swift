import Foundation

/// Plain value shown by ThingsTodoRow. Built by a Feature from its own state. This layer knows no app state or task model.
struct ThingsTodoRowModel: Identifiable, Equatable {
    var id: String
    var title: String
    var checkbox: ThingsCheckboxState = .open
    /// Shows the notes icon when there is no preview text.
    var hasNotes: Bool = false
    /// One line of notes shown under the title.
    var notesPreview: String? = nil
    var tags: [String] = []
    /// Days until the deadline (negative when past). Nil when none.
    var deadlineDaysRemaining: Int? = nil
    /// Checklist progress text such as "2/5". Nil when no checklist.
    var checklistLabel: String? = nil
    var isRepeating: Bool = false
    /// Show the yellow Today star in front of the checkbox (Anytime and projects).
    var showsTodayStar: Bool = false
    /// Reminder time text such as "9:00".
    var reminderText: String? = nil
    /// Draw dimmed, for Someday content.
    var isDimmed: Bool = false

    var isFinished: Bool { checkbox == .done || checkbox == .cancelled }
}
