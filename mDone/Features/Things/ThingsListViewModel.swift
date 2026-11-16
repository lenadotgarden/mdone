import Foundation
import SwiftUI

/// View model of a Things list, shared by the iPhone and Mac screens.
///
/// A thin facade over `AppState` (docs/ARCHITECTURE.md rule 3): it reads
/// `appState.tasks` and calls the existing mutators. It owns no task data, so
/// two instances for the same list always show the same thing.
///
/// Inbox project: the Inbox is `appState.defaultProject`, which is the project
/// the user picked in Settings (DefaultProjectPreference), else a project
/// titled "Inbox", else the first project. The same project receives a to-do
/// created from the Inbox, Today, Upcoming and Someday lists.
@Observable
@MainActor
final class ThingsListViewModel {
    let list: ThingsList

    // Internal (was private) so the extension files, for example
    // ThingsListViewModel+NaturalLanguage.swift, can reach them.
    let appState: AppState
    let calendar: Calendar
    let clock: () -> Date

    /// Ids of to-dos whose box was just ticked. They show as done and leave
    /// the list after `ThingsMotion.completionRemovalDelay` (spec 02 section 2).
    private(set) var pendingDoneIDs: Set<Int64> = []
    @ObservationIgnored private var pendingCompletions: [Int64: Task<Void, Never>] = [:]

    init(
        list: ThingsList,
        appState: AppState,
        calendar: Calendar = Calendar.current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.list = list
        self.appState = appState
        self.calendar = calendar
        self.clock = now
    }

    // MARK: - Reading

    /// The Inbox project id, nil while no project is loaded.
    var inboxProjectID: Int64? {
        appState.defaultProject?.id
    }

    /// Everything derived from the tasks, memoized in `AppState` and shared by
    /// every list view model. It is rebuilt only when the tasks, the Inbox
    /// project or the day change, not on each body evaluation. Reading
    /// `appState.tasks` here is what registers the observation, so a change of
    /// the tasks still redraws the views that read this model.
    private var derived: ThingsListsCache.Entry {
        let tasks = appState.tasks
        return appState.thingsCache.entry(
            tasks: tasks,
            tasksRevision: appState.tasksRevision,
            inboxProjectID: inboxProjectID,
            now: clock(),
            calendar: calendar
        )
    }

    /// The raw sections of the list.
    var sections: [ThingsListSection] {
        derived.snapshot.sections[list] ?? []
    }

    /// The sections with their rows mapped to display models. Memoized on the
    /// derived data and the ticked boxes, the only other input.
    var displaySections: [ThingsDisplaySection] {
        let entry = derived
        let pending = pendingDoneIDs
        if let memo = displayMemo, memo.generation == entry.generation, memo.pending == pending {
            return memo.sections
        }
        let built = ThingsRowMapper.displaySections(
            entry.snapshot.sections[list] ?? [],
            list: list,
            pendingDone: pending,
            now: clock(),
            calendar: calendar
        )
        displayMemo = DisplayMemo(generation: entry.generation, pending: pending, sections: built)
        return built
    }

    private struct DisplayMemo {
        let generation: UInt64
        let pending: Set<Int64>
        let sections: [ThingsDisplaySection]
    }

    @ObservationIgnored private var displayMemo: DisplayMemo?

    /// Row ids in display order, handy to animate list changes.
    var rowIDs: [String] {
        displaySections.flatMap { section in section.rows.map { $0.id } }
    }

    /// Task counts of every list, for the Home badges.
    var counts: [ThingsList: Int] {
        derived.snapshot.counts
    }

    /// The task count of one list.
    func count(for other: ThingsList) -> Int {
        derived.snapshot.counts[other] ?? 0
    }

    /// The header of a section.
    func headerStyle(for section: ThingsDisplaySection) -> ThingsSectionHeaderStyle? {
        ThingsRowMapper.headerStyle(for: section.kind, list: list, now: clock(), calendar: calendar)
    }

