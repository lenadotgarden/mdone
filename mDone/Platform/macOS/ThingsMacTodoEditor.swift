import SwiftUI

#if os(macOS)

/// The to-do opened in place of its row (spec 04 section 3): title, notes,
/// checklist, tags and the action bar with the When, Deadline, Tags and Move
/// popovers. It is written fresh rather than reusing `TaskDetailSheet`, which is
/// a form; both save through `AppState.updateTask`. Notes are edited as the raw
/// stored text, Markdown rendering is a TODO (docs/things-spec/DEVIATIONS.md).
struct ThingsMacTodoEditor: View {
    let task: VTask
    let model: ThingsMacModel

    @State private var title: String
    @State private var notes: String
    @State private var checklistTitle = ""
    @State private var showChecklist = false
    @State private var showWhen = false
    @State private var showDeadline = false
    @State private var showTags = false
    @State private var showMove = false
    @FocusState private var focused: Field?
    @Environment(\.colorScheme) private var scheme

    enum Field: Hashable {
        case title, notes, checklist
    }

    init(task: VTask, model: ThingsMacModel) {
        self.task = task
        self.model = model
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.userVisibleDescription ?? "")
    }

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.s) {
            titleRow
            notesField
            checklistSection
            tagsRow
            actionBar
        }
        .padding(ThingsMetrics.Card.innerPadding)
        .background(
            RoundedRectangle(cornerRadius: ThingsMetrics.Card.cornerRadius, style: .continuous)
                .fill(palette[.bgExpandedTodo])
                .shadow(
                    color: Color.black.opacity(ThingsColorOpacity.cardShadow),
                    radius: ThingsMetrics.Card.shadowRadius,
                    x: 0,
                    y: ThingsMetrics.Card.shadowOffsetY
                )
        )
        .onAppear { focused = .title }
        .onExitCommand {
            commit()
            model.collapseEditor()
        }
        .onDisappear { commit() }
        .onChange(of: model.commitRequest) { _, _ in
            commit()
            model.collapseEditor()
        }
        .onChange(of: model.pendingPopover, initial: true) { _, popover in consume(popover) }
        .onChange(of: model.editorFocusRequest, initial: true) { _, field in
            if field == .checklist {
                model.editorFocusRequest = nil
                showChecklist = true
                focused = .checklist
            }
        }
    }

    // MARK: - Fields

    private var titleRow: some View {
        let pending = model.activeViewModel.pendingDoneIDs.contains(task.id)
        return HStack(alignment: .top, spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            ThingsCheckbox(
                state: ThingsRowMapper.checkboxState(for: task, isPendingDone: pending),
                action: { model.activeViewModel.tapCheckbox(task) }
            )
            TextField(String(localized: "New To-Do"), text: $title)
                .textFieldStyle(.plain)
                .font(ThingsTypography.todoTitle)
                .focused($focused, equals: .title)
                .onSubmit { focused = .notes }
        }
    }

    private var notesField: some View {
        ZStack(alignment: .topLeading) {
            if notes.isEmpty {
                Text(String(localized: "Notes"))
                    .font(ThingsTypography.notes)
                    .foregroundStyle(palette[.textPlaceholder])
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $notes)
                .font(ThingsTypography.notes)
                .scrollContentBackground(.hidden)
                .focused($focused, equals: .notes)
                .frame(minHeight: 44, maxHeight: 160)
        }
        .padding(.leading, ThingsMetrics.Checkbox.size + ThingsMetrics.Row.checkboxTitleSpacing)
    }

    @ViewBuilder
    private var checklistSection: some View {
        let items = ThingsChecklist.items(of: task)
        if !items.isEmpty || showChecklist {
            VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.xs) {
                ForEach(items) { item in
                    HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                        ThingsCheckbox(
                            state: item.done ? .done : .open,
                            size: ThingsMetrics.Checkbox.checklistItemSize,
                            action: { toggle(item) }
                        )
                        Text(verbatim: item.title)
                            .font(ThingsTypography.todoTitle)
                            .strikethrough(item.done)
                            .foregroundStyle(item.done ? palette[.textSecondary] : palette[.textPrimary])
                        Spacer(minLength: 0)
                    }
                }
                TextField(String(localized: "Add checklist item"), text: $checklistTitle)
                    .textFieldStyle(.plain)
                    .font(ThingsTypography.todoTitle)
                    .focused($focused, equals: .checklist)
                    .onSubmit { addChecklistItem() }
            }
            .padding(.leading, ThingsMetrics.Checkbox.size + ThingsMetrics.Row.checkboxTitleSpacing)
        }
    }

    @ViewBuilder
    private var tagsRow: some View {
        let tags = ThingsRowMapper.tags(for: task)
        if !tags.isEmpty {
            HStack(spacing: ThingsMetrics.Spacing.xs) {
                ForEach(Array(tags.enumerated()), id: \.offset) { entry in
                    ThingsTagChip(title: entry.element)
                }
                Spacer(minLength: 0)
            }
            .padding(.leading, ThingsMetrics.Checkbox.size + ThingsMetrics.Row.checkboxTitleSpacing)
        }
    }

    // MARK: - Action bar

    private var whenLabel: String {
        switch ThingsWhen.resolve(task: task, now: Date(), calendar: Calendar.current) {
        case .today: return String(localized: "Today")
        case .thisEvening: return String(localized: "This Evening")
        case .someday: return String(localized: "Someday")
        case .date(let day): return day.formatted(date: .abbreviated, time: .omitted)
        case .none: return String(localized: "When")
        }
    }

    private var deadlineLabel: String {
        guard let due = task.effectiveDueDate else { return String(localized: "Deadline") }
        return due.formatted(date: .abbreviated, time: .omitted)
    }

    private var actionBar: some View {
        HStack(spacing: ThingsMetrics.Spacing.m) {
            barButton(ThingsIcons.tag, String(localized: "Tags")) { showTags = true }
                .popover(isPresented: $showTags) { ThingsMacTagsPopover(task: task, model: model) }
            barButton(ThingsIcons.checklist, String(localized: "Checklist")) {
                showChecklist = true
                focused = .checklist
            }
            barButton(ThingsIcons.when, whenLabel) { showWhen = true }
                .popover(isPresented: $showWhen) {
                    ThingsMacWhenPopover(task: task, model: model, onClose: { showWhen = false })
                }
            barButton(ThingsIcons.deadlineFlag, deadlineLabel) { showDeadline = true }
                .popover(isPresented: $showDeadline) {
                    ThingsMacDeadlinePopover(task: task, model: model, onClose: { showDeadline = false })
                }
            Spacer(minLength: 0)
            moreMenu
        }
        .padding(.top, ThingsMetrics.Spacing.xs)
    }

    private var moreMenu: some View {
        Menu {
            Button(String(localized: "Move...")) { showMove = true }
            Button(String(localized: "Duplicate")) {
                model.select(task.id)
                model.duplicateSelected()
            }
            Divider()
            Button(String(localized: "Delete"), role: .destructive) {
                model.select(task.id)
                model.requestDeleteSelected()
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .popover(isPresented: $showMove) {
            ThingsMacMovePopover(task: task, model: model, onClose: { showMove = false })
        }
    }

    private func barButton(_ symbol: String, _ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(text, systemImage: symbol)
                .font(ThingsTypography.deadline)
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette[.textSecondary])
    }

    // MARK: - Behavior

    private func consume(_ popover: ThingsMacPopover?) {
        guard let popover = popover else { return }
        model.pendingPopover = nil
        switch popover {
        case .when: showWhen = true
        case .deadline: showDeadline = true
        case .tags: showTags = true
        case .move: showMove = true
        }
    }

    private func toggle(_ item: VTask) {
        let state = model.appState
        Task { @MainActor in
            await state.toggleTaskDone(item)
        }
    }

    private func addChecklistItem() {
        let text = checklistTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        checklistTitle = ""
        if text.isEmpty { return }
        let state = model.appState
        let parent = task
        Task { @MainActor in
            _ = await state.createSubtask(title: text, parent: parent)
        }
        focused = .checklist
    }

    /// Saves the title and the notes when they changed. The estimate marker of
    /// the description is kept, as `TaskDetailSheet` does.
    private func commit() {
        let state = model.appState
        let id = task.id
        if !state.tasks.contains(where: { $0.id == id }) { return }
        var request = TaskUpdateRequest()
        var changed = false
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != task.title {
            request.title = trimmed
            changed = true
        }
        if notes != (task.userVisibleDescription ?? "") {
            let body: String? = notes.isEmpty ? nil : notes
            request.description = EstimateMarker.apply(task.estimatedSeconds, to: body) ?? ""
            changed = true
        }
        if !changed { return }
        Task { @MainActor in
            await state.updateTask(id: id, request: request)
        }
    }
}

#endif
