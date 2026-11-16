import SwiftUI

#if os(macOS)
import AppKit

/// Undo and redo of the Things window (Cmd Z, Shift Cmd Z, Edit menu).
///
/// The history is a `ThingsUndoStack`; every mutation made from the Things UI records a
/// closure pair through `recordUndo`. The closures go through the same `AppState`
/// mutators as the original action, with ids captured at record time and resolved with
/// `liveID` when they run.
///
/// Vikunja cannot undelete a task. Undo Delete creates the task again (same title, notes,
/// dates, tags, priority, project, repeat and checklist) and the id changes, so the model
/// keeps `idAliases` and older steps that name the deleted id follow it to the new task.
/// The new task is placed by the server, not at its old position.
extension ThingsMacModel {
    // MARK: - State for the menu

    var canUndo: Bool { undoStack.canUndo }
    var canRedo: Bool { undoStack.canRedo }

    /// "Undo Complete To-Do", or "Undo" when there is nothing to undo.
    var undoMenuTitle: String {
        guard let title = undoStack.undoTitle else { return String(localized: "Undo") }
        return String(localized: "Undo \(title)")
    }

    var redoMenuTitle: String {
        guard let title = undoStack.redoTitle else { return String(localized: "Redo") }
        return String(localized: "Redo \(title)")
    }

    /// A text field may have the keyboard: the open card, the new to-do row, Quick Find or
    /// a sheet. The Edit menu items stay enabled then so Cmd Z reaches the field's own undo.
    var textEditingActive: Bool {
        expandedTaskID != nil || isAddingTodo || showQuickFind || sheet != nil
    }

    /// A text view (the shared field editor of every `TextField`) is the first responder.
    static var isEditingText: Bool {
        NSApp.keyWindow?.firstResponder is NSText
    }

    // MARK: - Recording and running

    /// Adds a step to the history. Ignored (and the history emptied) once the session ended.
    func recordUndo(
        _ title: String,
        key: String? = nil,
        undo: @escaping @MainActor () async -> Void,
        redo: @escaping @MainActor () async -> Void
    ) {
        guard appState.isAuthenticated else {
            clearUndoHistory()
            return
        }
        undoStack.record(ThingsUndoCommand(title: title, coalescingKey: key, undo: undo, redo: redo))
    }

    /// Empties the history. Called on logout so a new session never undoes the old one.
    func clearUndoHistory() {
        undoStack.clear()
        idAliases.removeAll()
    }

    /// Edit > Undo. A focused text field keeps its own undo.
    func undoFromMenu() {
        if Self.isEditingText {
            NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
            return
        }
        performUndo()
    }

    /// Edit > Redo. A focused text field keeps its own redo.
    func redoFromMenu() {
        if Self.isEditingText {
            NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
            return
        }
        performRedo()
    }

    func performUndo() {
        guard !isUndoRunning else { return }
        guard appState.isAuthenticated else {
            clearUndoHistory()
            return
        }
        guard let command = undoStack.popUndo() else { return }
        isUndoRunning = true
        Task { @MainActor in
            await command.undo()
            self.isUndoRunning = false
        }
    }

    func performRedo() {
        guard !isUndoRunning else { return }
        guard appState.isAuthenticated else {
            clearUndoHistory()
            return
        }
        guard let command = undoStack.popRedo() else { return }
        isUndoRunning = true
        Task { @MainActor in
            await command.redo()
            self.isUndoRunning = false
        }
    }

    // MARK: - Ids

    /// The id a step recorded for `id` should act on now: follows the replacements made by
    /// Undo Delete, from the original id to the newest task.
    func liveID(_ id: Int64) -> Int64 {
        var current = id
        var hops = 0
        while let next = idAliases[current], next != current, hops < 32 {
            current = next
            hops += 1
        }
        return current
    }

    func liveTask(_ id: Int64) -> VTask? {
        let resolved = liveID(id)
        return appState.tasks.first { $0.id == resolved }
    }

    // MARK: - Building blocks of the steps

    /// Creates the to-do again from a snapshot (Undo Delete, Redo Create, Undo Duplicate).
    /// Points `originalID` at the new task so older steps keep working.
    @discardableResult
    func recreate(_ snapshot: ThingsTaskSnapshot, replacing originalID: Int64?) async -> VTask? {
        let state = appState
        guard let created = await state.createTask(
            title: snapshot.title,
            projectId: snapshot.projectID,
            description: snapshot.description,
            dueDate: snapshot.dueDate,
            priority: snapshot.priority,
            labelIds: snapshot.labelIDs
        ) else { return nil }

        var request = TaskUpdateRequest()
        if let start = snapshot.startDate { request.startDate = start }
        if snapshot.hasRepeat {
            request.repeatAfter = snapshot.repeatAfter
            request.repeatMode = snapshot.repeatMode
        }
        if !request.isEmpty {
            await state.updateTask(id: created.id, request: request)
        }
        for item in snapshot.checklist {
            await state.createSubtask(title: item.title, parent: created)
        }
        let doneTitles = snapshot.checklist.filter { $0.done }.map { $0.title }
        if !doneTitles.isEmpty, let parent = state.tasks.first(where: { $0.id == created.id }) {
            for item in ThingsChecklist.items(of: parent) where !item.done && doneTitles.contains(item.title) {
                await state.toggleTaskDone(item)
            }
        }
        if snapshot.done, let live = state.tasks.first(where: { $0.id == created.id }) {
            await state.toggleTaskDone(live)
        }
        if let originalID = originalID {
            let previous = liveID(originalID)
            idAliases[originalID] = created.id
            idAliases[previous] = created.id
        }
        return state.tasks.first { $0.id == created.id } ?? created
    }

