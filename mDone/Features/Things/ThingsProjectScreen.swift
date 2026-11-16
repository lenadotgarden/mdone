import SwiftUI

/// A project or an Area (spec 02 sections 9 and 10), first version: a flat list
/// of the open to-dos, with the progress pie for a project and, for an Area,
/// links to its projects. Headings are a TODO (docs/things-spec/DEVIATIONS.md).
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

    private var isArea: Bool {
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
            ForEach(rows) { row in
                ThingsRowCell(
                    row: row,
                    viewModel: viewModel,
                    onOpen: { task in detailTask = task },
                    onWhen: { task in whenTask = task }
                )
            }
            if isArea {
                ForEach(ThingsProjectMeta.children(of: projectID, in: appState.projects)) { child in
                    childRow(child)
                }
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

    private func childRow(_ child: Project) -> some View {
        ZStack {
            NavigationLink(value: ThingsRoute.project(child.id)) { EmptyView() }
                .opacity(0)
            HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                ThingsProjectPie(progress: viewModel.progress(ofProject: child.id))
                Text(verbatim: child.title)
                    .font(ThingsTypography.sidebarRow)
                    .foregroundStyle(palette[.textPrimary])
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
            .frame(minHeight: ThingsMetrics.Icon.homeRowHeight)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
