import SwiftUI

/// The empty to-do row that opens at the top of a list when the Magic Plus is
/// tapped. It calls `onFinish` exactly once, with the trimmed title (empty when
/// the user gave up), when the user presses return or leaves the field.
struct ThingsInlineAddRow: View {
    let onFinish: (String) -> Void

    @State private var title = ""
    @State private var finished = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            ThingsCheckbox(state: .open)
            TextField(String(localized: "New To-Do"), text: $title)
                .font(ThingsTypography.todoTitle)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { finish() }
        }
        .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
        .padding(.vertical, ThingsMetrics.Row.verticalPadding)
        .frame(minHeight: ThingsMetrics.Row.minHeight, alignment: .leading)
        .onAppear { focused = true }
        .onChange(of: focused) { _, isFocused in
            if !isFocused { finish() }
        }
    }

    private func finish() {
        if finished { return }
        finished = true
        onFinish(title.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
