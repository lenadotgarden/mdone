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
    /// Second line under the title on Mac: the name of the project or Area the
    /// to-do lives in, emoji included when the name carries one. Nil hides the line.
    var projectLine: String? = nil
    /// Short text in a pill in front of the title on Mac, for example the weekday "Thu".
    var datePill: String? = nil
    /// The to-do is in Someday: the checkbox outline is dashed on Mac.
    var isSomeday: Bool = false

    var isFinished: Bool { checkbox == .done || checkbox == .cancelled }

    /// Whether the Mac row is two lines high.
    var hasProjectLine: Bool { !(projectLine ?? "").isEmpty }
}
