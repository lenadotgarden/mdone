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

    /// Handles a drop on a sidebar row. `targetProjectID` is the project or
    /// Area under the pointer. Returns whether the drop was accepted.
    @discardableResult
    func handleDrop(_ payloads: [String], onProject targetProjectID: Int64) -> Bool {
        guard let first = payloads.compactMap({ ThingsDragPayload(encoded: $0) }).first else { return false }
        switch first {
        case .todo(let taskID):
            guard let task = appState.tasks.first(where: { $0.id == taskID }) else { return false }
            if task.projectId == targetProjectID { return false }
            move(task, toProject: targetProjectID)
            return true
        case .project(let projectID):
            if !projectTree.canMove(projectID: projectID, toParent: targetProjectID) { return false }
            moveProject(projectID, toParent: targetProjectID)
            return true
        }
    }

    /// Handles a drop of a to-do on a built-in list row: Inbox moves it to the
    /// Inbox project, Today and Someday schedule it. Other lists refuse.
    @discardableResult
    func handleDrop(_ payloads: [String], onList list: ThingsList) -> Bool {
        guard let first = payloads.compactMap({ ThingsDragPayload(encoded: $0) }).first else { return false }
        guard case .todo(let taskID) = first,
              let task = appState.tasks.first(where: { $0.id == taskID }) else { return false }
        switch list {
        case .inbox:
            guard let inbox = appState.defaultProject, task.projectId != inbox.id else { return false }
            move(task, toProject: inbox.id)
            return true
        case .today:
            schedule(task, when: .today)
            return true
        case .someday:
            schedule(task, when: .someday)
            return true
        default:
            return false
        }
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
