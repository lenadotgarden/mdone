import SwiftUI

#if os(macOS)
import AppKit

/// A section of the Mac list: an optional header and its rows.
struct ThingsMacSectionData: Identifiable {
    let id: String
    let header: ThingsSectionHeaderStyle?
    let rows: [ThingsDisplayRow]
}

/// The scrolling list shared by the Mac list and project screens (spec 04
/// sections 1 to 3, 11): selection, arrow keys, Return to open, the open card
/// in place of the row, a context menu. Drag and drop reordering is a TODO.
struct ThingsMacTodoList: View {
    let sections: [ThingsMacSectionData]
    let viewModel: ThingsListViewModel
    let model: ThingsMacModel
    let header: AnyView
    let empty: AnyView?
    let trailing: AnyView?

    @FocusState private var listFocused: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        let ids = sections.flatMap { section in section.rows.map { $0.task.id } }
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
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                    if let trailing = trailing {
                        trailing
                    }
                    Color.clear.frame(height: 48)
                }
            }
            .background(palette[.bgPrimary])
            .focusable()
            .focused($listFocused)
            .focusEffectDisabled()
            .onKeyPress(phases: [.down, .repeat]) { press in handleKey(press) }
            .onChange(of: ids, initial: true) { _, newIDs in model.visibleTaskIDs = newIDs }
            .onChange(of: model.selectedTaskID) { _, newID in
                if let newID = newID {
                    withAnimation { proxy.scrollTo(newID) }
                }
            }
            .onChange(of: model.listFocusToken) { _, _ in listFocused = true }
            .animation(ThingsMotion.rowRemoval, value: ids)
        }
    }

    // MARK: - Keyboard

    /// Arrow keys move the selection, Opt arrow jumps to the ends, Return opens
    /// the card, Delete asks to delete (spec 05). With a card open the keys
    /// belong to its text fields.
    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        if model.expandedTaskID != nil { return .ignored }
        let option = press.modifiers.contains(.option)
        let command = press.modifiers.contains(.command)
        if press.key == .upArrow && !command {
            if option { model.selectFirst() } else { model.moveSelection(by: -1) }
            return .handled
        }
        if press.key == .downArrow && !command {
            if option { model.selectLast() } else { model.moveSelection(by: 1) }
            return .handled
        }
        if press.key == .return && !command && model.selectedTaskID != nil {
            model.openSelected()
            return .handled
        }
        if (press.key == .delete || press.key == .deleteForward) && model.selectedTaskID != nil {
            model.requestDeleteSelected()
            return .handled
        }
        return .ignored
    }

    // MARK: - Rows

    @ViewBuilder
    private func sectionView(_ section: ThingsMacSectionData) -> some View {
        if let style = section.header {
            ThingsSectionHeader(style: style)
        }
        ForEach(section.rows) { row in
            rowView(row)
        }
    }

    @ViewBuilder
    private func rowView(_ row: ThingsDisplayRow) -> some View {
        let id = row.task.id
        if model.expandedTaskID == id {
            ThingsMacTodoEditor(
                task: model.appState.tasks.first(where: { $0.id == id }) ?? row.task,
                model: model
            )
            .padding(ThingsMetrics.Card.outerMargin)
            .id(id)
        } else {
            ThingsTodoRow(
                model: row.model,
                isSelected: model.selectedTaskID == id,
                onToggle: { toggle(row.task) }
            )
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { ThingsDivider() }
            .onTapGesture(count: 2) { model.open(id) }
            .onTapGesture {
                model.select(id)
                listFocused = true
            }
            .contextMenu { contextMenu(for: row.task) }
            .id(id)
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
