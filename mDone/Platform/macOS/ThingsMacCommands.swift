import SwiftUI

#if os(macOS)

extension ThingsKeyChord {
    /// The SwiftUI key of the chord.
    var keyEquivalent: KeyEquivalent {
        switch key {
        case "up": return .upArrow
        case "down": return .downArrow
        case "left": return .leftArrow
        case "right": return .rightArrow
        case "return": return .return
        case "space": return .space
        case "escape": return .escape
        case "delete": return .delete
        default: return KeyEquivalent(key.first ?? " ")
        }
    }

    var eventModifiers: EventModifiers {
        var result: EventModifiers = []
        if command { result.insert(.command) }
        if option { result.insert(.option) }
        if shift { result.insert(.shift) }
        if control { result.insert(.control) }
        return result
    }

    /// A key without Command or Control would fire while typing in a text
    /// field. Those (Return, Delete, Opt arrows) are handled by the list's own
    /// key handler instead of a menu item.
    var isSafeForMenu: Bool { command || control }
}

/// One menu item: its title, the shortcut of its command from `ThingsShortcutTable`
/// and the action. Disabled while no Things window is focused (the classic Mac
/// interface keeps its own shortcuts then).
struct ThingsCommandButton: View {
    let id: ThingsCommandID
    let title: String
    let model: ThingsMacModel?
    let action: (ThingsMacModel) -> Void

    var body: some View {
        if let model = model, let chord = ThingsShortcutTable.chord(for: id), chord.isSafeForMenu {
            Button(title) { action(model) }
                .keyboardShortcut(chord.keyEquivalent, modifiers: chord.eventModifiers)
        } else {
            Button(title) {
                if let model = model { action(model) }
            }
            .disabled(model == nil)
        }
    }
}

/// The Things menus of the Mac app: shortcuts of docs/things-spec/05-macos-shortcuts.md.
/// The commands act on `ThingsMacModel`, found as the focused scene value of the key window.
struct ThingsMacCommands: Commands {
    @FocusedValue(\.thingsMac) private var model: ThingsMacModel?

    var body: some Commands {
        CommandGroup(replacing: .newItem) { ThingsFileMenuItems(model: model) }
        CommandGroup(replacing: .appSettings) {
            ThingsCommandButton(id: .settings, title: String(localized: "Settings..."), model: model) { $0.sheet = .settings }
        }
        CommandGroup(after: .pasteboard) { ThingsEditMenuItems(model: model) }
        CommandMenu(String(localized: "Items")) { ThingsItemsMenuItems(model: model) }
        CommandGroup(after: .sidebar) { ThingsGoMenuItems(model: model) }
    }
}

private struct ThingsFileMenuItems: View {
    let model: ThingsMacModel?

    var body: some View {
        ThingsCommandButton(id: .newTodo, title: String(localized: "New To-Do"), model: model) { $0.newTodo() }
        ThingsCommandButton(id: .newProject, title: String(localized: "New Project"), model: model) { $0.sheet = .newProject }
        // Headings are a TODO (DEVIATIONS.md), so the item stays disabled.
        Button(String(localized: "New Heading")) {}
            .disabled(true)
        ThingsCommandButton(id: .newChecklist, title: String(localized: "New Checklist Item"), model: model) { $0.requestChecklist() }
        Button(String(localized: "Quick Entry")) { ThingsQuickEntryController.shared.show() }
            .keyboardShortcut(ThingsShortcutTable.chord(for: .quickEntry)?.keyEquivalent ?? .space, modifiers: .control)
        Button(String(localized: "Enable Global Quick Entry...")) {
            ThingsQuickEntryController.shared.requestGlobalHotkeyAccess()
        }
        Divider()
        ThingsCommandButton(id: .saveAndClose, title: String(localized: "Save and Close"), model: model) { $0.saveAndClose() }
    }
}

private struct ThingsEditMenuItems: View {
    let model: ThingsMacModel?

