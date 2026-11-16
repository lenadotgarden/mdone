import Foundation

/// A task together with the model its row displays.
struct ThingsDisplayRow: Identifiable {
    let task: VTask
    var model: ThingsTodoRowModel

    var id: String { model.id }
}

/// A list section whose tasks are mapped to row models.
struct ThingsDisplaySection: Identifiable {
    let id: String
    let kind: ThingsListSection.Kind
    var rows: [ThingsDisplayRow]
}

/// Pure mapping from tasks to display models (spec 02 section 2, 06 section 2).
/// No app state: everything comes in as arguments so it can be tested.
enum ThingsRowMapper {
    // MARK: - Rows

    /// The row model of `task`.
    ///
    /// - Parameters:
    ///   - list: the list being shown, nil inside a project. In Anytime and in
    ///     projects a task that is in Today gets the yellow star (spec 02 section 2).
    ///   - isPendingDone: the user just ticked the box and the row is waiting
    ///     to leave the list, so it shows as done already.
    static func model(
        for task: VTask,
        list: ThingsList?,
        isPendingDone: Bool = false,
        now: Date,
        calendar: Calendar
    ) -> ThingsTodoRowModel {
        var model = ThingsTodoRowModel(id: String(task.id), title: task.title)
        model.checkbox = checkboxState(for: task, isPendingDone: isPendingDone)
        model.hasNotes = hasNotes(task)
        model.tags = tags(for: task)
        if !task.done {
            model.deadlineDaysRemaining = ThingsDeadline.daysLeft(
                dueDate: task.dueDate, now: now, calendar: calendar
            )
        }
        model.checklistLabel = ThingsChecklist.progress(of: task)?.label
        model.isRepeating = task.isRepeating
        model.showsTodayStar = showsTodayStar(task, list: list, now: now, calendar: calendar)
        model.isDimmed = list != .someday && task.hasThingsSomedayLabel && !task.done
        return model
    }

    static func checkboxState(for task: VTask, isPendingDone: Bool) -> ThingsCheckboxState {
        if task.done {
            return task.hasThingsCancelledLabel ? .cancelled : .done
        }
        return isPendingDone ? .done : .open
    }

    /// Label titles shown as tags: every label but the reserved ones.
    static func tags(for task: VTask) -> [String] {
        task.thingsLabelTitles.filter { title in
            !ThingsReservedLabels.isReserved(title)
                && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// Whether the description holds text. Web-app descriptions are HTML, so an
    /// empty paragraph counts as no notes.
    static func hasNotes(_ task: VTask) -> Bool {
        let text = (task.userVisibleDescription ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return false }
        return text != "<p></p>"
    }

    static func showsTodayStar(_ task: VTask, list: ThingsList?, now: Date, calendar: Calendar) -> Bool {
        if task.done { return false }
        if list != nil && list != .anytime { return false }
        let when = ThingsWhen.resolve(task: task, now: now, calendar: calendar)
        return when == .today || when == .thisEvening
    }

    // MARK: - Sections

    /// Maps list sections to display sections.
    static func displaySections(
        _ sections: [ThingsListSection],
        list: ThingsList?,
        pendingDone: Set<Int64>,
        now: Date,
        calendar: Calendar
    ) -> [ThingsDisplaySection] {
        sections.map { section in
            let rows = section.tasks.map { task in
                ThingsDisplayRow(
                    task: task,
                    model: model(
                        for: task,
                        list: list,
                        isPendingDone: pendingDone.contains(task.id),
                        now: now,
                        calendar: calendar
                    )
                )
            }
            return ThingsDisplaySection(id: section.id, kind: section.kind, rows: rows)
        }
    }

    // MARK: - Section headers

    /// The header of a section, nil for the plain block (spec 02 sections 4, 5, 8).
    static func headerStyle(
        for kind: ThingsListSection.Kind,
        list: ThingsList,
        now: Date,
        calendar: Calendar
    ) -> ThingsSectionHeaderStyle? {
        switch kind {
        case .normal:
            return nil
        case .evening:
            return .evening(title: String(localized: "This Evening"))
        case .overdue:
            return .standard(title: String(localized: "Overdue"))
        case .dateGroup(let day):
            let label = dayLabel(for: day, now: now, calendar: calendar)
            if list == .upcoming {
                let number = String(calendar.component(.day, from: day))
                return .upcomingDay(day: number, label: label)
            }
            return .standard(title: label)
        case .monthGroup(let month):
            return .standard(title: monthTitle(for: month, calendar: calendar))
        }
    }

    /// "Today", "Tomorrow", "Yesterday", else the weekday and date.
    static func dayLabel(for day: Date, now: Date, calendar: Calendar) -> String {
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: day)
        let offset = calendar.dateComponents([.day], from: today, to: target).day ?? 0
        if offset == 0 { return String(localized: "Today") }
        if offset == 1 { return String(localized: "Tomorrow") }
        if offset == -1 { return String(localized: "Yesterday") }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale ?? Locale.current
        formatter.setLocalizedDateFormatFromTemplate(offset > 0 && offset <= 7 ? "EEEE" : "EEEdMMMM")
        return formatter.string(from: day)
    }

    static func monthTitle(for month: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale ?? Locale.current
        formatter.setLocalizedDateFormatFromTemplate("LLLLyyyy")
        return formatter.string(from: month)
    }
}
