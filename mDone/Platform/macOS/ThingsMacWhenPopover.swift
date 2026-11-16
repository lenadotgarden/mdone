import SwiftUI

#if os(macOS)

/// Arrow keys of the date popovers: move the day the keyboard sits on. They only apply while
/// the header field is empty, so once the user types a date the arrows move the caret again.
struct ThingsDateArrowKeys: ViewModifier {
    let isEnabled: Bool
    let move: (ThingsCalendarMonth.Direction) -> Void

    func body(content: Content) -> some View {
        content
            .onKeyPress(.leftArrow) { handle(.left) }
            .onKeyPress(.rightArrow) { handle(.right) }
            .onKeyPress(.upArrow) { handle(.up) }
            .onKeyPress(.downArrow) { handle(.down) }
    }

    private func handle(_ direction: ThingsCalendarMonth.Direction) -> KeyPress.Result {
        if !isEnabled { return .ignored }
        move(direction)
        return .handled
    }
}

extension View {
    func thingsDateArrowKeys(
        isEnabled: Bool,
        move: @escaping (ThingsCalendarMonth.Direction) -> Void
    ) -> some View {
        modifier(ThingsDateArrowKeys(isEnabled: isEnabled, move: move))
    }
}

/// One row of the When popover: icon, title, a checkmark when it is the current value.
private struct ThingsDatePopoverRow: View {
    let symbol: String
    let tint: ThingsColorToken
    let title: String
    var isChecked: Bool = false
    let action: () -> Void

    @State private var isHovering = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        return Button(action: action) {
            HStack(spacing: ThingsMetrics.Spacing.s) {
                Image(systemName: symbol)
                    .font(.system(size: ThingsMetrics.Row.indicatorIconSize + 2))
                    .foregroundStyle(palette[tint])
                    .frame(width: ThingsMetrics.DatePopover.rowIconWidth)
                Text(verbatim: title)
                    .font(ThingsTypography.popoverRow)
                    .foregroundStyle(palette[.textPrimary])
                Spacer(minLength: 0)
                if isChecked {
                    Image(systemName: ThingsIcons.checkmark)
                        .font(.system(size: ThingsMetrics.Row.indicatorIconSize, weight: .semibold))
                        .foregroundStyle(palette[.textPrimary])
                }
            }
            .padding(.horizontal, ThingsMetrics.Spacing.s)
            .frame(height: ThingsMetrics.DatePopover.rowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ThingsMetrics.DatePopover.rowCornerRadius, style: .continuous)
                    .fill(isHovering ? palette[.selectionRow] : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isChecked ? .isSelected : [])
    }
}

