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


/// Where the rows were laid out, read by the drop delegate to find the insertion slot. A
/// class held in `@State`, so updating it during scrolling does not redraw the list.
private final class ThingsRowFrameStore {
    var frames: [Int64: CGRect] = [:]
}

private struct ThingsRowFramesKey: PreferenceKey {
    static let defaultValue: [Int64: CGRect] = [:]

    static func reduce(value: inout [Int64: CGRect], nextValue: () -> [Int64: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// What the list shows while a to-do hovers over it: the insertion slot, where the
/// dragged row comes from, and the height of the gap.
private struct ThingsDropVisual {
    let sourceID: Int64
    let source: ThingsDropSource
    let slot: ThingsDropSlot
    let rowHeight: CGFloat
}

/// The scrolling list shared by the Mac list and project screens (spec 04
/// sections 1 to 3, 10, 11, 05 "Selectionner" and "Deplacer", 08 drag and drop):
///
/// - selection and keyboard: Up and Down move between rows across sections, Opt
///   jumps to the first or last, Return opens the card, Esc clears the
///   selection, Delete asks to delete, Space is swallowed;
/// - drag and drop: every row is a system drag source (`onDrag`, payload
///   `ThingsDragPayload.todo`), so it can be dropped on a sidebar row as well as inside
///   the list. The list is one `DropDelegate`: while a to-do hovers, the insertion slot
///   follows the pointer and the rows slide apart to open a gap; a drop saves the order
///   through `ThingsDropPlan`, `ThingsListViewModel.commitDrop` and `AppState.moveTask`.
///   Today and project screens also accept a drop in another section where it means
///   something (This Evening, Someday), see `ThingsDropRules`;
/// - Cmd Opt Up and Cmd Opt Down (also Cmd Up and Cmd Down) swap the selected to-do with
///   its neighbour with the same spring, and the accessibility actions Move Up, Move Down
///   and Move to <section> do the same without a pointer;
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
    @State private var dropSlot: ThingsDropSlot?
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

    /// The sections with the order the user just gave them, until the server answers. A
    /// titled section a to-do just left empty is dropped (its header would hang alone).
    private var shownSections: [ThingsMacSectionData] {
        if orderOverride.isEmpty { return sections }
        let arranged = ThingsDropArrangement.rows(
            for: sections.map { (id: $0.id, rows: $0.rows) },
            overrides: orderOverride
        )
        var result: [ThingsMacSectionData] = []
        for (index, section) in sections.enumerated() {
            let rows = arranged[index]
            if rows.isEmpty && !section.rows.isEmpty && section.header != nil { continue }
            result.append(ThingsMacSectionData(
                id: section.id,
                header: section.header,
                rows: rows,
                allowsReorder: section.allowsReorder
            ))
        }
        return result
    }

    var body: some View {
        let palette = ThingsPalette(scheme)
        let shown = shownSections
        let ids = shown.flatMap { section in section.rows.map { $0.task.id } }
        let drop = dropVisual(in: shown)
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
                        sectionView(section, drop: drop)
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
                .onDrop(of: ThingsDragItem.contentTypes, delegate: dropDelegate)
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
        guard let id = model.selectedTaskID, model.expandedTaskID == nil, dropSlot == nil else { return }
        for section in shownSections where section.allowsReorder {
            guard section.rows.contains(where: { $0.task.id == id }) else { continue }
            let tasks = section.rows.map { $0.task }
            guard let plan = ThingsReorder.plan(sectionID: section.id, tasks: tasks, movingID: id, by: step) else {
                return
            }
            apply(.reorder(plan), animation: ThingsMotion.reorderSwap)
            withAnimation(ThingsMotion.resolved(ThingsMotion.reorderSwap, reduceMotion: reduceMotion)) {
                proxy.scrollTo(id)
            }
            return
        }
    }

    /// Shows the new order at once, then saves it. The shown order stays until the last
    /// request of every section the plan touches has finished and the server order is
    /// back; if the save failed the rows then slide back to where they were (rollback).
    private func apply(_ plan: ThingsDropPlan, animation: Animation) {
        let overrides = plan.overrides
        withAnimation(ThingsMotion.resolved(animation, reduceMotion: reduceMotion)) {
            for (sectionID, order) in overrides {
                orderOverride[sectionID] = order
                inflight[sectionID, default: 0] += 1
            }
            dropSlot = nil
        }
        let listModel = viewModel
        let state = model.appState
        let touched = Array(overrides.keys)
        Task { @MainActor in
            _ = await listModel.commitDrop(plan, appState: state)
            for sectionID in touched { finishReorder(sectionID: sectionID) }
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

    // MARK: - Drag and drop

    private var dropDelegate: ThingsListDropDelegate {
        ThingsListDropDelegate(
            slotAt: { y in slot(atY: y) },
            slot: $dropSlot,
            animation: ThingsMotion.resolved(ThingsMotion.reorder, reduceMotion: reduceMotion),
            commit: { target in commitDrop(at: target) }
        )
    }

    /// The section a drag of `id` starts from, in the order shown.
    private func sourceSection(of id: Int64, in shown: [ThingsMacSectionData]) -> ThingsMacSectionData? {
        shown.first { section in section.rows.contains(where: { $0.task.id == id }) }
    }

    /// The insertion slot for a pointer at height `y` of the list: only in the section of
    /// the dragged to-do and the sections it may move to. Nil for a to-do that is not in
    /// a reorderable section of this screen.
    private func slot(atY y: CGFloat) -> ThingsDropSlot? {
        guard let id = ThingsDragSession.shared.payload?.todoID else { return nil }
        let shown = shownSections
        guard let source = sourceSection(of: id, in: shown), source.allowsReorder else { return nil }
        let legal = shown.filter { section in
            section.allowsReorder
                && (section.id == source.id || ThingsDropRules.when(from: source.id, to: section.id) != nil)
        }
        let layout = legal.map { section in
            ThingsDropLayoutSection(id: section.id, rowIDs: section.rows.map { $0.task.id })
        }
        var frames: [Int64: ThingsDropRowFrame] = [:]
        for (rowID, rect) in frameStore.frames {
            frames[rowID] = ThingsDropRowFrame(minY: rect.minY, maxY: rect.maxY)
        }
        return ThingsDropGeometry.slot(sections: layout, frames: frames, pointerY: y)
    }

    private func commitDrop(at slot: ThingsDropSlot) -> Bool {
        guard let id = ThingsDragSession.shared.payload?.todoID else { return false }
        let tasks = shownSections.map { section in
            ThingsSectionTasks(id: section.id, tasks: section.rows.map { $0.task })
        }
        guard let plan = ThingsDropPlan.make(slot: slot, movingID: id, sections: tasks) else { return false }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        apply(plan, animation: ThingsMotion.reorder)
        return true
    }

    private func dropVisual(in shown: [ThingsMacSectionData]) -> ThingsDropVisual? {
        guard let slot = dropSlot, let id = ThingsDragSession.shared.payload?.todoID,
              let section = sourceSection(of: id, in: shown),
              let index = section.rows.firstIndex(where: { $0.task.id == id }) else { return nil }
        let height = frameStore.frames[id].map { $0.height } ?? ThingsMetrics.Reorder.fallbackGapHeight
        return ThingsDropVisual(
            sourceID: id,
            source: ThingsDropSource(sectionID: section.id, index: index),
            slot: slot,
            rowHeight: height
        )
    }

    /// Starts the system drag of a row: selects it and records the payload for the targets.
    private func beginDrag(_ row: ThingsDisplayRow) -> NSItemProvider {
        model.select(row.task.id)
        listFocused = true
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        return ThingsDragSession.shared.begin(.todo(row.task.id))
    }

    /// The image under the pointer: the row on a card with the lift shadow.
    private func dragPreview(_ row: ThingsDisplayRow) -> some View {
        let palette = ThingsPalette(scheme)
        return ThingsTodoRow(model: row.model, isSelected: false)
            .frame(width: frameStore.frames[row.task.id]?.width)
            .background(
                RoundedRectangle(cornerRadius: ThingsMetrics.Card.cornerRadius, style: .continuous)
                    .fill(palette[.bgPrimary])
            )
            .shadow(
                color: Color.black.opacity(ThingsColorOpacity.liftShadow),
                radius: ThingsMetrics.Reorder.liftShadowRadius,
                x: 0,
                y: ThingsMetrics.Reorder.liftShadowOffsetY
            )
    }

    // MARK: - Rows

    @ViewBuilder
    private func sectionView(_ section: ThingsMacSectionData, drop: ThingsDropVisual?) -> some View {
        if let style = section.header {
            ThingsSectionHeader(style: style)
        }
        ForEach(Array(section.rows.enumerated()), id: \.element.id) { entry in
            rowView(entry.element, index: entry.offset, in: section, drop: drop)
        }
    }

    @ViewBuilder
    private func rowView(
        _ row: ThingsDisplayRow,
        index: Int,
        in section: ThingsMacSectionData,
        drop: ThingsDropVisual?
    ) -> some View {
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
            listRow(row, index: index, in: section, drop: drop)
        }
    }

    private func listRow(
        _ row: ThingsDisplayRow,
        index: Int,
        in section: ThingsMacSectionData,
        drop: ThingsDropVisual?
    ) -> some View {
        let id = row.task.id
        // While a to-do hovers over the list its own row is hidden (the gap shows where it
        // lands) and the others slide to open the gap and close the place it left. If the
        // pointer leaves the list, `dropSlot` is nil again and the row comes back.
        let isSource = drop?.sourceID == id
        var slide: CGFloat = 0
        if let drop = drop {
            slide = ThingsDropGeometry.shift(
                forRowAt: index,
                in: section.id,
                source: drop.source,
                slot: drop.slot,
                rowHeight: drop.rowHeight
            )
        }
        let moves = ThingsDropRules.moves(from: section.id, among: sections.map { $0.id })
        return VStack(spacing: 0) {
            ThingsTodoRow(
                model: row.model,
                isSelected: model.selectedTaskID == id,
                onToggle: { toggle(row.task) }
            )
            .contentShape(Rectangle())
            .opacity(isSource ? 0 : 1)
            .offset(y: slide)
            .animation(ThingsMotion.resolved(ThingsMotion.reorder, reduceMotion: reduceMotion), value: slide)
            .onTapGesture(count: 2) { model.open(id) }
            .onTapGesture {
                model.select(id)
                listFocused = true
            }
            .onDrag {
                beginDrag(row)
            } preview: {
                dragPreview(row)
            }
        }
        .background(frameReader(id))
        .contextMenu { contextMenu(for: row.task, moves: moves) }
        .id(id)
        .accessibilityAction(named: Text("Move Up")) { moveByAccessibility(id, -1) }
        .accessibilityAction(named: Text("Move Down")) { moveByAccessibility(id, 1) }
        .accessibilityActions {
            ForEach(moves, id: \.sectionID) { move in
                Button(sectionMoveTitle(move.when)) { moveToSection(id, sectionID: move.sectionID) }
            }
        }
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
                apply(.reorder(plan), animation: ThingsMotion.reorderSwap)
            }
            return
        }
    }

    /// Moves a to-do to the end of another section (This Evening, Today, Someday, Anytime).
    private func moveToSection(_ id: Int64, sectionID: String) {
        let shown = shownSections
        guard let target = shown.first(where: { $0.id == sectionID }) else { return }
        let slot = ThingsDropSlot(sectionID: sectionID, index: target.rows.count)
        let tasks = shown.map { section in
            ThingsSectionTasks(id: section.id, tasks: section.rows.map { $0.task })
        }
        guard let plan = ThingsDropPlan.make(slot: slot, movingID: id, sections: tasks) else { return }
        apply(plan, animation: ThingsMotion.reorder)
    }

    private func sectionMoveTitle(_ when: ThingsWhen) -> String {
        switch when {
        case .thisEvening: return String(localized: "Move to This Evening")
        case .today: return String(localized: "Move to Today")
        case .someday: return String(localized: "Move to Someday")
        case .none: return String(localized: "Move to Anytime")
        case .date: return String(localized: "Move")
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
    private func contextMenu(for task: VTask, moves: [ThingsSectionMove]) -> some View {
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
        ForEach(moves, id: \.sectionID) { move in
            Button(sectionMoveTitle(move.when)) { moveToSection(task.id, sectionID: move.sectionID) }
        }
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