    /// Tomorrow, as the start of its day, for the "Tomorrow" choice of the When menu.
    var tomorrow: Date {
        let today = calendar.startOfDay(for: clock())
        return calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    // MARK: - Projects

    /// The open to-dos of a project as rows, in the project's order.
    func projectRows(projectID: Int64) -> [ThingsDisplayRow] {
        let tasks = ThingsChecklist.topLevel(appState.tasksForProject(projectID))
        let section = ThingsListSection(id: "project.\(projectID)", kind: .normal, tasks: tasks)
        let mapped = ThingsRowMapper.displaySections(
            [section], list: nil, pendingDone: pendingDoneIDs, now: clock(), calendar: calendar
        )
        return mapped.first?.rows ?? []
    }

    /// Share of finished to-dos in a project, 0 to 1 (spec 06 section 15 leaves
    /// the exact rule open; this is done over all top level to-dos). One
    /// dictionary lookup: the shares of every project are computed together.
    func progress(ofProject projectID: Int64) -> Double {
        derived.progressByProject[projectID] ?? 0
    }

    // MARK: - Actions

    /// Pull to refresh.
    func refresh() async {
        await appState.refreshAll()
    }

    /// Completes or reopens a to-do right away, without the delay.
    func toggleDone(_ task: VTask) async {
        await appState.toggleTaskDone(task)
    }

    /// The tap on a checkbox. Ticking an open to-do shows it as done at once and
    /// completes it after the delay, so a second tap in between undoes it.
    /// Reopening a finished to-do is immediate.
    func tapCheckbox(_ task: VTask) {
        let id = task.id
        if task.done {
            Task { await self.toggleDone(task) }
            return
        }
        if let running = pendingCompletions[id] {
            running.cancel()
            pendingCompletions[id] = nil
            withAnimation(ThingsMotion.checkboxToggle) {
                _ = pendingDoneIDs.remove(id)
            }
            return
        }
        withAnimation(ThingsMotion.checkboxToggle) {
            _ = pendingDoneIDs.insert(id)
        }
        let delay = UInt64(ThingsMotion.completionRemovalDelay * 1_000_000_000)
        pendingCompletions[id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            if Task.isCancelled { return }
            await self?.finishCompletion(of: task)
        }
    }

    private func finishCompletion(of task: VTask) async {
        await toggleDone(task)
        pendingCompletions[task.id] = nil
        withAnimation(ThingsMotion.rowRemoval) {
            _ = pendingDoneIDs.remove(task.id)
        }
    }

    /// Creates a to-do in the place the list implies (06 section 16):
    /// Inbox project for the Inbox, start date today for Today, the evening
    /// label for This Evening, the someday label for Someday, tomorrow for
    /// Upcoming. Anytime uses the first project that is not the Inbox, since a
    /// to-do of the Inbox project without a When belongs to the Inbox list.
    ///
    /// - Parameter when: overrides the When the list implies, for example
    ///   `.thisEvening` from the evening section of Today.
    @discardableResult
    func quickAdd(title: String, when: ThingsWhen? = nil) async -> VTask? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let projectID = quickAddProjectID else { return nil }
        if let plan = naturalLanguagePlan(for: trimmed) {
            return await create(plan: plan, defaultProjectID: projectID, defaultWhen: when ?? impliedWhen)
        }
        return await create(title: trimmed, projectID: projectID, when: when ?? impliedWhen)
    }

    /// Creates a to-do in `projectID` without a When.
    @discardableResult
    func quickAdd(title: String, inProject projectID: Int64) async -> VTask? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let plan = naturalLanguagePlan(for: trimmed) {
            return await create(plan: plan, defaultProjectID: projectID, defaultWhen: ThingsWhen.none)
        }
        return await create(title: trimmed, projectID: projectID, when: ThingsWhen.none)
    }

    /// The When a to-do created in this list gets.
    var impliedWhen: ThingsWhen {
        switch list {
        case .today: return .today
        case .someday: return .someday
        case .upcoming: return .date(tomorrow)
        case .inbox, .anytime, .logbook: return ThingsWhen.none
        }
    }

    private var quickAddProjectID: Int64? {
        if list == .anytime {
            let tree = ThingsProjectTree.build(projects: appState.projects, inboxProjectID: inboxProjectID)
            return tree.looseProjects.first?.project.id ?? inboxProjectID
        }
        return inboxProjectID
    }

    /// Creates the task, then applies the When. AppState.createTask has no
    /// start date, and takes labels by id only, so the start date goes through
    /// `updateTask` and the reserved labels are looked up (or created) first.
    private func create(title: String, projectID: Int64, when: ThingsWhen) async -> VTask? {
        let patch = ThingsWhen.patch(for: when, now: clock(), calendar: calendar)
        var labelIDs: [Int64] = []
        for labelTitle in patch.addLabels {
            if let label = await ensureLabel(title: labelTitle) {
                labelIDs.append(label.id)
            }
        }
        guard let created = await appState.createTask(
            title: title, projectId: projectID, labelIds: labelIDs
        ) else { return nil }
        if case .set(let date) = patch.startDate {
            await appState.updateTask(id: created.id, request: TaskUpdateRequest(startDate: date))
        }
        return appState.tasks.first(where: { $0.id == created.id }) ?? created
    }

    /// Changes the When of a to-do: start date through `updateTask`, reserved
    /// labels through the label endpoints (Vikunja ignores labels on update).
    func schedule(_ task: VTask, when: ThingsWhen) async {
        let live = appState.tasks.first(where: { $0.id == task.id }) ?? task
        let patch = ThingsWhen.patch(for: when, now: clock(), calendar: calendar)
            .minimized(against: live, calendar: calendar)
        switch patch.startDate {
        case .unchanged:
            break
        case .set(let date):
            await appState.updateTask(id: live.id, request: TaskUpdateRequest(startDate: date))
        case .clear:
            await appState.updateTask(id: live.id, request: TaskUpdateRequest(clearStartDate: true))
        }
        for labelTitle in patch.addLabels {
            if let label = await ensureLabel(title: labelTitle), !appState.hasLabel(label, on: live) {
                await appState.toggleLabel(label, on: live)
            }
        }
        for labelTitle in patch.removeLabels {
            let current = appState.tasks.first(where: { $0.id == live.id }) ?? live
            let present = (current.labels ?? []).first { ThingsReservedLabels.matches($0.title, labelTitle) }
            if let label = present {
                await appState.toggleLabel(label, on: current)
            }
        }
    }

    /// Deletes a to-do (permanent on iOS, spec 06 section 16).
    func delete(_ task: VTask) async {
        await appState.deleteTask(task)
    }

    private func ensureLabel(title: String) async -> VLabel? {
        if let existing = appState.labels.first(where: { ThingsReservedLabels.matches($0.title, title) }) {
            return existing
        }
        return await appState.createLabel(title: title)
    }
}
