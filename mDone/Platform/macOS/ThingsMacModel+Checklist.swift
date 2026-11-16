import SwiftUI

#if os(macOS)

/// Checklist edits made in the open card, each with an undo step. A checklist item is a
/// subtask of the to-do (spec 07 section 5). Undoing the delete of an item creates it
/// again, so its id changes like for a deleted to-do (see `ThingsMacModel+Undo`).
extension ThingsMacModel {
    func addChecklistItem(title: String, to parent: VTask) {
        let text = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return }
        let state = appState
        let parentID = parent.id
        let existing = Set(ThingsChecklist.items(of: parent).map { $0.id })
        Task { @MainActor in
            let created = await state.createSubtask(title: text, parent: parent)
            if !created { return }
            guard let newID = self.newChecklistItemID(parentID: parentID, excluding: existing) else { return }
            self.recordUndo(
                String(localized: "Change Checklist"),
                undo: { [weak self] in await self?.deleteQuietly(newID) },
                redo: { [weak self] in
                    await self?.recreateChecklistItem(title: text, done: false, parentID: parentID, replacing: newID)
                }
            )
        }
    }

    func toggleChecklistItem(_ item: VTask) {
        let state = appState
        let id = item.id
        let wasDone = item.done
        Task { @MainActor in
            await state.toggleTaskDone(item)
            self.recordUndo(
                String(localized: "Change Checklist"),
                undo: { [weak self] in await self?.setDone(id, done: wasDone) },
                redo: { [weak self] in await self?.setDone(id, done: !wasDone) }
            )
        }
    }

    func renameChecklistItem(_ item: VTask, to newTitle: String) {
        let text = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text == item.title { return }
        let state = appState
        let id = item.id
        let oldTitle = item.title
        Task { @MainActor in
            var request = TaskUpdateRequest()
            request.title = text
            await state.updateTask(id: id, request: request)
            self.recordUndo(
                String(localized: "Change Checklist"),
                key: "checklist.\(id)",
                undo: { [weak self] in await self?.writeChecklistTitle(id, oldTitle) },
                redo: { [weak self] in await self?.writeChecklistTitle(id, text) }
            )
        }
    }

    func deleteChecklistItem(_ item: VTask, parent: VTask) {
        let state = appState
        let id = item.id
        let parentID = parent.id
        let title = item.title
        let wasDone = item.done
        Task { @MainActor in
            await state.deleteTask(item)
            if state.tasks.contains(where: { $0.id == id }) { return }
            self.recordUndo(
                String(localized: "Change Checklist"),
                undo: { [weak self] in
                    await self?.recreateChecklistItem(title: title, done: wasDone, parentID: parentID, replacing: id)
                },
                redo: { [weak self] in await self?.deleteQuietly(id) }
            )
        }
    }

    // MARK: - Helpers

    private func newChecklistItemID(parentID: Int64, excluding existing: Set<Int64>) -> Int64? {
        guard let parent = liveTask(parentID) else { return nil }
        return ThingsChecklist.items(of: parent).map { $0.id }.first { !existing.contains($0) }
    }

    private func writeChecklistTitle(_ id: Int64, _ title: String) async {
        let resolved = liveID(id)
        guard appState.tasks.contains(where: { $0.id == resolved }) else { return }
        var request = TaskUpdateRequest()
        request.title = title
        await appState.updateTask(id: resolved, request: request)
    }

    private func recreateChecklistItem(title: String, done: Bool, parentID: Int64, replacing originalID: Int64) async {
        guard let parent = liveTask(parentID) else { return }
        let existing = Set(ThingsChecklist.items(of: parent).map { $0.id })
        let created = await appState.createSubtask(title: title, parent: parent)
        if !created { return }
        guard let newID = newChecklistItemID(parentID: parent.id, excluding: existing) else { return }
        let previous = liveID(originalID)
        idAliases[originalID] = newID
        idAliases[previous] = newID
        if done, let item = appState.tasks.first(where: { $0.id == newID }) {
            await appState.toggleTaskDone(item)
        }
    }
}

#endif
