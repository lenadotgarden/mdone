import SwiftUI

/// The empty to-do row that opens at the top of a list when the Magic Plus is
/// tapped (iPhone) or New To-Do is chosen (Mac). It calls `onFinish` exactly
/// once, with the trimmed title (empty when the user gave up), when the user
/// presses return or leaves the field.
///
/// The text is passed on as typed: natural language ("buy milk tomorrow +Home
/// *errand") is read by `ThingsListViewModel.quickAdd`, so every entry point
/// gets it. While typing, a preview line under the field shows what the line
/// will become.
struct ThingsInlineAddRow: View {
    let onFinish: (String) -> Void

    @Environment(AppState.self) private var appState
    @State private var title = ""
    @State private var finished = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.xs) {
            HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                ThingsCheckbox(state: .open)
                TextField(String(localized: "New To-Do"), text: $title)
                    .font(ThingsTypography.todoTitle)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { finish() }
            }
            if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ThingsNaturalLanguagePreview(text: title, appState: appState)
                    .padding(.leading, ThingsMetrics.Checkbox.size + ThingsMetrics.Row.checkboxTitleSpacing)
            }
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
