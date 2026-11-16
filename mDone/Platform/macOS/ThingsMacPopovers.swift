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

/// The Move popover (Shift Cmd M, spec 04 section 4): search, then Inbox,
/// projects and Areas. Targeting headings and inactive projects is a TODO.
struct ThingsMacMovePopover: View {
    let task: VTask
    let model: ThingsMacModel
    let onClose: () -> Void

    @State private var query = ""

    private struct Target: Identifiable {
        let id: Int64
        let title: String
        let symbol: String
    }

    private var targets: [Target] {
        var result: [Target] = []
        if let inbox = model.appState.defaultProject {
            result.append(Target(id: inbox.id, title: String(localized: "Inbox"), symbol: ThingsIcons.inbox))
        }
        for project in model.home.looseProjects {
            result.append(Target(id: project.id, title: project.project.title, symbol: ThingsIcons.project))
        }
        for area in model.home.areas {
            result.append(Target(id: area.id, title: area.project.title, symbol: ThingsIcons.area))
            for child in area.children {
                result.append(Target(id: child.id, title: child.project.title, symbol: ThingsIcons.project))
            }
        }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return result }
        return result.filter { $0.title.localizedCaseInsensitiveContains(needle) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.s) {
            TextField(String(localized: "Move to..."), text: $query)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    if let first = targets.first { choose(first) }
                }
            ScrollView {
                VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.xs) {
                    ForEach(targets) { target in
                        Button {
                            choose(target)
                        } label: {
                            HStack {
                                Image(systemName: target.symbol)
                                Text(verbatim: target.title)
                                Spacer(minLength: 0)
                                if target.id == task.projectId {
                                    Image(systemName: ThingsIcons.checkmark)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 260)
        }
        .padding(ThingsMetrics.Spacing.m)
        .frame(width: 260)
    }

    private func choose(_ target: Target) {
        model.move(task, toProject: target.id)
        onClose()
    }
}

#endif
