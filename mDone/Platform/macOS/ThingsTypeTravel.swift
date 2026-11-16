import SwiftUI

#if os(macOS)
import AppKit

/// Type Travel (spec 04 section 6): with no text field focused, typing
/// anywhere in the main window opens Quick Find with those characters in the
/// field, and the search runs as you type.
///
/// Safe by construction:
/// - the search only starts when the key press has no Cmd, Ctrl or Opt, so menu
///   shortcuts are untouched;
/// - it is skipped when a text field or text view is being edited (the field
///   editor is an `NSText`), when a card is open, a new to-do row is open, a
///   sheet or alert is up, or Quick Find is already open;
/// - arrows, Return, Esc, Tab, Delete and function keys never start it
///   (`ThingsQuickFindEngine.isSearchStart`), and the lists consume their own
///   keys first (`ThingsMacTodoList.handleKey` returns `.ignored` for the rest).
///
/// SwiftUI only delivers a key press to the root while some view of the window
/// has the focus. The list takes it on click; `focusListIfNothingIsFocused`
/// gives it to the list after a launch or a route change when nothing has it,
/// and leaves the sidebar alone when the sidebar has it.
private struct ThingsTypeTravel: ViewModifier {
    let model: ThingsMacModel

    func body(content: Content) -> some View {
        content
            .onKeyPress(phases: [.down]) { press in
                MainActor.assumeIsolated { startSearch(with: press) }
            }
            .onAppear { focusListIfNothingIsFocused() }
            .onChange(of: model.route) { _, _ in focusListIfNothingIsFocused() }
    }

    @MainActor
    private func startSearch(with press: KeyPress) -> KeyPress.Result {
        if model.showQuickFind || model.sheet != nil || model.pendingDeletion != nil { return .ignored }
        if model.isAddingTodo || model.expandedTaskID != nil { return .ignored }
        if !press.modifiers.isDisjoint(with: [.command, .control, .option]) { return .ignored }
        if Self.isEditingText() { return .ignored }
        let typed = press.characters
        guard ThingsQuickFindEngine.isSearchStart(typed) else { return .ignored }
        ThingsQuickFindSeed.shared.offer(typed)
        model.showQuickFind = true
        return .handled
    }

    private func focusListIfNothingIsFocused() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            if model.isAddingTodo || model.expandedTaskID != nil || model.showQuickFind || model.sheet != nil {
                return
            }
            if Self.nothingHasFocus() {
                model.listFocusToken += 1
            }
        }
    }

    /// A text field or text view is the first responder (the shared field
    /// editor of every `TextField` is an `NSTextView`, an `NSText`).
    @MainActor
    private static func isEditingText() -> Bool {
        guard let responder = NSApp.keyWindow?.firstResponder else { return false }
        return responder is NSText
    }

    /// The window itself, or its content view, is the first responder: no
    /// control, list or sidebar has the keyboard.
    @MainActor
    private static func nothingHasFocus() -> Bool {
        guard let window = NSApp.keyWindow else { return false }
        guard let responder = window.firstResponder else { return true }
        return responder === window || responder === window.contentView
    }
}

extension View {
    /// Typing anywhere in the window opens Quick Find (Type Travel).
    func thingsTypeTravel(model: ThingsMacModel) -> some View {
        modifier(ThingsTypeTravel(model: model))
    }
}

#endif
