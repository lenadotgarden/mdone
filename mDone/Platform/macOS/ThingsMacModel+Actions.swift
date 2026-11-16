import SwiftUI

#if os(macOS)

/// What the menu commands, the keyboard and the card do to to-dos. Each action
/// goes through an existing `AppState` mutator or `ThingsListViewModel` method, and
/// records an undo step (`ThingsMacModel+Undo`) once the change went through.
extension ThingsMacModel {
    // MARK: - Create

    /// New To-Do (Cmd N): opens the empty row of the list on screen. The
    /// Logbook cannot take a to-do, so the Inbox opens instead.
    func newTodo() {
        if case .list(let list) = route, !list.allowsQuickAdd {
            navigate(to: .list(.inbox))
        }
        insertAfterTaskID = nil
        isAddingTodo = true
    }

    /// Space (spec 05 "Create"): a new empty to-do right below the selected one, in the same
    /// list, section, project and When; with no to-do selected on a project screen, a new
    /// to-do at the top of that project. Returns false when there is nothing it applies
    /// to, so the caller can leave the key alone.
    @discardableResult
    func addTodoFromSpace() -> Bool {
        if expandedTaskID != nil || isAddingTodo { return false }
        if let id = selectedTaskID, selectedTask != nil {
            insertAfterTaskID = id
            isAddingTodo = true
            return true
        }
        if case .project = route {
            insertAfterTaskID = nil
            isAddingTodo = true
            return true
        }
        return false
    }

    /// Called by the empty row with the trimmed title (empty when the user gave up).
    /// `siblings` are the to-dos of the section the row sits in, in display order: the new
    /// to-do goes right after the anchor among them.
    func finishAdding(title: String, siblings: [VTask] = []) {
        let anchorID = insertAfterTaskID
        isAddingTodo = false
        insertAfterTaskID = nil
        if title.isEmpty {
            listFocusToken += 1
            return
        }
        let target = route
        let listModel = activeViewModel
        Task { @MainActor in
            var created: VTask?
            if let anchorID = anchorID, let anchor = self.appState.tasks.first(where: { $0.id == anchorID }) {
                created = await self.createBelow(anchor, title: title, siblings: siblings, listModel: listModel)
            } else {
                switch target {
                case .list:
                    created = await listModel.quickAdd(title: title)
                case .project(let projectID):
                    created = await listModel.quickAdd(title: title, inProject: projectID)
                }
            }
            if let created = created {
                self.selectedTaskID = created.id
                self.recordCreation(created)
            }
            self.listFocusToken += 1
        }
    }

    /// Creates a to-do in the project of `anchor` with the When of `anchor`, then puts it
    /// right after `anchor` among `siblings`.
    private func createBelow(
        _ anchor: VTask,
        title: String,
        siblings: [VTask],
        listModel: ThingsListViewModel
    ) async -> VTask? {
        let state = appState
        guard let first = await listModel.quickAdd(title: title, inProject: anchor.projectId) else { return nil }
        var created = state.tasks.first(where: { $0.id == first.id }) ?? first
        let calendar = Calendar.current
        // A date, tag or word of the title that named a When wins over the anchor's.
        if ThingsWhen.resolve(task: created, now: Date(), calendar: calendar) == ThingsWhen.none {
            let when = ThingsWhen.resolve(task: anchor, now: Date(), calendar: calendar)
            if when != ThingsWhen.none {
                await listModel.schedule(created, when: when)
                created = state.tasks.first(where: { $0.id == first.id }) ?? created
            }
        }
        let others = siblings.filter { $0.id != created.id }
        if let index = others.firstIndex(where: { $0.id == anchor.id }) {
            let position = TaskPositioning.position(forInserting: created, at: index + 1, into: others)
            await state.moveTask(created, toPosition: position)
        }
        return state.tasks.first(where: { $0.id == created.id }) ?? created
    }