/// The full width Clear button at the bottom of the When and Deadline popovers.
struct ThingsDatePopoverClearButton: View {
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        return Button(action: action) {
            Text(String(localized: "Clear"))
                .font(ThingsTypography.popoverRow)
                .foregroundStyle(palette[.textPrimary])
                .frame(maxWidth: .infinity)
                .frame(height: ThingsMetrics.DatePopover.clearButtonHeight)
                .background(
                    RoundedRectangle(cornerRadius: ThingsMetrics.DatePopover.rowCornerRadius, style: .continuous)
                        .fill(palette[.bgCalendarBox])
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// The When popover (Cmd S, spec 04 section 4, 05 "Dates"): the header "When" that turns
/// into a text field as soon as the user types a date or a word such as "tomorrow", then
/// Today and This Evening, a month calendar (Monday first, today marked with a star),
/// Someday, Add Reminder and a Clear button. Arrows move over the grid, Return picks,
/// Esc closes.
struct ThingsMacWhenPopover: View {
    let task: VTask
    let model: ThingsMacModel
    let onClose: () -> Void

    @State private var typed = ""
    @State private var month: Date
    @State private var focusDay: Date
    @State private var showReminder = false
    @State private var reminderTime: Date
    @FocusState private var fieldFocused: Bool
    @Environment(\.colorScheme) private var scheme

    init(task: VTask, model: ThingsMacModel, onClose: @escaping () -> Void) {
        self.task = task
        self.model = model
        self.onClose = onClose
        let calendar = Calendar.current
        let start = task.effectiveStartDate.map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: Date())
        _month = State(initialValue: start)
        _focusDay = State(initialValue: start)
        let existing = task.reminders?.compactMap { $0.reminder }.first
        let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        _reminderTime = State(initialValue: existing ?? defaultTime)
    }

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    private var live: VTask {
        model.appState.tasks.first(where: { $0.id == task.id }) ?? task
    }

    private var current: ThingsWhen {
        ThingsWhen.resolve(task: live, now: Date(), calendar: Calendar.current)
    }

    private var selectedDay: Date? {
        if case .date(let day) = current { return day }
        return nil
    }

    private var typedTrimmed: String {
        typed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var existingReminder: Date? {
        live.reminders?.compactMap { $0.reminder }.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.xs) {
            header
            ThingsDatePopoverRow(
                symbol: ThingsIcons.today,
                tint: .todayStar,
                title: String(localized: "Today"),
                isChecked: current == .today,
                action: { apply(.today) }
            )
            ThingsDatePopoverRow(
                symbol: ThingsIcons.evening,
                tint: .eveningMoon,
                title: String(localized: "This Evening"),
                isChecked: current == .thisEvening,
                action: { apply(.thisEvening) }
            )
            ThingsCalendarGrid(
                month: $month,
                selected: selectedDay,
                focused: typed.isEmpty ? focusDay : nil,
                todayStyle: .star,
                onPick: { pick($0) }
            )
            .padding(.vertical, ThingsMetrics.Spacing.xs)
            ThingsDatePopoverRow(
                symbol: ThingsIcons.someday,
                tint: .somedayTan,
                title: String(localized: "Someday"),
                isChecked: current == .someday,
                action: { apply(.someday) }
            )
            reminderRow
            ThingsDatePopoverClearButton { apply(ThingsWhen.none) }
                .padding(.top, ThingsMetrics.Spacing.xs)
        }
        .padding(ThingsMetrics.DatePopover.padding)
        .frame(width: ThingsMetrics.DatePopover.width)
        .onAppear { fieldFocused = true }
        .onExitCommand { onClose() }
        .onChange(of: focusDay) { _, day in
            if !ThingsCalendarMonth.sameMonth(day, month, calendar: Calendar.current) { month = day }
        }
    }

    // MARK: - Header

    /// "When" until the user types; then the typed text and, under it, what it reads as.
    private var header: some View {
        VStack(spacing: ThingsMetrics.Spacing.xxs) {
            ZStack {
                if typed.isEmpty {
                    Text(String(localized: "When"))
                        .font(ThingsTypography.popoverTitle)
                        .foregroundStyle(palette[.textPrimary])
                        .allowsHitTesting(false)
                }
                TextField(text: $typed, label: { EmptyView() })
                    .textFieldStyle(.plain)
                    .font(ThingsTypography.popoverTitle)
                    .multilineTextAlignment(.center)
                    .focused($fieldFocused)
                    .onSubmit { submit() }
                    .thingsDateArrowKeys(isEnabled: typed.isEmpty) { direction in
                        focusDay = ThingsCalendarMonth.moveFocus(focusDay, direction, calendar: Calendar.current)
                    }
                    .accessibilityLabel(Text(String(localized: "When")))
            }
            .frame(height: ThingsMetrics.DatePopover.rowHeight)
            if !typedTrimmed.isEmpty, let when = ThingsWhenInput.parseWhen(typedTrimmed) {
                Text(verbatim: readable(when))
                    .font(ThingsTypography.projectLine)
                    .foregroundStyle(palette[.textSecondary])
            }
        }
    }

    private func readable(_ when: ThingsWhen) -> String {
        switch when {
        case .today: return String(localized: "Today")
        case .thisEvening: return String(localized: "This Evening")
        case .someday: return String(localized: "Someday")
        case .date(let day): return day.formatted(date: .complete, time: .omitted)
        case .none: return String(localized: "Anytime")
        }
    }

    // MARK: - Reminder

    @ViewBuilder
    private var reminderRow: some View {
        let title = existingReminder.map { $0.formatted(date: .omitted, time: .shortened) }
            ?? String(localized: "Add Reminder")
        ThingsDatePopoverRow(
            symbol: existingReminder == nil ? ThingsIcons.add : ThingsIcons.reminder,
            tint: .textSecondary,
            title: title,
            action: { showReminder.toggle() }
        )
        if showReminder {
            HStack(spacing: ThingsMetrics.Spacing.s) {
                DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                Spacer(minLength: 0)
                if existingReminder != nil {
                    Button(String(localized: "Remove")) { saveReminder(nil) }
                }
                Button(String(localized: "Set")) { saveReminder(reminderTime) }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, ThingsMetrics.Spacing.s)
        }
    }

    private func saveReminder(_ time: Date?) {
        model.setReminder(time, for: live)
        showReminder = false
        if time != nil { onClose() }
    }

    // MARK: - Picking

    /// A typed date or word. Nothing typed picks the day the keyboard sits on.
    private func submit() {
        if typedTrimmed.isEmpty {
            pick(focusDay)
            return
        }
        if let when = ThingsWhenInput.parseWhen(typedTrimmed) {
            apply(when)
        }
    }

    /// A day of the grid: today or earlier is Today, later is a start date.
    private func pick(_ day: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        if start <= calendar.startOfDay(for: Date()) {
            apply(.today)
        } else {
            apply(.date(start))
        }
    }

    private func apply(_ when: ThingsWhen) {
        model.applyWhen(live, when)
        onClose()
    }
}

extension ThingsMacModel {
    /// Sets the reminder of a to-do at `time` (its clock time on the day of its When,
    /// today when it has none), or removes it. A to-do with a reminder always has a When
    /// (spec 07 section 6), so a to-do without one gets Today.
    func setReminder(_ time: Date?, for task: VTask) {
        let state = appState
        let live = state.tasks.first(where: { $0.id == task.id }) ?? task
        let id = live.id
        let calendar = Calendar.current
        let before = live.reminders ?? []
        var reminders: [TaskReminder] = []
        if let time = time {
            let day = ThingsWhen.validDate(live.startDate, calendar: calendar).map { calendar.startOfDay(for: $0) }
                ?? calendar.startOfDay(for: Date())
            let parts = calendar.dateComponents([.hour, .minute], from: time)
            let fire = calendar.date(
                bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0, second: 0, of: day
            ) ?? time
            reminders = [TaskReminder(reminder: fire, relativePeriod: nil, relativeTo: nil)]
        }
        let needsWhen = time != nil
            && ThingsWhen.resolve(task: live, now: Date(), calendar: calendar) == ThingsWhen.none
        let wanted = reminders
        let listModel = activeViewModel
        Task { @MainActor in
            if needsWhen { await listModel.schedule(live, when: .today) }
            var request = TaskUpdateRequest()
            request.reminders = wanted
            await state.updateTask(id: id, request: request)
            self.recordUndo(
                String(localized: "Change Reminder"),
                key: "reminder.\(id)",
                undo: { [weak self] in await self?.writeReminders(id, before) },
                redo: { [weak self] in await self?.writeReminders(id, wanted) }
            )
        }
    }

    private func writeReminders(_ id: Int64, _ reminders: [TaskReminder]) async {
        let resolved = liveID(id)
        guard appState.tasks.contains(where: { $0.id == resolved }) else { return }
        var request = TaskUpdateRequest()
        request.reminders = reminders
        await appState.updateTask(id: resolved, request: request)
    }
}

#endif
