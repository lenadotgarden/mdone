import Foundation

/// The "Smart parsing" switch (`SmartParsingPreference`) as the Things
/// interface reads it. Léna asked for natural language in Things, so here a
/// missing key means ON, where the old quick-add bar defaults to off. Once the
/// user flips the switch in Settings the stored value wins on both screens.
enum ThingsNaturalLanguagePreference {
    static let defaultValue = true

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: SmartParsingPreference.storageKey) as? Bool ?? defaultValue
    }
}

extension ThingsNaturalLanguage {
    /// The mapper fed with the projects and tags the app has loaded, the
    /// current clock and the user's preference.
    @MainActor
    static func current(appState: AppState, now: Date = Date()) -> ThingsNaturalLanguage {
        ThingsNaturalLanguage(
            projectModels: appState.projects,
            labelModels: appState.labels,
            isEnabled: ThingsNaturalLanguagePreference.isEnabled(),
            now: now,
            calendar: Calendar.app
        )
    }
}

/// Natural language creation (docs/things-spec/WIRING-AGENT3.md). The two
/// `quickAdd` methods of the main file call `naturalLanguagePlan(for:)` first,
/// so every entry point (iPhone empty row and Magic Plus, Mac empty row, Quick
/// Entry) goes through here without changing its own code.
extension ThingsListViewModel {
    /// The plan for `text`, or nil when the preference is off or the text names
    /// no field. nil means: create the to-do with the typed title as before.
    func naturalLanguagePlan(for text: String) -> ThingsNaturalLanguagePlan? {
        let mapper = ThingsNaturalLanguage.current(appState: appState, now: clock())
        guard mapper.isEnabled else { return nil }
        let plan = mapper.plan(for: text)
        return plan.hasEffect ? plan : nil
    }

    /// Creates the to-do described by `plan`.
    ///
    /// - Parameters:
    ///   - defaultProjectID: the project when the text named none (`+Project`).
    ///   - defaultWhen: the When the list implies, used when the text named none.
    ///
    /// Same two step creation as the main file: `createTask` takes title,
    /// notes (the estimate marker), deadline, priority and tags, then one
    /// `updateTask` sets the start date, the reminder and the repeat. A To-do
    /// with a reminder always has a When (07 section 6), the mapper guarantees it.
    func create(plan: ThingsNaturalLanguagePlan, defaultProjectID: Int64, defaultWhen: ThingsWhen) async -> VTask? {
        let when = plan.when ?? defaultWhen
        let projectID = plan.projectID ?? defaultProjectID
        let patch = ThingsWhen.patch(for: when, now: clock(), calendar: calendar)

        var labelIDs = plan.labelIDs
        for labelTitle in patch.addLabels {
            if let label = await ensureReservedLabel(title: labelTitle), !labelIDs.contains(label.id) {
                labelIDs.append(label.id)
            }
        }

        guard let created = await appState.createTask(
            title: plan.title,
            projectId: projectID,
            description: EstimateMarker.apply(plan.estimateSeconds, to: nil),
            dueDate: plan.deadline,
            priority: plan.priority,
            labelIds: labelIDs
        ) else { return nil }

        var request = TaskUpdateRequest()
        if case .set(let date) = patch.startDate {
            request.startDate = date
        }
        if let reminder = plan.reminder {
            request.reminders = [TaskReminder(reminder: reminder, relativePeriod: nil, relativeTo: nil)]
        }
        if let repeatRule = plan.repeatRule {
            request.repeatAfter = repeatRule.repeatAfter
            request.repeatMode = repeatRule.repeatMode
        }
        if !request.isEmpty {
            await appState.updateTask(id: created.id, request: request)
        }
        return appState.tasks.first(where: { $0.id == created.id }) ?? created
    }

    private func ensureReservedLabel(title: String) async -> VLabel? {
        if let existing = appState.labels.first(where: { ThingsReservedLabels.matches($0.title, title) }) {
            return existing
        }
        return await appState.createLabel(title: title)
    }
}
