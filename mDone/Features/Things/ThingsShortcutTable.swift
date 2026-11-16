import Foundation

/// Every Mac keyboard command of the Things shell (docs/things-spec/05-macos-shortcuts.md).
/// Pure data: no SwiftUI, so the table is unit tested on both platforms. The Mac
/// menu bar (Platform/macOS/ThingsMacCommands) turns a chord into a SwiftUI shortcut.
enum ThingsCommandID: String, CaseIterable, Hashable {
    // Go to
    case goInbox, goToday, goUpcoming, goAnytime, goSomeday, goLogbook
    // Create
    case newTodo, newProject, newHeading, newChecklist, quickEntry
    // Edit
    case openItem, saveAndClose, duplicate, complete, cancel, deleteItem, moveCompletedToLogbook
    // Select
    case selectFirst, selectLast, extendSelectionUp, extendSelectionDown, selectAll
    // Move
    case moveItem, moveItemUp, moveItemDown, moveItemToTop, moveItemToBottom
    // Dates
    case showWhen, startToday, startEvening, startAnytime, startSomeday
    case startPlusDay, startMinusDay, startPlusWeek, startMinusWeek
    case addDeadline, deadlinePlusDay, deadlineMinusDay, deadlinePlusWeek, deadlineMinusWeek
    case addRepeat
    // Windows, search, tags
    case toggleSidebar, newWindow, quickFind, findInText, showNavigation, goBack, editTags, settings
}

/// A key and its modifiers. `key` is a single lowercase character or one of the
/// names `up`, `down`, `left`, `right`, `return`, `space`, `escape`, `delete`.
struct ThingsKeyChord: Hashable {
    let key: String
    let command: Bool
    let option: Bool
    let shift: Bool
    let control: Bool

    init(_ key: String, control: Bool = false, option: Bool = false, shift: Bool = false, command: Bool = false) {
        self.key = key
        self.command = command
        self.option = option
        self.shift = shift
        self.control = control
    }

    /// Mac style text such as the Shift Command N glyphs, in the order Ctrl, Opt, Shift, Cmd.
    var display: String {
        var text = ""
        if control { text += "\u{2303}" }
        if option { text += "\u{2325}" }
        if shift { text += "\u{21E7}" }
        if command { text += "\u{2318}" }
        return text + ThingsKeyChord.glyph(for: key)
    }

    private static func glyph(for key: String) -> String {
        switch key {
        case "up": return "\u{2191}"
        case "down": return "\u{2193}"
        case "left": return "\u{2190}"
        case "right": return "\u{2192}"
        case "return": return "\u{21A9}"
        case "space": return "Space"
        case "escape": return "\u{238B}"
        case "delete": return "\u{232B}"
        default: return key.uppercased()
        }
    }
}

/// One row of the table. `isImplemented` is false for a TODO, with the reason in `note`.
struct ThingsShortcutEntry: Equatable {
    let id: ThingsCommandID
    let chord: ThingsKeyChord
    let isImplemented: Bool
    let note: String
}

enum ThingsShortcutTable {
    /// The command number of the Go To shortcuts, Cmd 1 to Cmd 6 (spec 05, Navigation).
    static let goCommands: [ThingsCommandID] = [
        .goInbox, .goToday, .goUpcoming, .goAnytime, .goSomeday, .goLogbook
    ]

    static let entries: [ThingsShortcutEntry] = navigation + creation + editing + selection + moving + dates + windows

    private static func done(_ id: ThingsCommandID, _ chord: ThingsKeyChord) -> ThingsShortcutEntry {
        ThingsShortcutEntry(id: id, chord: chord, isImplemented: true, note: "")
    }

    private static func todo(_ id: ThingsCommandID, _ chord: ThingsKeyChord, _ note: String) -> ThingsShortcutEntry {
        ThingsShortcutEntry(id: id, chord: chord, isImplemented: false, note: note)
    }

    private static let navigation: [ThingsShortcutEntry] = [
        done(.goInbox, ThingsKeyChord("1", command: true)),
        done(.goToday, ThingsKeyChord("2", command: true)),
        done(.goUpcoming, ThingsKeyChord("3", command: true)),
        done(.goAnytime, ThingsKeyChord("4", command: true)),
        done(.goSomeday, ThingsKeyChord("5", command: true)),
        done(.goLogbook, ThingsKeyChord("6", command: true)),
        todo(.goBack, ThingsKeyChord("left", command: true), "Conflicts with caret movement in text fields; the toolbar button works"),
        todo(.showNavigation, ThingsKeyChord("o", shift: true, command: true), "Navigation popover not built; Quick Find covers it")
    ]

    private static let creation: [ThingsShortcutEntry] = [
        done(.newTodo, ThingsKeyChord("n", command: true)),
        done(.newProject, ThingsKeyChord("n", option: true, command: true)),
        todo(.newHeading, ThingsKeyChord("n", shift: true, command: true), "Headings need the things-headings view, see DEVIATIONS"),
        done(.newChecklist, ThingsKeyChord("c", shift: true, command: true)),
        done(.quickEntry, ThingsKeyChord("space", control: true))
    ]

