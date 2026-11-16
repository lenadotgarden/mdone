import SwiftUI

#if os(macOS)

/// The characters that opened Quick Find through Type Travel. The root view
/// leaves them here and `ThingsQuickFindView` takes them when it appears, so
/// the model of the window (not owned by the search) needs no extra field.
@MainActor
final class ThingsQuickFindSeed {
    static let shared = ThingsQuickFindSeed()

    private var pending = ""

    private init() {}

    func offer(_ characters: String) {
        pending = characters
    }

    /// The pending characters, once.
    func take() -> String {
        let text = pending
        pending = ""
        return text
    }
}

/// Quick Find (spec 04 section 6): a card over the window, opened by Cmd F, the
/// toolbar search button, or Type Travel (typing anywhere in the window, see
/// `ThingsMacRootView`). It searches as you type, grouped like Things: to-dos,
/// projects and Areas, tags, after the default lists. Return opens the
/// highlighted result, the arrow keys move it, Esc closes. Choosing a tag keeps
/// the search open and lists the to-dos that carry it; Delete on an empty field
/// leaves the tag. "Continue Search" in notes and the Logbook, and Cmd Return
/// for a new window are TODOs (DEVIATIONS.md).
struct ThingsQuickFindView: View {
    let model: ThingsMacModel

    @Environment(\.colorScheme) private var scheme
    @State private var query = ""
    @State private var activeTag: String?
    @State private var highlighted = 0
    @FocusState private var focused: Bool

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    private enum Row: Identifiable {
        case header(String)
        case result(Int, ThingsQuickFindResult)

        var id: String {
            switch self {
            case .header(let title): return "header." + title
            case .result(_, let result): return result.id
            }
        }
    }

    private var results: [ThingsQuickFindResult] {
        if let tag = activeTag {
            let tagged = ThingsQuickFindEngine.todos(
                taggedWith: tag, tasks: model.appState.tasks, projects: model.appState.projects
            )
            let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if needle.isEmpty { return tagged }
            return tagged.filter { $0.title.localizedCaseInsensitiveContains(needle) }
        }
        return ThingsQuickFindEngine.results(
            query: query,
            tasks: model.appState.tasks,
            projects: model.appState.projects,
            labels: model.appState.labels
        )
    }

    private func rows(for found: [ThingsQuickFindResult]) -> [Row] {
        var rows: [Row] = []
        var index = 0
        for block in ThingsQuickFindEngine.grouped(found) {
            if let title = block.group.title, activeTag == nil {
                rows.append(.header(title))
            }
            for result in block.results {
                rows.append(.result(index, result))
                index += 1
            }
        }
        return rows
    }

    var body: some View {
        let rowList = rows(for: results)
        let flat: [ThingsQuickFindResult] = rowList.compactMap { row in
            if case .result(_, let result) = row { return result }
            return nil
        }
        return ZStack(alignment: .top) {
            palette[.textPrimary].opacity(0.08)
                .ignoresSafeArea()
                .onTapGesture { close() }
            card(rowList, flat: flat)
                .padding(.top, ThingsMetrics.Spacing.xxl * 2)
        }
        .transition(.opacity)
    }

    private func card(_ rowList: [Row], flat: [ThingsQuickFindResult]) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: ThingsMetrics.Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(palette[.textSecondary])
                if let tag = activeTag {
                    ThingsTagChip(title: tag, isActive: true)
                }
                TextField(String(localized: "Quick Find"), text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .focused($focused)
                    .onSubmit { openHighlighted(in: flat) }
                    .onKeyPress(.upArrow) {
                        highlighted = max(highlighted - 1, 0)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        highlighted = min(highlighted + 1, max(flat.count - 1, 0))
                        return .handled
                    }
                    .onKeyPress(.escape) {
                        close()
                        return .handled
                    }
                    .onKeyPress(.delete) {
                        if query.isEmpty, activeTag != nil {
                            activeTag = nil
                            return .handled
                        }
                        return .ignored
                    }
            }
            .padding(ThingsMetrics.Spacing.m)
            Divider()
            if flat.isEmpty {
                Text(emptyMessage)
                    .font(ThingsTypography.emptyMessage)
                    .foregroundStyle(palette[.textSecondary])
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                resultList(rowList, flat: flat)
            }
        }
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: ThingsMetrics.Card.cornerRadius, style: .continuous)
                .fill(palette[.bgExpandedTodo])
        )
        .clipShape(RoundedRectangle(cornerRadius: ThingsMetrics.Card.cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(ThingsColorOpacity.cardShadow), radius: ThingsMetrics.Card.cornerRadius)
        .onAppear { present() }
        .onChange(of: query) { _, _ in highlighted = 0 }
        .onChange(of: activeTag) { _, _ in highlighted = 0 }
        .onExitCommand { close() }
    }

    private var emptyMessage: String {
        if activeTag != nil { return String(localized: "No to-dos with this tag") }
        return query.isEmpty ? String(localized: "Type to search") : String(localized: "No results")
    }

    private func resultList(_ rowList: [Row], flat: [ThingsQuickFindResult]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(rowList) { row in
                        switch row {
                        case .header(let title):
                            Text(verbatim: title)
                                .font(ThingsTypography.notes.weight(.semibold))
                                .foregroundStyle(palette[.textSecondary])
                                .padding(.horizontal, ThingsMetrics.Spacing.m)
                                .padding(.top, ThingsMetrics.Spacing.s)
                                .padding(.bottom, ThingsMetrics.Spacing.xs)
                        case .result(let index, let result):
                            resultRow(result, isHighlighted: index == highlighted)
                                .onTapGesture { choose(result) }
                        }
                    }
                }
            }
            .frame(maxHeight: 340)
            .onChange(of: highlighted) { _, newValue in
                if flat.indices.contains(newValue) {
                    proxy.scrollTo(flat[newValue].id)
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
        .id(result.id)
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

    // MARK: - Actions

    /// Focus first, then put the typed characters in: giving a field focus
    /// can select its text, and the next key would replace it. Characters
    /// typed meanwhile stay after the seed.
    private func present() {
        focused = true
        let seed = ThingsQuickFindSeed.shared.take()
        if seed.isEmpty { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000)
            query = seed + query
            focused = true
        }
    }

    private func close() {
        model.showQuickFind = false
        model.listFocusToken += 1
    }

    private func openHighlighted(in found: [ThingsQuickFindResult]) {
        if found.indices.contains(highlighted) {
            choose(found[highlighted])
        }
    }

    /// A tag keeps the search open on the to-dos that carry it. Anything else
    /// opens and closes the search.
    private func choose(_ result: ThingsQuickFindResult) {
        if case .tag(let title) = result.target {
            activeTag = title
            query = ""
            return
        }
        model.open(result.target)
        close()
    }
}

#endif
