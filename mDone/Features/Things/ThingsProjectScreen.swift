import SwiftUI

/// A project or an Area (spec 02 sections 9 and 10), first version: the sub-projects at
/// the top (nested, foldable, same tree as the Mac sidebar), then a flat list of the open
/// to-dos, with the progress pie for a project. Headings are a TODO
/// (docs/things-spec/DEVIATIONS.md).
struct ThingsProjectScreen: View {
    @State private var viewModel: ThingsListViewModel
    private let projectID: Int64
    private let appState: AppState

    @State private var detailTask: VTask?
    @State private var whenTask: VTask?
    @State private var isAdding = false

    @Environment(\.colorScheme) private var scheme

    /// - Parameter viewModel: any list view model, used for its actions and progress.
    init(projectID: Int64, appState: AppState) {
        self.projectID = projectID
        self.appState = appState
        _viewModel = State(initialValue: ThingsListViewModel(list: .anytime, appState: appState))
    }

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    private var project: Project? {
        appState.projects.first { $0.id == projectID }
    }

    private var tree: ThingsProjectTree {
        ThingsProjectTree.build(projects: appState.projects, inboxProjectID: viewModel.inboxProjectID)
    }

    /// An Area is any root with sub-projects (or the marker), whatever its description says.
    private var isArea: Bool {
        if let node = tree.node(id: projectID) { return node.isArea }
        guard let project = project else { return false }
        return ThingsProjectMeta.isArea(project)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
            #if os(iOS)
            ThingsMagicPlusButton { isAdding = true }
                .padding(ThingsMetrics.MagicPlus.edgeMargin)
            #endif
        }
        .background(palette[.bgPrimary])
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $detailTask) { task in
            TaskDetailSheet(task: task)
        }
        .thingsWhenDialog(task: $whenTask, viewModel: viewModel)
    }

    private var header: some View {
        let title = project?.title ?? String(localized: "Project")
        return Group {
            if isArea {
                ThingsListHeader(title: title, kind: .area)
            } else {
                ThingsListHeader(
                    title: title,
                    symbolName: ThingsIcons.project,
                    tint: .accent,
                    progress: viewModel.progress(ofProject: projectID)
                )
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var content: some View {
        let rows = viewModel.projectRows(projectID: projectID)
        return List {
            header
            if isAdding {
                ThingsInlineAddRow { title in
                    isAdding = false
                    if title.isEmpty { return }
                    let model = viewModel
                    let id = projectID
                    Task { await model.quickAdd(title: title, inProject: id) }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            ForEach(tree.descendantRows(of: projectID, collapsed: appState.collapsedProjectIDs)) { row in
                childRow(row)
            }
            ForEach(rows) { row in
                ThingsRowCell(
                    row: row,
                    viewModel: viewModel,
                    onOpen: { task in detailTask = task },
                    onWhen: { task in whenTask = task }
                )
            }
            Color.clear
                .frame(height: ThingsMetrics.Screen.listBottomClearance)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
        .animation(ThingsMotion.rowRemoval, value: rows.map { $0.id })
    }

    /// A sub-project line: fold chevron, pie, bold title and the open to-do count. Nested
    /// levels indent one step each.
    private func childRow(_ row: ThingsProjectRow) -> some View {
        let node = row.node
        let folded = !appState.isProjectExpanded(node.id)
        let openCount = appState.tasksForProject(node.id).filter { !$0.done }.count
        return ZStack {
            NavigationLink(value: ThingsRoute.project(node.id)) { EmptyView() }
                .opacity(0)
            HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                ThingsProjectPie(progress: viewModel.progress(ofProject: node.id))
                Text(verbatim: node.title)
                    .font(ThingsTypography.sidebarRow.weight(.semibold))
                    .foregroundStyle(palette[.textPrimary])
                    .lineLimit(1)
                if openCount > 0 {
                    Text(verbatim: String(openCount))
                        .font(ThingsTypography.datePill)
                        .foregroundStyle(palette[.textSecondary])
                }
                Spacer(minLength: 0)
                if node.hasChildren {
                    Button {
                        withAnimation(ThingsMotion.rowRemoval) { appState.toggleProjectFold(node.id) }
                    } label: {
                        Image(systemName: folded ? "chevron.right" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(palette[.textSecondary])
                            .frame(width: ThingsMetrics.Icon.list, height: ThingsMetrics.Icon.homeRowHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(folded ? String(localized: "Expand") : String(localized: "Collapse"))
                }
            }
            .padding(.leading, CGFloat(row.depth) * ThingsMetrics.Spacing.l)
            .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
            .frame(minHeight: ThingsMetrics.Icon.homeRowHeight)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