    private static let editing: [ThingsShortcutEntry] = [
        done(.openItem, ThingsKeyChord("return")),
        done(.saveAndClose, ThingsKeyChord("return", command: true)),
        done(.duplicate, ThingsKeyChord("d", command: true)),
        done(.complete, ThingsKeyChord("k", command: true)),
        done(.cancel, ThingsKeyChord("k", option: true, command: true)),
        done(.deleteItem, ThingsKeyChord("delete")),
        todo(.moveCompletedToLogbook, ThingsKeyChord("y", shift: true, command: true), "Completed to-dos enter the Logbook at once")
    ]

    private static let selection: [ThingsShortcutEntry] = [
        done(.selectFirst, ThingsKeyChord("up", option: true)),
        done(.selectLast, ThingsKeyChord("down", option: true)),
        todo(.extendSelectionUp, ThingsKeyChord("up", shift: true), "Single selection only, multi-select is a TODO"),
        todo(.extendSelectionDown, ThingsKeyChord("down", shift: true), "Single selection only, multi-select is a TODO"),
        todo(.selectAll, ThingsKeyChord("a", command: true), "Single selection only, multi-select is a TODO")
    ]

    private static let moving: [ThingsShortcutEntry] = [
        done(.moveItem, ThingsKeyChord("m", shift: true, command: true)),
        todo(.moveItemUp, ThingsKeyChord("up", command: true), "Reordering needs the list view positions"),
        todo(.moveItemDown, ThingsKeyChord("down", command: true), "Reordering needs the list view positions"),
        todo(.moveItemToTop, ThingsKeyChord("up", option: true, command: true), "Reordering needs the list view positions"),
        todo(.moveItemToBottom, ThingsKeyChord("down", option: true, command: true), "Reordering needs the list view positions")
    ]

    private static let dates: [ThingsShortcutEntry] = [
        done(.showWhen, ThingsKeyChord("s", command: true)),
        done(.startToday, ThingsKeyChord("t", command: true)),
        done(.startEvening, ThingsKeyChord("e", command: true)),
        done(.startAnytime, ThingsKeyChord("r", command: true)),
        done(.startSomeday, ThingsKeyChord("o", command: true)),
        done(.startPlusDay, ThingsKeyChord("]", control: true)),
        done(.startMinusDay, ThingsKeyChord("[", control: true)),
        done(.startPlusWeek, ThingsKeyChord("]", control: true, shift: true)),
        done(.startMinusWeek, ThingsKeyChord("[", control: true, shift: true)),
        done(.addDeadline, ThingsKeyChord("d", shift: true, command: true)),
        done(.deadlinePlusDay, ThingsKeyChord(".", control: true)),
        done(.deadlineMinusDay, ThingsKeyChord(",", control: true)),
        done(.deadlinePlusWeek, ThingsKeyChord(".", control: true, shift: true)),
        done(.deadlineMinusWeek, ThingsKeyChord(",", control: true, shift: true)),
        todo(.addRepeat, ThingsKeyChord("r", shift: true, command: true), "Repeat panel not built")
    ]

    private static let windows: [ThingsShortcutEntry] = [
        done(.toggleSidebar, ThingsKeyChord("/", command: true)),
        todo(.newWindow, ThingsKeyChord("n", control: true, command: true), "One window only for now"),
        done(.quickFind, ThingsKeyChord("f", command: true)),
        todo(.findInText, ThingsKeyChord("f", shift: true, command: true), "Find in text of notes not built; Cmd F is Quick Find"),
        done(.editTags, ThingsKeyChord("t", shift: true, command: true)),
        done(.settings, ThingsKeyChord(",", command: true))
    ]

    // MARK: - Lookup

    static func entry(for id: ThingsCommandID) -> ThingsShortcutEntry? {
        entries.first { $0.id == id }
    }

    static func chord(for id: ThingsCommandID) -> ThingsKeyChord? {
        entry(for: id)?.chord
    }

    /// The command a chord triggers. Only implemented entries answer.
    static func command(for chord: ThingsKeyChord) -> ThingsCommandID? {
        entries.first { $0.chord == chord && $0.isImplemented }?.id
    }

    /// The Go To command of a list, for the sidebar tooltips.
    static func goCommand(for list: ThingsList) -> ThingsCommandID {
        switch list {
        case .inbox: return .goInbox
        case .today: return .goToday
        case .upcoming: return .goUpcoming
        case .anytime: return .goAnytime
        case .someday: return .goSomeday
        case .logbook: return .goLogbook
        }
    }

    /// The list a Go To command opens, nil for any other command.
    static func list(for id: ThingsCommandID) -> ThingsList? {
        switch id {
        case .goInbox: return .inbox
        case .goToday: return .today
        case .goUpcoming: return .upcoming
        case .goAnytime: return .anytime
        case .goSomeday: return .someday
        case .goLogbook: return .logbook
        default: return nil
        }
    }

    static var todoEntries: [ThingsShortcutEntry] {
        entries.filter { !$0.isImplemented }
    }

    /// Chords used by more than one implemented command. Must stay empty.
    static var conflicts: [ThingsKeyChord] {
        var seen = Set<ThingsKeyChord>()
        var duplicates: [ThingsKeyChord] = []
        for entry in entries where entry.isImplemented {
            if seen.contains(entry.chord) {
                duplicates.append(entry.chord)
            } else {
                seen.insert(entry.chord)
            }
        }
        return duplicates
    }
}
