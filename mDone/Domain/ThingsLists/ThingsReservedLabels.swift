import Foundation

/// Label titles that carry Things semantics on top of plain Vikunja labels
/// (docs/things-spec/07-vikunja-mapping.md, sections 7, 8, 10 and 16).
///
/// They are matched case-insensitively and ignoring surrounding whitespace,
/// because labels can be created by hand in the Vikunja web app.
enum ThingsReservedLabels {
    /// Marks a Today task as "This Evening".
    static let evening = "things:evening"
    /// Marks a task as Someday. The label wins over any start date.
    static let someday = "things:someday"
    /// Marks a done task as cancelled rather than completed.
    static let cancelled = "things:cancelled"

    /// Every reserved title.
    static let all: [String] = [evening, someday, cancelled]

    /// Whether `title` is `reserved`, ignoring case and surrounding whitespace.
    static func matches(_ title: String, _ reserved: String) -> Bool {
        normalized(title) == normalized(reserved)
    }

    /// Whether `title` is any reserved title. Useful to hide them from tag UIs.
    static func isReserved(_ title: String) -> Bool {
        let key = normalized(title)
        return all.contains { normalized($0) == key }
    }

    /// Whether any of `titles` is `reserved`.
    static func contains(_ reserved: String, in titles: [String]) -> Bool {
        titles.contains { matches($0, reserved) }
    }

    private static func normalized(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension VTask {
    /// The titles of this task's labels. Empty when it has none.
    var thingsLabelTitles: [String] {
        (labels ?? []).map { $0.title }
    }

    /// Carries the reserved `things:evening` label.
    var hasThingsEveningLabel: Bool {
        ThingsReservedLabels.contains(ThingsReservedLabels.evening, in: thingsLabelTitles)
    }

    /// Carries the reserved `things:someday` label.
    var hasThingsSomedayLabel: Bool {
        ThingsReservedLabels.contains(ThingsReservedLabels.someday, in: thingsLabelTitles)
    }

    /// Carries the reserved `things:cancelled` label.
    var hasThingsCancelledLabel: Bool {
        ThingsReservedLabels.contains(ThingsReservedLabels.cancelled, in: thingsLabelTitles)
    }
}
