import SwiftUI

#if os(macOS)

/// Quick Find (spec 04 section 6), opened by Cmd F or the toolbar search
/// button as a sheet. It lists default lists, projects, Areas, tags and open
/// to-dos matching the text; Return opens the highlighted result, the arrow
/// keys move it. Type Travel (typing anywhere opens it), "Continue Search" in
/// notes and Logbook, and Cmd Return for a new window are TODOs (DEVIATIONS.md).
struct ThingsQuickFindView: View {
    let model: ThingsMacModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var query = ""
    @State private var highlighted = 0
    @FocusState private var focused: Bool

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    private var results: [ThingsQuickFindResult] {
        ThingsQuickFindEngine.results(
            query: query,
            tasks: model.appState.tasks,
            projects: model.appState.projects,
            labels: model.appState.labels
        )
    }

    var body: some View {
        let found = results
        return VStack(spacing: 0) {
            TextField(String(localized: "Quick Find"), text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .padding(ThingsMetrics.Spacing.m)
                .focused($focused)
                .onSubmit { openHighlighted(in: found) }
                .onKeyPress(.upArrow) {
                    highlighted = max(highlighted - 1, 0)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    highlighted = min(highlighted + 1, max(found.count - 1, 0))
                    return .handled
                }
            Divider()
            if found.isEmpty {
                Text(query.isEmpty ? String(localized: "Type to search") : String(localized: "No results"))
                    .font(ThingsTypography.emptyMessage)
                    .foregroundStyle(palette[.textSecondary])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                resultList(found)
            }
        }
        .frame(width: 480, height: 360)
        .onAppear { focused = true }
        .onChange(of: query) { _, _ in highlighted = 0 }
        .onExitCommand { dismiss() }
    }

    private func resultList(_ found: [ThingsQuickFindResult]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(found.enumerated()), id: \.element.id) { entry in
                    resultRow(entry.element, isHighlighted: entry.offset == highlighted)
                        .onTapGesture { choose(entry.element) }
                }
            }
        }
    }

    private func resultRow(_ result: ThingsQuickFindResult, isHighlighted: Bool) -> some View {
        HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            Image(systemName: symbol(for: result.target))
                .frame(width: ThingsMetrics.Icon.list)
                .foregroundStyle(palette[.textSecondary])
            Text(verbatim: result.title)
                .font(ThingsTypography.todoTitle)
                .foregroundStyle(palette[.textPrimary])
                .lineLimit(1)
            Spacer(minLength: 0)
            if let subtitle = result.subtitle {
                Text(verbatim: subtitle)
                    .font(ThingsTypography.notes)
                    .foregroundStyle(palette[.textSecondary])
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, ThingsMetrics.Spacing.m)
        .padding(.vertical, ThingsMetrics.Spacing.s)
        .background(isHighlighted ? palette[.selectionRow] : Color.clear)
        .contentShape(Rectangle())
    }

    private func symbol(for target: ThingsQuickFindTarget) -> String {
        switch target {
        case .list(let list): return ThingsIcons.symbol(for: list.kind)
        case .project: return ThingsIcons.project
        case .area: return ThingsIcons.area
        case .todo: return "square"
        case .tag: return ThingsIcons.tag
        }
    }

    private func openHighlighted(in found: [ThingsQuickFindResult]) {
        if found.indices.contains(highlighted) {
            choose(found[highlighted])
        }
    }

    /// A tag stays in the field so the to-dos that carry it show up.
    private func choose(_ result: ThingsQuickFindResult) {
        if case .tag(let title) = result.target {
            query = title
            return
        }
        model.open(result.target)
        dismiss()
    }
}

#endif
