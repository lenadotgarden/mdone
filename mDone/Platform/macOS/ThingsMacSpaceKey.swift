import SwiftUI

#if os(macOS)

/// Space anywhere in the window (spec 05 "Create"): a new empty to-do below the selected
/// one, or at the top of the project on screen when only the project is selected (for
/// example after a click on its row in the sidebar). The list handles Space itself while
/// it has the keyboard; this modifier covers the sidebar and the rest of the window.
///
/// It does nothing while a text field has the keyboard, the Quick Find card or a sheet is
/// open, or a card is open, so typing a space is never taken.
private struct ThingsMacSpaceKey: ViewModifier {
    let model: ThingsMacModel

    func body(content: Content) -> some View {
        content
            .onKeyPress(.space, phases: [.down]) { press in
                MainActor.assumeIsolated { handle(press) }
            }
    }

    @MainActor
    private func handle(_ press: KeyPress) -> KeyPress.Result {
        if !press.modifiers.isEmpty { return .ignored }
        if ThingsMacModel.isEditingText { return .ignored }
        if model.showQuickFind || model.sheet != nil || model.isAddingTodo || model.expandedTaskID != nil {
            return .ignored
        }
        return model.addTodoFromSpace() ? .handled : .ignored
    }
}

extension View {
    /// Space adds a to-do below the selection from anywhere in the window.
    func thingsMacSpaceKey(model: ThingsMacModel) -> some View {
        modifier(ThingsMacSpaceKey(model: model))
    }
}

#endif
