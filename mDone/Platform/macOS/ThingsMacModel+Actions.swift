import SwiftUI

#if os(macOS)

/// What the menu commands, the keyboard and the card do to to-dos. Each action
/// goes through an existing `AppState` mutator or `ThingsListViewModel` method.
extension ThingsMacModel {
    // MARK: - Create

    /// New To-Do (Cmd N): opens the empty row of the list on screen. The
    /// Logbook cannot take a to-do, so the Inbox opens instead.
    func newTodo() {
        if case .list(let list) = route, !list.allowsQuickAdd {
            navigate(to: .list(.inbox))
        }
        isAddingTodo = true
    }

    /// Called by the empty row with the trimmed title (empty when the user gave up).
    func finishAdding(title: String) {
        isAddingTodo = false
        if title.isEmpty { return }
        let target = route
        let listModel = activeViewModel
        Task { @MainActor in
            var created: VTask?
            switch target {
            case .list:
                created = await listModel.quickAdd(title: title)
            case .project(let projectID):
                created = await listModel.quickAdd(title: title, inProject: projectID)
            }
            if let created = created { self.selectedTaskID = created.id }
        }
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
        }
    }

    // MARK: - Complete, cancel, delete

    /// Complete (Cmd K): same delayed tick as a click on the box.
    func completeSelected() {
        guard let task = selectedTask else { return }
        activeViewModel.tapCheckbox(task)
    }

    /// Cancel (Opt Cmd K): the reserved cancelled label, then done (07 mapping).
    func cancelSelected() {
        guard let task = selectedTask, !task.done else { return }
        let state = appState
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
        }
    }

    func requestDeleteSelected() {
        pendingDeletion = selectedTask
    }

    func confirmDeletion(_ task: VTask) {
        pendingDeletion = nil
        selectedTaskID = nil
        collapseEditor()
        let listModel = activeViewModel
        Task { @MainActor in
            await listModel.delete(task)
        }
    }

    // MARK: - Dates

    func schedule(_ when: ThingsWhen) {
        guard let task = selectedTask else { return }
        let listModel = activeViewModel
        Task { @MainActor in
            await listModel.schedule(task, when: when)
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

    /// Sets the deadline, or clears it when `date` is nil.
    func setDeadline(_ date: Date?, for task: VTask) {
        let state = appState
        Task { @MainActor in
            if let date = date {
                await state.updateTask(id: task.id, request: TaskUpdateRequest(dueDate: date))
            } else {
                await state.updateTask(id: task.id, request: TaskUpdateRequest(clearDueDate: true))
            }
        }
    }

    // MARK: - Move and tags

    /// Moves a to-do to a project, an Area or the Inbox project.
    func move(_ task: VTask, toProject projectID: Int64) {
        let state = appState
        Task { @MainActor in
            await state.updateTask(id: task.id, request: TaskUpdateRequest(projectId: projectID))
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
        let state = appState
        Task { @MainActor in
            await state.moveProject(project, toParentId: parentID)
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
            schedule(task, when: when)
        case .reparentProject(let projectID, let parentID):
            moveProject(projectID, toParent: parentID)
        }
        return true
    }

    private func schedule(_ task: VTask, when: ThingsWhen) {
        let listModel = activeViewModel
        Task { @MainActor in
            await listModel.schedule(task, when: when)
        }
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
        Task { @MainActor in
            await state.toggleLabel(label, on: task)
        }
    }

    /// Creates the tag when it does not exist, then puts it on the to-do.
    func addTag(named title: String, to task: VTask) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        let state = appState
        Task { @MainActor in
            var label = state.labels.first { $0.title.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
            if label == nil {
                label = await state.createLabel(title: trimmed)
            }
            if let label = label, !state.hasLabel(label, on: task) {
                await state.toggleLabel(label, on: task)
            }
        }
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