    /// Deletes a to-do without recording a step (the undo of a creation).
    func deleteQuietly(_ id: Int64) async {
        guard let task = liveTask(id) else { return }
        await appState.deleteTask(task)
    }

    /// Writes a start date and the two reserved labels back.
    func restoreWhen(_ id: Int64, to wanted: ThingsWhenState) async {
        let resolved = liveID(id)
        guard appState.tasks.contains(where: { $0.id == resolved }) else { return }
        var request = TaskUpdateRequest()
        if let start = wanted.startDate {
            request.startDate = start
        } else {
            request.clearStartDate = true
        }
        await appState.updateTask(id: resolved, request: request)
        await setReservedLabel(ThingsReservedLabels.evening, present: wanted.isEvening, taskID: resolved)
        await setReservedLabel(ThingsReservedLabels.someday, present: wanted.isSomeday, taskID: resolved)
    }

    /// Makes a reserved label present or absent on a to-do.
    func setReservedLabel(_ title: String, present: Bool, taskID: Int64) async {
        let state = appState
        guard let live = state.tasks.first(where: { $0.id == taskID }) else { return }
        let current = (live.labels ?? []).first { ThingsReservedLabels.matches($0.title, title) }
        if present {
            if current != nil { return }
            var label = state.labels.first { ThingsReservedLabels.matches($0.title, title) }
            if label == nil { label = await state.createLabel(title: title) }
            if let label = label { await state.toggleLabel(label, on: live) }
        } else if let current = current {
            await state.toggleLabel(current, on: live)
        }
    }

    /// Writes a deadline back, or clears it.
    func restoreDeadline(_ id: Int64, to date: Date?) async {
        let resolved = liveID(id)
        guard appState.tasks.contains(where: { $0.id == resolved }) else { return }
        var request = TaskUpdateRequest()
        if let date = date {
            request.dueDate = date
        } else {
            request.clearDueDate = true
        }
        await appState.updateTask(id: resolved, request: request)
    }

    /// Puts a tag on a to-do or takes it off.
    func setTag(_ label: VLabel, present: Bool, taskID: Int64) async {
        let state = appState
        guard let live = state.tasks.first(where: { $0.id == liveID(taskID) }) else { return }
        if state.hasLabel(label, on: live) != present {
            await state.toggleLabel(label, on: live)
        }
    }

    /// Sets a to-do done or open, whatever its state is now.
    func setDone(_ id: Int64, done: Bool) async {
        guard let live = liveTask(id), live.done != done else { return }
        await appState.toggleTaskDone(live)
    }

    // MARK: - Steps with their own shape

    /// A step for a reorder: back to the old position, or forward to the new one. A move
    /// into another section also changes the When (`newWhen`), which the undo writes back
    /// from `previousWhen`.
    func recordReorder(
        taskID: Int64,
        oldPosition: Double,
        newPosition: Double,
        previousWhen: ThingsWhenState?,
        newWhen: ThingsWhen?,
        listModel: ThingsListViewModel
    ) {
        let state = appState
        recordUndo(
            String(localized: "Move To-Do"),
            key: "reorder.\(taskID)",
            undo: { [weak self] in
                guard let self = self, let live = self.liveTask(taskID) else { return }
                if let previous = previousWhen { await self.restoreWhen(taskID, to: previous) }
                await state.moveTask(self.liveTask(taskID) ?? live, toPosition: oldPosition)
            },
            redo: { [weak self] in
                guard let self = self, let live = self.liveTask(taskID) else { return }
                if let when = newWhen { await listModel.schedule(live, when: when) }
                await state.moveTask(self.liveTask(taskID) ?? live, toPosition: newPosition)
            }
        )
    }

    /// A step for a title or notes edit made in the open card.
    func recordEdit(
        taskID: Int64,
        oldTitle: String,
        newTitle: String,
        oldDescription: String?,
        newDescription: String?
    ) {
        recordUndo(
            String(localized: "Edit To-Do"),
            key: "edit.\(taskID)",
            undo: { [weak self] in await self?.writeEdit(taskID, title: oldTitle, description: oldDescription) },
            redo: { [weak self] in await self?.writeEdit(taskID, title: newTitle, description: newDescription) }
        )
    }

    private func writeEdit(_ taskID: Int64, title: String, description: String?) async {
        let resolved = liveID(taskID)
        guard appState.tasks.contains(where: { $0.id == resolved }) else { return }
        var request = TaskUpdateRequest()
        request.title = title
        request.description = description ?? ""
        await appState.updateTask(id: resolved, request: request)
    }
}

#endif
