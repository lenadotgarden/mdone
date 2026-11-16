import SwiftUI

/// The Home screen, root of the Things navigation (spec 02 section 1): the six
/// lists, then projects without an Area, then Areas with their projects.
/// Navigation goes through `ThingsRoute` values resolved by the shell.
struct ThingsHomeScreen: View {
    @State private var viewModel: ThingsHomeViewModel
    let onOpenSettings: () -> Void

    @State private var query = ""
    @State private var detailTask: VTask?
    @State private var showNewList = false
    @State private var creating: NewListKind?
    @State private var newTitle = ""

    @Environment(\.colorScheme) private var scheme

    private enum NewListKind {
        case project
        case area
    }

    init(viewModel: ThingsHomeViewModel, onOpenSettings: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenSettings = onOpenSettings
    }

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        Group {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                homeList
            } else {
                searchResults
            }
        }
        .background(palette[.bgPrimary])
        .searchable(text: $query, prompt: String(localized: "Quick Find"))
        .toolbar {
            ToolbarItemGroup(placement: bottomPlacement) {
                Button {
                    showNewList = true
                } label: {
                    Label(String(localized: "New List"), systemImage: ThingsIcons.add)
                }
                Spacer()
                Button {
                    onOpenSettings()
                } label: {
                    Label(String(localized: "Settings"), systemImage: "gearshape")
                }
            }
        }
        .sheet(item: $detailTask) { task in
            TaskDetailSheet(task: task)
        }
        .confirmationDialog(String(localized: "New List"), isPresented: $showNewList, titleVisibility: .visible) {
            Button(String(localized: "New Project")) { startCreating(.project) }
            Button(String(localized: "New Area")) { startCreating(.area) }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
        .alert(
            creating == .area ? String(localized: "New Area") : String(localized: "New Project"),
            isPresented: Binding(
                get: { creating != nil },
                set: { isPresented in if !isPresented { creating = nil } }
            )
        ) {
            TextField(String(localized: "Title"), text: $newTitle)
            Button(String(localized: "Create")) { commitCreate() }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }

    private var bottomPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .bottomBar
        #else
        return .automatic
        #endif
    }

    // MARK: - Lists

    private var homeList: some View {
        List {
            listRow(.inbox)
            spacer
            listRow(.today)
            listRow(.upcoming)
            listRow(.anytime)
            listRow(.someday)
            spacer
            listRow(.logbook)
            spacer
            projectRows
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    /// The whole project tree, like the Mac sidebar: loose projects, then every Area with
    /// all its descendants (any depth), foldable. Fold state is `AppState.collapsedProjectIDs`.
    @ViewBuilder
    private var projectRows: some View {
        let tree = viewModel.tree
        let collapsed = viewModel.collapsedIDs
        ForEach(tree.looseProjects) { node in
            projectRow(node)
        }
        ForEach(tree.areas) { area in
            ForEach(tree.visibleSubtree(of: area, collapsed: collapsed)) { node in
                projectRow(node)
            }
        }
    }

    private var spacer: some View {
        Color.clear
            .frame(height: ThingsMetrics.Screen.homeGroupSpacing)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private func listRow(_ list: ThingsList) -> some View {
        let badge = viewModel.badge(for: list)
        return homeRow(route: .list(list)) {
            Image(systemName: ThingsIcons.symbol(for: list.kind))
                .font(.system(size: ThingsMetrics.Icon.list * 0.8))
                .foregroundStyle(palette[ThingsIcons.tint(for: list.kind)])
                .frame(width: ThingsMetrics.Icon.list)
                .accessibilityHidden(true)
            Text(verbatim: list.title)
                .font(ThingsTypography.sidebarRow)
                .foregroundStyle(palette[.textPrimary])
            Spacer(minLength: ThingsMetrics.Spacing.s)
            if let badge = badge {
                Text(verbatim: String(badge))
                    .font(ThingsTypography.counter)
                    .foregroundStyle(palette[.textSecondary])
            }
        }
    }

    private func projectRow(_ node: ThingsProjectNode) -> some View {
        let folded = viewModel.isFolded(node.id)
        return homeRow(
            route: .project(node.id),
            indent: CGFloat(node.depth) * ThingsMetrics.Spacing.l,
            fold: node.hasChildren ? FoldControl(id: node.id, isFolded: folded) : nil
        ) {
            if node.isArea {
                Image(systemName: ThingsIcons.area)
                    .font(.system(size: ThingsMetrics.Icon.list * 0.8))
                    .foregroundStyle(palette[.areaGray])
                    .frame(width: ThingsMetrics.Icon.list)
                    .accessibilityHidden(true)
            } else {
                ThingsProjectPie(progress: viewModel.progress(of: node))
                    .frame(width: ThingsMetrics.Icon.list)
            }
            Text(verbatim: node.title)
                .font(ThingsTypography.sidebarRow)
                .fontWeight(node.isArea ? .semibold : .regular)
                .foregroundStyle(node.isArea ? palette[.textSecondary] : palette[.textPrimary])
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    /// What the fold button of a row needs.
    private struct FoldControl {
        let id: Int64
        let isFolded: Bool
    }

    /// A tappable Home line. The invisible link keeps the disclosure chevron away.
    private func homeRow<Content: View>(
        route: ThingsRoute,
        indent: CGFloat = 0,
        fold: FoldControl? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            NavigationLink(value: route) { EmptyView() }
                .opacity(0)
            HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                content()
                if let fold = fold {
                    Button {
                        withAnimation(ThingsMotion.rowRemoval) { viewModel.toggleFold(fold.id) }
                    } label: {
                        Image(systemName: fold.isFolded ? "chevron.right" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(palette[.textSecondary])
                            .frame(width: ThingsMetrics.Icon.list, height: ThingsMetrics.Icon.homeRowHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(fold.isFolded ? String(localized: "Expand") : String(localized: "Collapse"))
                }
            }
            .padding(.leading, indent)
            .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
            .frame(minHeight: ThingsMetrics.Icon.homeRowHeight)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    // MARK: - Search

    private var searchResults: some View {
        List {
            ForEach(viewModel.search(query)) { row in
                ThingsTodoRow(model: row.model)
                    .contentShape(Rectangle())
                    .onTapGesture { detailTask = row.task }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - New list

    private func startCreating(_ kind: NewListKind) {
        newTitle = ""
        creating = kind
    }

    private func commitCreate() {
        let title = newTitle
        let kind = creating
        let model = viewModel
        Task {
            if kind == .area {
                await model.createArea(title: title)
            } else {
                await model.createProject(title: title)
            }
        }
    }
}
