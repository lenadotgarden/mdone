import Foundation

/// One undoable change of the Things UI: how to take it back and how to redo it.
///
/// The closures act on the server through `AppState` (see `ThingsMacModel+Undo`). They
/// capture the ids and values they need when the command is recorded, never a `VTask`
/// that may be stale. Vikunja cannot undelete a task, so undoing a delete creates a new
/// task and the id changes: the model keeps an alias table so older commands that name
/// the deleted id still find the new task.
struct ThingsUndoCommand {
    /// Whole localized phrase such as "Complete To-Do", shown in the Edit menu as
    /// "Undo Complete To-Do" and "Redo Complete To-Do".
    let title: String
    /// Commands recorded close together with the same key merge into one step: the
    /// user undoes the whole burst at once (typing a date, pressing Ctrl ] five times).
    let coalescingKey: String?
    let undo: @MainActor () async -> Void
    let redo: @MainActor () async -> Void

    init(
        title: String,
        coalescingKey: String? = nil,
        undo: @escaping @MainActor () async -> Void,
        redo: @escaping @MainActor () async -> Void
    ) {
        self.title = title
        self.coalescingKey = coalescingKey
        self.undo = undo
        self.redo = redo
    }
}

/// The undo and redo history of one Things window. Pure bookkeeping: it never runs a
/// command, `popUndo` and `popRedo` hand the command to the caller, which runs it.
///
/// - At most `maxDepth` steps are kept, the oldest is dropped first.
/// - Recording a new command empties the redo history.
/// - Commands with the same non-nil `coalescingKey` recorded within
///   `coalescingWindow` seconds of each other become one step that undoes to the
///   state before the first and redoes to the state after the last.
/// - `clear()` is called on logout so a new session never undoes the old one.
struct ThingsUndoStack {
    static let maxDepth = 100
    static let coalescingWindow: TimeInterval = 1.5

    private struct Entry {
        var command: ThingsUndoCommand
        var recordedAt: Date
    }

    private var undoEntries: [Entry] = []
    private var redoEntries: [Entry] = []

    init() {}

    var canUndo: Bool { !undoEntries.isEmpty }
    var canRedo: Bool { !redoEntries.isEmpty }
    var undoCount: Int { undoEntries.count }
    var redoCount: Int { redoEntries.count }
    var undoTitle: String? { undoEntries.last?.command.title }
    var redoTitle: String? { redoEntries.last?.command.title }

    /// Adds a step. `now` is injectable for tests.
    mutating func record(_ command: ThingsUndoCommand, now: Date = Date()) {
        redoEntries.removeAll()
        if let top = undoEntries.last,
           let key = command.coalescingKey,
           top.command.coalescingKey == key,
           now.timeIntervalSince(top.recordedAt) <= Self.coalescingWindow {
            let merged = ThingsUndoCommand(
                title: command.title,
                coalescingKey: key,
                undo: top.command.undo,
                redo: command.redo
            )
            undoEntries[undoEntries.count - 1] = Entry(command: merged, recordedAt: now)
            return
        }
        undoEntries.append(Entry(command: command, recordedAt: now))
        if undoEntries.count > Self.maxDepth {
            undoEntries.removeFirst(undoEntries.count - Self.maxDepth)
        }
    }

    /// Takes the newest step off the undo history and puts it on the redo history. The
    /// caller then runs the returned command's `undo`.
    mutating func popUndo() -> ThingsUndoCommand? {
        guard let entry = undoEntries.popLast() else { return nil }
        redoEntries.append(Entry(command: entry.command, recordedAt: .distantPast))
        return entry.command
    }

    /// Takes the newest step off the redo history and puts it back on the undo history.
    /// The caller then runs the returned command's `redo`.
    mutating func popRedo() -> ThingsUndoCommand? {
        guard let entry = redoEntries.popLast() else { return nil }
        undoEntries.append(Entry(command: entry.command, recordedAt: .distantPast))
        return entry.command
    }

    /// Drops the newest step when it carries `key`. Used when the user cancels the
    /// change at once (a second click on a box that was just ticked).
    mutating func discardNewest(ifKey key: String) {
        guard let top = undoEntries.last, top.command.coalescingKey == key else { return }
        undoEntries.removeLast()
    }

    mutating func clear() {
        undoEntries.removeAll()
        redoEntries.removeAll()
    }
}
