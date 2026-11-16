import SwiftUI

#if os(macOS)

/// The When popover (spec 04 section 4): Today, This Evening, Someday, a month
/// calendar and Clear. The natural language field and Add Reminder are TODOs.
struct ThingsMacWhenPopover: View {
    let task: VTask
    let model: ThingsMacModel
    let onClose: () -> Void

    @State private var date: Date

    init(task: VTask, model: ThingsMacModel, onClose: @escaping () -> Void) {
        self.task = task
        self.model = model
        self.onClose = onClose
        _date = State(initialValue: task.effectiveStartDate ?? Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.s) {
            choice(ThingsIcons.today, String(localized: "Today"), .today)
            choice(ThingsIcons.evening, String(localized: "This Evening"), .thisEvening)
            choice(ThingsIcons.someday, String(localized: "Someday"), .someday)
            Divider()
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
            HStack {
                Button(String(localized: "Clear")) { apply(ThingsWhen.none) }
                Spacer()
                Button(String(localized: "Set Date")) {
                    apply(.date(Calendar.current.startOfDay(for: date)))
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(ThingsMetrics.Spacing.m)
        .frame(width: 260)
    }

    private func choice(_ symbol: String, _ title: String, _ when: ThingsWhen) -> some View {
        Button {
            apply(when)
        } label: {
            Label(title, systemImage: symbol)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func apply(_ when: ThingsWhen) {
        let listModel = model.activeViewModel
        let target = task
        Task { @MainActor in
            await listModel.schedule(target, when: when)
        }
        onClose()
    }
}

/// The Deadline popover (spec 04 section 4): a month calendar and Clear.
struct ThingsMacDeadlinePopover: View {
    let task: VTask
    let model: ThingsMacModel
    let onClose: () -> Void

    @State private var date: Date

    init(task: VTask, model: ThingsMacModel, onClose: @escaping () -> Void) {
        self.task = task
        self.model = model
        self.onClose = onClose
        _date = State(initialValue: task.effectiveDueDate ?? Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.s) {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
            HStack {
                Button(String(localized: "Clear")) {
                    model.setDeadline(nil, for: task)
                    onClose()
                }
                Spacer()
                Button(String(localized: "Set Deadline")) {
                    model.setDeadline(ThingsWhen.noonLocal(date, calendar: Calendar.current), for: task)
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(ThingsMetrics.Spacing.m)
        .frame(width: 260)
    }
}

/// The Tags popover (spec 04 section 4): a search field and a check per tag.
struct ThingsMacTagsPopover: View {
    let task: VTask
    let model: ThingsMacModel

    @State private var query = ""

    private var tags: [VLabel] {
        let visible = model.appState.labels.filter { !ThingsReservedLabels.isReserved($0.title) }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return visible }
        return visible.filter { $0.title.localizedCaseInsensitiveContains(needle) }
    }

    private var canCreate: Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return false }
        return !model.appState.labels.contains { $0.title.localizedCaseInsensitiveCompare(needle) == .orderedSame }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.s) {
            TextField(String(localized: "Search or create a tag"), text: $query)
                .textFieldStyle(.roundedBorder)
                .onSubmit { create() }
            ScrollView {
                VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.xs) {
                    ForEach(tags) { label in
                        Button {
                            model.toggleTag(label, on: task)
                        } label: {
                            HStack {
                                Image(systemName: isOn(label) ? "checkmark.square.fill" : "square")
                                Text(verbatim: label.title)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    if canCreate {
                        Button(String(localized: "Create tag")) { create() }
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(ThingsMetrics.Spacing.m)
        .frame(width: 240)
    }

    private func isOn(_ label: VLabel) -> Bool {
        model.appState.hasLabel(label, on: task)
    }

    private func create() {
        if !canCreate { return }
        model.addTag(named: query, to: task)
        query = ""
    }
}

/// The Move popover for a to-do (Shift Cmd M, spec 04 section 4): a filter
/// field, then Inbox and the whole project tree. Targeting headings and
/// inactive projects is a TODO.
struct ThingsMacMovePopover: View {
    let task: VTask
    let model: ThingsMacModel
    let onClose: () -> Void

    var body: some View {
        ThingsMacMoveChooser(subject: .todo(task), model: model, onClose: onClose)
    }
}

/// The Move popover for a project or an Area selected in the sidebar: pick an
/// Area or project to put it under, or "No Area" for the top level.
struct ThingsMacProjectMovePopover: View {
    let project: Project
    let model: ThingsMacModel
    let onClose: () -> Void

    var body: some View {
        ThingsMacMoveChooser(subject: .project(project), model: model, onClose: onClose)
    }
}

/// Shared list of the two Move popovers: type to filter, Up and Down to
/// highlight, Return to choose, Esc to close. Indented by tree depth while
/// the filter is empty, with the parent path shown while filtering.
struct ThingsMacMoveChooser: View {
    enum Subject {
        case todo(VTask)
        case project(Project)
    }

    let subject: Subject
    let model: ThingsMacModel
    let onClose: () -> Void

    @State private var query = ""
    @State private var highlighted = 0
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var scheme

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    private var targets: [ThingsMoveTarget] {
        let tree = model.projectTree
        switch subject {
        case .todo:
            return ThingsMoveTargets.forTodo(tree: tree, inboxProject: model.appState.defaultProject, query: query)
        case .project(let project):
            return ThingsMoveTargets.forProject(tree: tree, projectID: project.id, query: query)
        }
    }

    /// The project id the subject currently sits in (nil = top level).
    private var currentProjectID: Int64? {
        switch subject {
        case .todo(let task):
            return task.projectId
        case .project(let project):
            return model.projectTree.node(id: project.id)?.parentID
        }
    }

    private var placeholder: String {
        switch subject {
        case .todo: return String(localized: "Move to...")
        case .project: return String(localized: "Move to Area or project...")
        }
    }

    var body: some View {
        let list = targets
        return VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.s) {
            TextField(placeholder, text: $query)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit { chooseHighlighted(in: list) }
                .onKeyPress(.upArrow) {
                    highlighted = ThingsMoveTargets.clampedIndex(highlighted - 1, count: list.count)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    highlighted = ThingsMoveTargets.clampedIndex(highlighted + 1, count: list.count)
                    return .handled
                }
            if list.isEmpty {
                Text(String(localized: "No results"))
                    .font(ThingsTypography.emptyMessage)
                    .foregroundStyle(palette[.textSecondary])
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                rows(list)
            }
        }
        .padding(ThingsMetrics.Spacing.m)
        .frame(width: 300)
        .onAppear { focused = true }
        .onChange(of: query) { _, _ in highlighted = 0 }
        .onExitCommand { onClose() }
    }

    private func rows(_ list: [ThingsMoveTarget]) -> some View {
        let isFiltering = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, target in
                        row(target, index: index, isFiltering: isFiltering)
                            .id(target.id)
                    }
                }
            }
            .frame(maxHeight: 280)
            .onChange(of: highlighted) { _, newValue in
                let index = ThingsMoveTargets.clampedIndex(newValue, count: list.count)
                if index < list.count { proxy.scrollTo(list[index].id) }
            }
        }
    }

    private func row(_ target: ThingsMoveTarget, index: Int, isFiltering: Bool) -> some View {
        let isCurrent = target.projectID == currentProjectID
        let indent = isFiltering ? 0 : CGFloat(max(target.depth - 1, 0)) * ThingsMetrics.Spacing.m
        return Button {
            choose(target)
        } label: {
            HStack(spacing: ThingsMetrics.Spacing.s) {
                Image(systemName: symbol(for: target))
                    .foregroundStyle(palette[tint(for: target)])
                    .frame(width: ThingsMetrics.Icon.list)
                Text(verbatim: title(for: target))
                    .font(target.kind == .area ? ThingsTypography.sidebarRow.weight(.semibold) : ThingsTypography.sidebarRow)
                    .lineLimit(1)
                if isFiltering && !target.path.isEmpty {
                    Text(verbatim: target.path)
                        .font(ThingsTypography.notes)
                        .foregroundStyle(palette[.textSecondary])
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if isCurrent {
                    Image(systemName: ThingsIcons.checkmark)
                        .foregroundStyle(palette[.textSecondary])
                }
            }
            .padding(.leading, indent)
            .padding(.horizontal, ThingsMetrics.Spacing.s)
            .padding(.vertical, ThingsMetrics.Spacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ThingsMetrics.Checkbox.cornerRadius)
                    .fill(index == highlighted ? palette[.selectionRow] : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func title(for target: ThingsMoveTarget) -> String {
        switch target.kind {
        case .inbox: return String(localized: "Inbox")
        case .topLevel: return String(localized: "No Area")
        case .area, .project: return target.title
        }
    }

    private func symbol(for target: ThingsMoveTarget) -> String {
        switch target.kind {
        case .inbox: return ThingsIcons.inbox
        case .topLevel: return "arrow.up.to.line"
        case .area: return ThingsIcons.area
        case .project: return ThingsIcons.project
        }
    }

    private func tint(for target: ThingsMoveTarget) -> ThingsColorToken {
        switch target.kind {
        case .inbox: return .accent
        case .topLevel, .area: return .areaGray
        case .project: return .accent
        }
    }

    private func chooseHighlighted(in list: [ThingsMoveTarget]) {
        if list.isEmpty { return }
        choose(list[ThingsMoveTargets.clampedIndex(highlighted, count: list.count)])
    }

    private func choose(_ target: ThingsMoveTarget) {
        switch subject {
        case .todo(let task):
            if let projectID = target.projectID { model.move(task, toProject: projectID) }
        case .project(let project):
            model.moveProject(project.id, toParent: target.projectID)
        }
        onClose()
    }
}

#endif
