import SwiftUI

#if os(macOS)
import AppKit

/// A section of the Mac list: an optional header and its rows.
struct ThingsMacSectionData: Identifiable {
    let id: String
    let header: ThingsSectionHeaderStyle?
    let rows: [ThingsDisplayRow]
    /// False for sections that must not be reordered (logged to-dos).
    var allowsReorder: Bool = true
}

/// Where the rows were laid out, read by the drag to find its drop slot. A class
/// held in `@State`, so updating it during scrolling does not redraw the list.
private final class ThingsRowFrameStore {
    var frames: [Int64: CGRect] = [:]
}

private struct ThingsRowFramesKey: PreferenceKey {
    static let defaultValue: [Int64: CGRect] = [:]

    static func reduce(value: inout [Int64: CGRect], nextValue: () -> [Int64: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// A row being dragged with the mouse.
private struct ThingsRowDrag: Equatable {
    let id: Int64
    let sectionID: String
    /// Index of the row in its section when the drag began.
    let fromIndex: Int
    /// Vertical distance the pointer travelled.
    var translation: CGFloat
    /// Index the row would land at (in the list without the dragged row).
    var targetIndex: Int
}

/// The scrolling list shared by the Mac list and project screens (spec 04
/// sections 1 to 3, 10, 11, 05 "Selectionner" and "Deplacer"):
///
/// - selection and keyboard: Up and Down move between rows across sections, Opt
///   jumps to the first or last, Return opens the card, Esc clears the
///   selection, Delete asks to delete, Space is swallowed;
/// - reordering: dragging a row lifts it (scale, shadow) while the others slide
///   apart to open the drop slot; Cmd Opt Up and Cmd Opt Down (also Cmd Up and
///   Cmd Down) swap the selected to-do with its neighbour with the same spring;
///   the order is saved through `ThingsReorder` and `AppState.moveTask`;
/// - the open card replaces its row, a context menu.
struct ThingsMacTodoList: View {
    let sections: [ThingsMacSectionData]
    let viewModel: ThingsListViewModel
    let model: ThingsMacModel
    let header: AnyView
    let empty: AnyView?
    let trailing: AnyView?

    @FocusState private var listFocused: Bool
    @State private var orderOverride: [String: [Int64]] = [:]
    @State private var inflight: [String: Int] = [:]
    @State private var drag: ThingsRowDrag?
    @State private var frameStore = ThingsRowFrameStore()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let spaceName = "thingsMacList"

    init(
        sections: [ThingsMacSectionData],
        viewModel: ThingsListViewModel,
        model: ThingsMacModel,
        header: AnyView,
        empty: AnyView?,
        trailing: AnyView?
    ) {
        self.sections = sections
        self.viewModel = viewModel
        self.model = model
        self.header = header
        self.empty = empty
        self.trailing = trailing
    }

    /// The sections with the order the user just gave them, until the server answers.
    private var shownSections: [ThingsMacSectionData] {
        sections.map { section in
            guard let order = orderOverride[section.id] else { return section }
            return ThingsMacSectionData(
                id: section.id,
                header: section.header,
                rows: ThingsReorder.ordered(section.rows, by: order),
                allowsReorder: section.allowsReorder
            )
        }
    }

    var body: some View {
        let palette = ThingsPalette(scheme)
        let shown = shownSections
        let ids = shown.flatMap { section in section.rows.map { $0.task.id } }
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    header
                    if model.isAddingTodo {
                        ThingsInlineAddRow { title in model.finishAdding(title: title) }
                    }
                    if ids.isEmpty && !model.isAddingTodo, let empty = empty {
                        empty
                    }
                    ForEach(shown) { section in
                        sectionView(section)
                    }
                    if let trailing = trailing {
                        trailing
                    }
                    Color.clear.frame(height: 48)
                }
                .coordinateSpace(name: ThingsMacTodoList.spaceName)
                .onPreferenceChange(ThingsRowFramesKey.self) { frames in
                    frameStore.frames = frames
                }
                .frame(maxWidth: ThingsMetrics.Layout.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.select(nil)
                            listFocused = true
                        }
                )
            }
            .background(palette[.bgPrimary])
            .focusable()
            .focused($listFocused)
            .focusEffectDisabled()
            .onKeyPress(phases: [.down, .repeat]) { press in handleKey(press, proxy: proxy) }
            .onChange(of: ids, initial: true) { _, newIDs in model.visibleTaskIDs = newIDs }
            .onChange(of: model.selectedTaskID) { _, newID in
                if let newID = newID {
                    withAnimation { proxy.scrollTo(newID) }
                }
            }
            .onChange(of: model.listFocusToken) { _, _ in listFocused = true }
            // Membership changes (a to-do leaves) use the removal animation. A reorder
            // keeps the same set of ids, so the spring of the move is not overridden.
            .animation(ThingsMotion.rowRemoval, value: Set(ids))
        }
    }

    // MARK: - Keyboard

    /// Arrow keys move the selection (also across sections), Opt arrow jumps to the
    /// ends, Cmd Opt arrow and Cmd arrow move the selected to-do, Return opens the card,
    /// Esc clears the selection, Delete asks to delete (spec 05). With a card open the keys
    /// belong to its text fields.
    private func handleKey(_ press: KeyPress, proxy: ScrollViewProxy) -> KeyPress.Result {
        if model.expandedTaskID != nil { return .ignored }
        let option = press.modifiers.contains(.option)
        let command = press.modifiers.contains(.command)
        let shift = press.modifiers.contains(.shift)
        let control = press.modifiers.contains(.control)
        if control { return .ignored }

        if press.key == .upArrow || press.key == .downArrow {
            let step = (press.key == .upArrow) ? -1 : 1
            if command {
                moveSelected(by: step, proxy: proxy)
                return .handled
            }
            if shift { return .ignored }
            if option {
                if step < 0 { model.selectFirst() } else { model.selectLast() }
            } else {
                model.moveSelection(by: step)
            }
            return .handled
        }
        if command { return .ignored }
        if press.key == .return && model.selectedTaskID != nil {
            model.openSelected()
            return .handled
        }
        if (press.key == .delete || press.key == .deleteForward) && model.selectedTaskID != nil {
            model.requestDeleteSelected()
            return .handled
        }
        if press.key == .escape && model.selectedTaskID != nil {
            model.select(nil)
            return .handled
        }
        if press.key == .space && !option {
            // Space (new to-do below the selection) is a TODO: swallow it instead of beeping.
            return .handled
        }
        return .ignored
    }

    // MARK: - Reordering

    /// Moves the selected to-do one place up or down inside its section, animated.
    private func moveSelected(by step: Int, proxy: ScrollViewProxy) {
        guard let id = model.selectedTaskID, model.expandedTaskID == nil, drag == nil else { return }
        for section in shownSections where section.allowsReorder {
            guard section.rows.contains(where: { $0.task.id == id }) else { continue }
            let tasks = section.rows.map { $0.task }
            guard let plan = ThingsReorder.plan(sectionID: section.id, tasks: tasks, movingID: id, by: step) else {
                return
            }
            apply(plan, animation: ThingsMotion.reorderSwap)
            withAnimation(ThingsMotion.resolved(ThingsMotion.reorderSwap, reduceMotion: reduceMotion)) {
                proxy.scrollTo(id)
            }
            return
        }
    }

    /// Shows the new order at once, then saves it. The shown order stays until the last
    /// request of the section has finished and the server order is back.
    private func apply(_ plan: ThingsReorderPlan, animation: Animation) {
        withAnimation(ThingsMotion.resolved(animation, reduceMotion: reduceMotion)) {
            orderOverride[plan.sectionID] = plan.reorderedIDs
            inflight[plan.sectionID, default: 0] += 1
            drag = nil
        }
        let listModel = viewModel
        let state = model.appState
        Task { @MainActor in
            _ = await listModel.commitReorder(plan, appState: state)
            finishReorder(sectionID: plan.sectionID)
        }
    }

    private func finishReorder(sectionID: String) {
        let remaining = (inflight[sectionID] ?? 1) - 1
        if remaining > 0 {
            inflight[sectionID] = remaining
            return
        }
        inflight[sectionID] = nil
        withAnimation(ThingsMotion.resolved(ThingsMotion.reorder, reduceMotion: reduceMotion)) {
            orderOverride[sectionID] = nil
        }
    }

    private func dragGesture(for row: ThingsDisplayRow, in section: ThingsMacSectionData) -> some Gesture {
        DragGesture(
            minimumDistance: ThingsMetrics.Reorder.minimumDistance,
            coordinateSpace: .named(ThingsMacTodoList.spaceName)
        )
        .onChanged { value in dragChanged(row, in: section, translation: value.translation.height) }
        .onEnded { value in dragEnded(row, in: section, translation: value.translation.height) }
    }

    private func dragChanged(_ row: ThingsDisplayRow, in section: ThingsMacSectionData, translation: CGFloat) {
        guard section.allowsReorder, model.expandedTaskID == nil else { return }
        let id = row.task.id
        guard let from = section.rows.firstIndex(where: { $0.task.id == id }) else { return }
        var state = drag ?? ThingsRowDrag(id: id, sectionID: section.id, fromIndex: from, translation: 0, targetIndex: from)
        if drag == nil {
            model.select(id)
            listFocused = true
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
        if state.id != id { return }
        state.translation = translation
        state.targetIndex = targetIndex(for: state, rows: section.rows)
        drag = state
    }

    private func dragEnded(_ row: ThingsDisplayRow, in section: ThingsMacSectionData, translation: CGFloat) {
        guard let current = drag, current.id == row.task.id else {
            drag = nil
            return
        }
        var state = current
        state.translation = translation
        state.targetIndex = targetIndex(for: state, rows: section.rows)
        let tasks = section.rows.map { $0.task }
        let destination = ThingsReorder.destinationOffset(from: state.fromIndex, finalIndex: state.targetIndex)
        if let plan = ThingsReorder.plan(sectionID: section.id, tasks: tasks, movingID: state.id, toOffset: destination) {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            apply(plan, animation: ThingsMotion.reorder)
        } else {
            withAnimation(ThingsMotion.resolved(ThingsMotion.reorder, reduceMotion: reduceMotion)) {
                drag = nil
            }
        }
    }

    /// The index the dragged row would land at: the number of other rows whose
    /// middle is above the middle of the dragged row. Rows not laid out (lazy) count
    /// by their place relative to the dragged row.
    private func targetIndex(for state: ThingsRowDrag, rows: [ThingsDisplayRow]) -> Int {
        guard let frame = frameStore.frames[state.id] else { return state.fromIndex }
        let center = frame.midY + state.translation
        var count = 0
        for (index, other) in rows.enumerated() where index != state.fromIndex {
            if let otherFrame = frameStore.frames[other.task.id] {
                if otherFrame.midY < center { count += 1 }
            } else if index < state.fromIndex {
                count += 1
            }
        }
        return count
    }

    /// How far a row slides to open the drop slot of the dragged row.
    private func shift(forRowAt index: Int, id: Int64, in section: ThingsMacSectionData) -> CGFloat {
        guard let current = drag, current.sectionID == section.id, current.id != id,
              let height = frameStore.frames[current.id]?.height else { return 0 }
        if current.targetIndex > current.fromIndex && index > current.fromIndex && index <= current.targetIndex {
            return -height
        }
        if current.targetIndex < current.fromIndex && index < current.fromIndex && index >= current.targetIndex {
            return height
        }
        return 0
    }

    // MARK: - Rows

    @ViewBuilder
    private func sectionView(_ section: ThingsMacSectionData) -> some View {
        if let style = section.header {
            ThingsSectionHeader(style: style)
        }
        ForEach(Array(section.rows.enumerated()), id: \.element.id) { entry in
            rowView(entry.element, index: entry.offset, in: section)
        }
    }

    @ViewBuilder
    private func rowView(_ row: ThingsDisplayRow, index: Int, in section: ThingsMacSectionData) -> some View {
        let id = row.task.id
        if model.expandedTaskID == id {
            ThingsMacTodoEditor(
                task: model.appState.tasks.first(where: { $0.id == id }) ?? row.task,
                model: model
            )
            .padding(.horizontal, -ThingsMetrics.Card.outset)
            .padding(.vertical, ThingsMetrics.Card.verticalMargin)
            .id(id)
        } else {
            listRow(row, index: index, in: section)
        }
    }

    private func listRow(_ row: ThingsDisplayRow, index: Int, in section: ThingsMacSectionData) -> some View {
        let id = row.task.id
        let isDragged = drag?.id == id
        let slide = shift(forRowAt: index, id: id, in: section)
        let offset: CGFloat = isDragged ? (drag?.translation ?? 0) : slide
        return VStack(spacing: 0) {
            ThingsTodoRow(
                model: row.model,
                isSelected: model.selectedTaskID == id,
                onToggle: { toggle(row.task) }
            )
            .contentShape(Rectangle())
            .offset(y: offset)
            .transaction { transaction in
                // The dragged row follows the pointer without easing, and eases home on drop.
                if isDragged { transaction.animation = nil }
            }
            .scaleEffect(isDragged ? ThingsMotion.liftScale : 1)
            .shadow(
                color: Color.black.opacity(isDragged ? ThingsColorOpacity.liftShadow : 0),
                radius: isDragged ? ThingsMetrics.Reorder.liftShadowRadius : 0,
                x: 0,
                y: isDragged ? ThingsMetrics.Reorder.liftShadowOffsetY : 0
            )
            .animation(ThingsMotion.resolved(ThingsMotion.lift, reduceMotion: reduceMotion), value: isDragged)
            .animation(ThingsMotion.resolved(ThingsMotion.reorder, reduceMotion: reduceMotion), value: slide)
            .onTapGesture(count: 2) { model.open(id) }
            .onTapGesture {
                model.select(id)
                listFocused = true
            }
            .simultaneousGesture(dragGesture(for: row, in: section))
        }
        .background(frameReader(id))
        .zIndex(isDragged ? 1 : 0)
        .contextMenu { contextMenu(for: row.task) }
        .id(id)
        .accessibilityAction(named: Text("Move Up")) { moveByAccessibility(id, -1) }
        .accessibilityAction(named: Text("Move Down")) { moveByAccessibility(id, 1) }
    }

    private func frameReader(_ id: Int64) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ThingsRowFramesKey.self,
                value: [id: proxy.frame(in: .named(ThingsMacTodoList.spaceName))]
            )
        }
    }

    private func moveByAccessibility(_ id: Int64, _ step: Int) {
        for section in shownSections where section.allowsReorder {
            guard section.rows.contains(where: { $0.task.id == id }) else { continue }
            let tasks = section.rows.map { $0.task }
            if let plan = ThingsReorder.plan(sectionID: section.id, tasks: tasks, movingID: id, by: step) {
                apply(plan, animation: ThingsMotion.reorderSwap)
            }
            return
        }
    }

    /// A click on the box completes; Opt click cancels (spec 04 section 11).
    private func toggle(_ task: VTask) {
        if NSEvent.modifierFlags.contains(.option) && !task.done {
            model.select(task.id)
            model.cancelSelected()
        } else {
            viewModel.tapCheckbox(task)
        }
    }

    @ViewBuilder
    private func contextMenu(for task: VTask) -> some View {
        Button(String(localized: "Open")) { model.open(task.id) }
        Button(String(localized: "Complete")) { viewModel.tapCheckbox(task) }
        Menu(String(localized: "When")) {
            Button(String(localized: "Today")) { schedule(task, .today) }
            Button(String(localized: "This Evening")) { schedule(task, .thisEvening) }
            Button(String(localized: "Someday")) { schedule(task, .someday) }
            Button(String(localized: "Clear")) { schedule(task, ThingsWhen.none) }
        }
        Button(String(localized: "Move Up")) { moveByAccessibility(task.id, -1) }
        Button(String(localized: "Move Down")) { moveByAccessibility(task.id, 1) }
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

    private func schedule(_ task: VTask, _ when: ThingsWhen) {
        model.select(task.id)
        model.schedule(when)
    }
}

#endif