    var body: some View {
        Divider()
        ThingsCommandButton(id: .duplicate, title: String(localized: "Duplicate"), model: model) { $0.duplicateSelected() }
        Button(String(localized: "Delete")) { model?.requestDeleteSelected() }
            .disabled(model == nil)
        Divider()
        ThingsCommandButton(id: .quickFind, title: String(localized: "Quick Find"), model: model) { $0.showQuickFind = true }
    }
}

private struct ThingsItemsMenuItems: View {
    let model: ThingsMacModel?

    var body: some View {
        Group {
            ThingsCommandButton(id: .complete, title: String(localized: "Complete"), model: model) { $0.completeSelected() }
            ThingsCommandButton(id: .cancel, title: String(localized: "Cancel"), model: model) { $0.cancelSelected() }
        }
        Divider()
        Group {
            ThingsCommandButton(id: .showWhen, title: String(localized: "When..."), model: model) { $0.requestPopover(.when) }
            ThingsCommandButton(id: .startToday, title: String(localized: "Today"), model: model) { $0.schedule(.today) }
            ThingsCommandButton(id: .startEvening, title: String(localized: "This Evening"), model: model) { $0.schedule(.thisEvening) }
            ThingsCommandButton(id: .startAnytime, title: String(localized: "Anytime"), model: model) { $0.schedule(ThingsWhen.none) }
            ThingsCommandButton(id: .startSomeday, title: String(localized: "Someday"), model: model) { $0.schedule(.someday) }
        }
        Menu(String(localized: "Shift Start Date")) {
            ThingsCommandButton(id: .startPlusDay, title: String(localized: "Plus 1 Day"), model: model) { $0.shiftStart(days: 1) }
            ThingsCommandButton(id: .startMinusDay, title: String(localized: "Minus 1 Day"), model: model) { $0.shiftStart(days: -1) }
            ThingsCommandButton(id: .startPlusWeek, title: String(localized: "Plus 1 Week"), model: model) { $0.shiftStart(days: 7) }
            ThingsCommandButton(id: .startMinusWeek, title: String(localized: "Minus 1 Week"), model: model) { $0.shiftStart(days: -7) }
        }
        Divider()
        deadlineItems
        Divider()
        Group {
            ThingsCommandButton(id: .editTags, title: String(localized: "Tags..."), model: model) { $0.requestPopover(.tags) }
            ThingsCommandButton(id: .moveItem, title: String(localized: "Move..."), model: model) { $0.requestMove() }
        }
    }

    @ViewBuilder
    private var deadlineItems: some View {
        ThingsCommandButton(id: .addDeadline, title: String(localized: "Add Deadline..."), model: model) { $0.requestPopover(.deadline) }
        Menu(String(localized: "Shift Deadline")) {
            ThingsCommandButton(id: .deadlinePlusDay, title: String(localized: "Plus 1 Day"), model: model) { $0.shiftDeadline(days: 1) }
            ThingsCommandButton(id: .deadlineMinusDay, title: String(localized: "Minus 1 Day"), model: model) { $0.shiftDeadline(days: -1) }
            ThingsCommandButton(id: .deadlinePlusWeek, title: String(localized: "Plus 1 Week"), model: model) { $0.shiftDeadline(days: 7) }
            ThingsCommandButton(id: .deadlineMinusWeek, title: String(localized: "Minus 1 Week"), model: model) { $0.shiftDeadline(days: -7) }
        }
    }
}

private struct ThingsGoMenuItems: View {
    let model: ThingsMacModel?

    var body: some View {
        ThingsCommandButton(id: .toggleSidebar, title: String(localized: "Show or Hide Sidebar"), model: model) { $0.toggleSidebar() }
        Divider()
        ForEach(ThingsShortcutTable.goCommands, id: \.self) { command in
            if let list = ThingsShortcutTable.list(for: command) {
                ThingsCommandButton(id: command, title: String(localized: "Go to ") + list.title, model: model) {
                    $0.navigate(to: .list(list))
                }
            }
        }
    }
}

#endif
