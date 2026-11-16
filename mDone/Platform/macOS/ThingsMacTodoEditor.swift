import SwiftUI

#if os(macOS)

/// The to-do opened in place of its row (spec 04 section 3, mac-dark-02.png):
/// a rounded card with the checkbox and title, a "Notes" area, the optional
/// checklist and tags, and a bottom line with the When button on the left and the
/// tag, checklist and deadline icons on the right. Under the card, right aligned, a
/// breadcrumb names the project and opens it. The When, Deadline, Tags and Move
/// popovers hang on the buttons. It is written fresh rather than reusing
/// `TaskDetailSheet`, which is a form; both save through `AppState.updateTask`. Notes
/// are edited as the raw stored text, Markdown rendering is a TODO
/// (docs/things-spec/DEVIATIONS.md). Move, Duplicate and Delete are in the card's
/// context menu, as the capture has no "more" button.
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

    /// Left edge of the title text inside the card, after the checkbox.
    private var contentLeading: CGFloat {
        ThingsMetrics.Checkbox.size + ThingsMetrics.Row.checkboxTitleSpacing
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: ThingsMetrics.Card.breadcrumbGap) {
            card
            breadcrumb
        }
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

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow
                .padding(.top, ThingsMetrics.Card.topPadding)
            notesField
                .padding(.top, ThingsMetrics.Card.titleNotesGap)
            checklistSection
            tagsRow
            actionBar
        }
        .padding(.horizontal, ThingsMetrics.Card.innerPadding)
        .padding(.bottom, ThingsMetrics.Card.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ThingsMetrics.Card.cornerRadius, style: .continuous)
                .fill(palette[.bgExpandedTodo])
                .shadow(
                    color: palette.cardShadowColor,
                    radius: ThingsMetrics.Card.shadowRadius,
                    x: 0,
                    y: ThingsMetrics.Card.shadowOffsetY
                )
        )
        .contextMenu {
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
        }
        .popover(isPresented: $showMove) {
            ThingsMacMovePopover(task: task, model: model, onClose: { showMove = false })
        }
    }

    // MARK: - Fields

    private var titleRow: some View {
        let pending = model.activeViewModel.pendingDoneIDs.contains(task.id)
        return HStack(alignment: .center, spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            ThingsCheckbox(
                state: ThingsRowMapper.checkboxState(for: task, isPendingDone: pending),
                action: { model.activeViewModel.tapCheckbox(task) },
                isDashed: task.hasThingsSomedayLabel
            )
            TextField(String(localized: "New To-Do"), text: $title)
                .textFieldStyle(.plain)
                .font(ThingsTypography.todoTitle)
                .foregroundStyle(palette[.textPrimary])
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
                    .padding(.top, 4)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $notes)
                .font(ThingsTypography.notes)
                .foregroundStyle(palette[.textPrimary])
                .scrollContentBackground(.hidden)
                .focused($focused, equals: .notes)
                .frame(minHeight: ThingsMetrics.Card.notesMinHeight, maxHeight: 220)
        }
        // The text editor insets its text by about 5 pt.
        .padding(.leading, contentLeading - 5)
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
            .padding(.top, ThingsMetrics.Spacing.xs)
            .padding(.leading, contentLeading)
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
            .padding(.top, ThingsMetrics.Spacing.s)
            .padding(.leading, contentLeading)
        }
    }

    // MARK: - Bottom line

    private var whenValue: ThingsWhen {
        ThingsWhen.resolve(task: task, now: Date(), calendar: Calendar.current)
    }

    private var whenText: String? {
        switch whenValue {
        case .today: return String(localized: "Today")
        case .thisEvening: return String(localized: "This Evening")
        case .someday: return String(localized: "Someday")
        case .date(let day): return day.formatted(date: .abbreviated, time: .omitted)
        case .none: return nil
        }
    }

    private var whenSymbol: String {
        switch whenValue {
        case .today: return ThingsIcons.today
        case .thisEvening: return ThingsIcons.evening
        case .someday: return ThingsIcons.someday
        case .date, .none: return ThingsIcons.when
        }
    }

    private var whenTint: ThingsColorToken {
        switch whenValue {
        case .today: return .todayStar
        case .thisEvening: return .eveningMoon
        case .someday: return .somedayTan
        case .date, .none: return .textPlaceholder
        }
    }

    private var deadlineText: String? {
        guard let due = task.effectiveDueDate else { return nil }
        return due.formatted(date: .abbreviated, time: .omitted)
    }

    private var actionBar: some View {
        HStack(spacing: ThingsMetrics.Spacing.m) {
            whenButton
                .popover(isPresented: $showWhen) {
                    ThingsMacWhenPopover(task: task, model: model, onClose: { showWhen = false })
                }
            if let deadline = deadlineText {
                deadlineButton(label: deadline)
                    .popover(isPresented: $showDeadline) {
                        ThingsMacDeadlinePopover(task: task, model: model, onClose: { showDeadline = false })
                    }
            }
            Spacer(minLength: 0)
            HStack(spacing: ThingsMetrics.Card.toolbarIconPitch - 24) {
                iconButton(ThingsIcons.tag, help: String(localized: "Tags")) { showTags = true }
                    .popover(isPresented: $showTags) { ThingsMacTagsPopover(task: task, model: model) }
                iconButton(ThingsIcons.checklist, help: String(localized: "Checklist")) {
                    showChecklist = true
                    focused = .checklist
                }
                if deadlineText == nil {
                    iconButton(ThingsIcons.deadlineFlag, help: String(localized: "Deadline")) { showDeadline = true }
                        .popover(isPresented: $showDeadline) {
                            ThingsMacDeadlinePopover(task: task, model: model, onClose: { showDeadline = false })
                        }
                }
            }
            .padding(.trailing, ThingsMetrics.Card.toolbarTrailingPadding - ThingsMetrics.Card.innerPadding - 5.5)
        }
        .padding(.leading, contentLeading)
        .padding(.top, ThingsMetrics.Spacing.s)
        .frame(minHeight: 24)
    }

    private var whenButton: some View {
        Button {
            showWhen = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: whenSymbol)
                    .font(.system(size: 12))
                    .foregroundStyle(palette[whenTint])
                if let text = whenText {
                    Text(verbatim: text)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(palette[.textPrimary])
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(String(localized: "When"))
    }

    private func deadlineButton(label: String) -> some View {
        Button {
            showDeadline = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: ThingsIcons.deadlineFlag)
                    .font(.system(size: 11))
                    .foregroundStyle(palette[.deadlineFlame])
                Text(verbatim: label)
                    .font(.system(size: 12))
                    .foregroundStyle(palette[.textSecondary])
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(String(localized: "Deadline"))
    }

    private func iconButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: ThingsMetrics.Card.toolbarIconSize))
                .foregroundStyle(palette[.textPlaceholder])
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Breadcrumb

    private var projectForBreadcrumb: Project? {
        if task.projectId == model.appState.defaultProject?.id { return nil }
        if case .project(let current) = model.route, current == task.projectId { return nil }
        return model.appState.projects.first { $0.id == task.projectId }
    }

    @ViewBuilder
    private var breadcrumb: some View {
        if let project = projectForBreadcrumb {
            Button {
                model.navigate(to: .project(project.id))
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: ThingsIcons.area)
                        .font(.system(size: 11))
                    Text(verbatim: project.title)
                        .font(ThingsTypography.breadcrumb)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(palette[.textSecondary])
                .frame(height: ThingsMetrics.Card.breadcrumbHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, ThingsMetrics.Card.breadcrumbTrailingInset)
            .help(String(localized: "Show in parent list"))
        }
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