    /// Undo of a creation deletes the to-do; redo creates it again (new id).
    private func recordCreation(_ task: VTask) {
        let snapshot = ThingsTaskSnapshot(task: task)
        let originalID = task.id
        recordUndo(
            String(localized: "New To-Do"),
            undo: { [weak self] in await self?.deleteQuietly(originalID) },
            redo: { [weak self] in await self?.recreate(snapshot, replacing: originalID) }
        )
    }

    func createProject(title: String, isArea: Bool) {
        let source = home
        Task { @MainActor in
            var created: Project?
            if isArea {
                created = await source.createArea(title: title)
            } else {
                created = await source.createProject(title: title)
            }
            if let created = created { self.navigate(to: .project(created.id)) }
        }
    }

    func duplicateSelected() {
        guard let task = selectedTask else { return }
        let state = appState
        Task { @MainActor in
            let labelIDs = (task.labels ?? []).map { $0.id }
            guard let copy = await state.createTask(
                title: task.title,
                projectId: task.projectId,
                description: task.description,
                dueDate: task.dueDate,
                priority: task.priority,
                labelIds: labelIDs
            ) else { return }
            if let start = ThingsWhen.validDate(task.startDate, calendar: Calendar.current) {
                await state.updateTask(id: copy.id, request: TaskUpdateRequest(startDate: start))
            }
            self.selectedTaskID = copy.id
            let live = state.tasks.first(where: { $0.id == copy.id }) ?? copy
            let snapshot = ThingsTaskSnapshot(task: live)
            let originalID = copy.id
            self.recordUndo(
                String(localized: "Duplicate To-Do"),
                undo: { [weak self] in await self?.deleteQuietly(originalID) },
                redo: { [weak self] in await self?.recreate(snapshot, replacing: originalID) }
            )
        }
    }

    // MARK: - Complete, cancel, delete

    /// The box was clicked, or Cmd K was pressed. Ticking an open to-do shows it done at
    /// once and completes it after `ThingsMotion.completionRemovalDelay`; a second tap in
    /// between cancels. One undo step per tick.
    func tapCheckbox(_ task: VTask) {
        let id = task.id
        let live = appState.tasks.first(where: { $0.id == id }) ?? task
        let listModel = activeViewModel
        let wasPending = listModel.pendingDoneIDs.contains(id)
        let key = "complete.\(id)"
        listModel.tapCheckbox(live)

        if live.done {
            recordUndo(
                String(localized: "Reopen To-Do"),
                undo: { [weak self] in await self?.setDone(id, done: true) },
                redo: { [weak self] in await self?.setDone(id, done: false) }
            )
            return
        }
        if wasPending {
            undoStack.discardNewest(ifKey: key)
            return
        }
        recordUndo(
            String(localized: "Complete To-Do"),
            key: key,
            undo: { [weak self] in
                guard let self = self, let current = self.liveTask(id) else { return }
                if listModel.pendingDoneIDs.contains(current.id) {
                    listModel.tapCheckbox(current)
                } else if current.done {
                    await self.appState.toggleTaskDone(current)
                }
            },
            redo: { [weak self] in
                guard let self = self, let current = self.liveTask(id) else { return }
                if current.done || listModel.pendingDoneIDs.contains(current.id) { return }
                listModel.tapCheckbox(current)
            }
        )
    }

    /// Complete (Cmd K): same delayed tick as a click on the box.
    func completeSelected() {
        guard let task = selectedTask else { return }
        tapCheckbox(task)
    }

    /// Cancel (Opt Cmd K): the reserved cancelled label, then done (07 mapping).
    func cancelSelected() {
        guard let task = selectedTask, !task.done else { return }
        let state = appState
        let id = task.id
        Task { @MainActor in
            let title = ThingsReservedLabels.cancelled
            var label = state.labels.first { ThingsReservedLabels.matches($0.title, title) }
            if label == nil {
                label = await state.createLabel(title: title)
            }
            if let label = label {
                await state.toggleLabel(label, on: task)
            }
            await state.toggleTaskDone(task)
            self.recordUndo(
                String(localized: "Cancel To-Do"),
                undo: { [weak self] in
                    guard let self = self else { return }
                    await self.setDone(id, done: false)
                    await self.setReservedLabel(ThingsReservedLabels.cancelled, present: false, taskID: self.liveID(id))
                },
                redo: { [weak self] in
                    guard let self = self else { return }
                    await self.setReservedLabel(ThingsReservedLabels.cancelled, present: true, taskID: self.liveID(id))
                    await self.setDone(id, done: true)
                }
            )
        }
    }

    /// Delete (Del, Backspace, Cmd Backspace): Things deletes at once and relies on undo,
    /// so there is no confirmation.
    func requestDeleteSelected() {
        deleteSelected()
    }

    func deleteSelected() {
        guard let task = selectedTask else { return }
        delete(task)
    }

    func confirmDeletion(_ task: VTask) {
        pendingDeletion = nil
        delete(task)
    }

    /// Deletes a to-do and records an undo step that creates it again. Vikunja cannot
    /// undelete, so the recreated to-do has a new id (see `recreate`).
    func delete(_ task: VTask) {
        let live = appState.tasks.first(where: { $0.id == task.id }) ?? task
        let snapshot = ThingsTaskSnapshot(task: live)
        let originalID = live.id
        if selectedTaskID == originalID {
            selectedTaskID = neighbourID(of: originalID)
        }
        if expandedTaskID == originalID { collapseEditor() }
        let listModel = activeViewModel
        Task { @MainActor in
            await listModel.delete(live)
            // A failed delete (offline, server error) leaves the to-do in place: no step.
            if self.appState.tasks.contains(where: { $0.id == originalID }) { return }
            self.recordUndo(
                String(localized: "Delete To-Do"),
                undo: { [weak self] in
                    guard let self = self else { return }
                    if let created = await self.recreate(snapshot, replacing: originalID) {
                        self.selectedTaskID = created.id
                    }
                },
                redo: { [weak self] in await self?.deleteQuietly(originalID) }
            )
            self.listFocusToken += 1
        }
    }

    /// The row to select after `id` leaves the list: the one below, else the one above.
    private func neighbourID(of id: Int64) -> Int64? {
        guard let index = visibleTaskIDs.firstIndex(of: id) else { return nil }
        if index + 1 < visibleTaskIDs.count { return visibleTaskIDs[index + 1] }
        if index > 0 { return visibleTaskIDs[index - 1] }
        return nil
    }

    // MARK: - Dates

    func schedule(_ when: ThingsWhen) {
        guard let task = selectedTask else { return }
        applyWhen(task, when)
    }

    /// Changes the When of a to-do and records an undo step with the stored state before
    /// and after (a start date and the two reserved labels). Several changes in a row
    /// (Ctrl ] pressed five times) undo together.
    func applyWhen(_ task: VTask, _ when: ThingsWhen) {
        let live = appState.tasks.first(where: { $0.id == task.id }) ?? task
        let before = ThingsWhenState(task: live)
        let id = live.id
        let listModel = activeViewModel
        Task { @MainActor in
            await listModel.schedule(live, when: when)
            guard let current = self.appState.tasks.first(where: { $0.id == id }) else { return }
            let after = ThingsWhenState(task: current)
            if after == before { return }
            self.recordUndo(
                String(localized: "Change When"),
                key: "when.\(id)",
                undo: { [weak self] in await self?.restoreWhen(id, to: before) },
                redo: { [weak self] in await self?.restoreWhen(id, to: after) }
            )
        }
    }

    /// Start date plus or minus `days` (Ctrl ] and friends). A to-do without a
    /// start date counts from today.
    func shiftStart(days: Int) {
        guard let task = selectedTask else { return }
        let calendar = Calendar.current
        let base = task.effectiveStartDate ?? Date()
        guard let moved = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: base)) else { return }
        schedule(.date(moved))
    }

    /// Deadline plus or minus `days` (Ctrl . and friends). A to-do without a
    /// deadline counts from today.
    func shiftDeadline(days: Int) {
        guard let task = selectedTask else { return }
        let calendar = Calendar.current
        let base = task.effectiveDueDate ?? Date()
        guard let moved = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: base)) else { return }
        setDeadline(ThingsWhen.noonLocal(moved, calendar: calendar), for: task)
    }

    /// Sets the deadline, or clears it when `date` is nil, and records an undo step.
    func setDeadline(_ date: Date?, for task: VTask) {
        let state = appState
        let live = state.tasks.first(where: { $0.id == task.id }) ?? task
        let before = ThingsWhen.validDate(live.dueDate, calendar: Calendar.current)
        let id = live.id
        Task { @MainActor in
            if let date = date {
                await state.updateTask(id: id, request: TaskUpdateRequest(dueDate: date))
            } else {
                await state.updateTask(id: id, request: TaskUpdateRequest(clearDueDate: true))
            }
            guard let current = state.tasks.first(where: { $0.id == id }) else { return }
            let after = ThingsWhen.validDate(current.dueDate, calendar: Calendar.current)
            if after == before { return }
            self.recordUndo(
                String(localized: "Change Deadline"),
                key: "deadline.\(id)",
                undo: { [weak self] in await self?.restoreDeadline(id, to: before) },
                redo: { [weak self] in await self?.restoreDeadline(id, to: after) }
            )
        }
    }

    // MARK: - Move and tags

    /// Moves a to-do to a project, an Area or the Inbox project.
    func move(_ task: VTask, toProject projectID: Int64) {
        let state = appState
        let live = state.tasks.first(where: { $0.id == task.id }) ?? task
        let oldProjectID = live.projectId
        let id = live.id
        Task { @MainActor in
            await state.updateTask(id: id, request: TaskUpdateRequest(projectId: projectID))
            if oldProjectID == projectID { return }
            self.recordUndo(
                String(localized: "Move To-Do"),
                undo: { [weak self] in
                    guard let self = self else { return }
                    await state.updateTask(id: self.liveID(id), request: TaskUpdateRequest(projectId: oldProjectID))
                },
                redo: { [weak self] in
                    guard let self = self else { return }
                    await state.updateTask(id: self.liveID(id), request: TaskUpdateRequest(projectId: projectID))
                }
            )
        }
    }

    /// Re-parents a project (or Area) under `parentID`, or at the top level
    /// when nil. Refuses a cycle or a no-op. The new parent is unfolded so the
    /// moved project stays visible.
    func moveProject(_ projectID: Int64, toParent parentID: Int64?) {
        let tree = projectTree
        guard tree.canMove(projectID: projectID, toParent: parentID) else { return }
        guard let project = appState.projects.first(where: { $0.id == projectID }) else { return }
        if let parentID = parentID { collapsedProjectIDs.remove(parentID) }
        let oldParentID = tree.node(id: projectID)?.parentID
        let state = appState
        Task { @MainActor in
            await state.moveProject(project, toParentId: parentID)
            if oldParentID == parentID { return }
            self.recordUndo(
                String(localized: "Move Project"),
                undo: { [weak self] in
                    guard let self = self,
                          let current = self.appState.projects.first(where: { $0.id == projectID }) else { return }
                    await self.appState.moveProject(current, toParentId: oldParentID)
                },
                redo: { [weak self] in
                    guard let self = self,
                          let current = self.appState.projects.first(where: { $0.id == projectID }) else { return }
                    await self.appState.moveProject(current, toParentId: parentID)
                }
            )
        }
    }

    /// What dropping `payload` on a sidebar row would do, nil when the row refuses it. Reads
    /// the facts from the app state and leaves the decision to `ThingsDropResolver`, so the
    /// hover highlight and the drop agree.
    func dropAction(for payload: ThingsDragPayload, on target: ThingsDropTarget) -> ThingsDropAction? {
        let task = payload.todoID.flatMap { id in appState.tasks.first(where: { $0.id == id }) }
        var canReparent = false
        if let projectID = payload.projectID, case .project(let parentID) = target {
            canReparent = projectTree.canMove(projectID: projectID, toParent: parentID)
        }
        let facts = ThingsDropFacts(
            taskProjectID: task?.projectId,
            taskWhen: task.map { ThingsWhen.resolve(task: $0, now: Date(), calendar: Calendar.current) },
            inboxProjectID: appState.defaultProject?.id,
            canReparent: canReparent
        )
        return ThingsDropResolver.action(for: payload, on: target, facts: facts)
    }

    /// Runs a drop on a sidebar row. Returns whether the row accepted it.
    @discardableResult
    func handleDrop(_ payload: ThingsDragPayload, on target: ThingsDropTarget) -> Bool {
        guard let action = dropAction(for: payload, on: target) else { return false }
        switch action {
        case .moveTodo(let taskID, let projectID):
            guard let task = appState.tasks.first(where: { $0.id == taskID }) else { return false }
            move(task, toProject: projectID)
        case .scheduleTodo(let taskID, let when):
            guard let task = appState.tasks.first(where: { $0.id == taskID }) else { return false }
            applyWhen(task, when)
        case .reparentProject(let projectID, let parentID):
            moveProject(projectID, toParent: parentID)
        }
        return true
    }

    // MARK: - Sidebar folding

    func toggleCollapsed(_ projectID: Int64) {
        if collapsedProjectIDs.contains(projectID) {
            collapsedProjectIDs.remove(projectID)
        } else {
            collapsedProjectIDs.insert(projectID)
        }
    }

    func setAllCollapsed(_ collapsed: Bool) {
        collapsedProjectIDs = collapsed ? Set(projectTree.expandableIDs) : []
    }

    func toggleTag(_ label: VLabel, on task: VTask) {
        let state = appState
        let id = task.id
        let wasOn = state.hasLabel(label, on: task)
        Task { @MainActor in
            let stuck = await state.toggleLabel(label, on: task)
            if stuck { self.recordTagChange(label, wasOn: wasOn, taskID: id) }
        }
    }

    /// Creates the tag when it does not exist, then puts it on the to-do.
    func addTag(named title: String, to task: VTask) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        let state = appState
        let id = task.id
        Task { @MainActor in
            var label = state.labels.first { $0.title.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
            if label == nil {
                label = await state.createLabel(title: trimmed)
            }
            if let label = label, !state.hasLabel(label, on: task) {
                let stuck = await state.toggleLabel(label, on: task)
                if stuck { self.recordTagChange(label, wasOn: false, taskID: id) }
            }
        }
    }

    private func recordTagChange(_ label: VLabel, wasOn: Bool, taskID: Int64) {
        recordUndo(
            String(localized: "Change Tags"),
            key: "tags.\(taskID).\(label.id)",
            undo: { [weak self] in await self?.setTag(label, present: wasOn, taskID: taskID) },
            redo: { [weak self] in await self?.setTag(label, present: !wasOn, taskID: taskID) }
        )
    }

    // MARK: - Quick Find

    /// Opens a Quick Find result. A tag has no screen of its own, the Quick Find view keeps it as the query.
    func open(_ target: ThingsQuickFindTarget) {
        switch target {
        case .list(let list):
            navigate(to: .list(list))
        case .project(let id), .area(let id):
            navigate(to: .project(id))
        case .todo(let id):
            guard let task = appState.tasks.first(where: { $0.id == id }) else { return }
            let destination = ThingsQuickFindEngine.route(
                for: task, inboxProjectID: appState.defaultProject?.id, now: Date(), calendar: Calendar.current
            )
            navigate(to: destination)
            selectedTaskID = id
        case .tag:
            break
        }
    }
}

#endif
