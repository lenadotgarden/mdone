import SwiftUI

#if os(macOS)

/// A built-in Things list in the detail pane (spec 04 section 2): the same
/// view model and header as the iPhone screen, with the Mac list underneath.
struct ThingsMacListScreen: View {
    let list: ThingsList
    let model: ThingsMacModel

    var body: some View {
        let listModel = model.viewModel(for: list)
        let sections = listModel.displaySections.map { section in
            ThingsMacSectionData(id: section.id, header: listModel.headerStyle(for: section), rows: section.rows)
        }
        let empty = ThingsEmptyState(
            symbolName: ThingsIcons.symbol(for: list.kind),
            title: list.emptyTitle,
            message: list.emptyMessage,
            tint: ThingsIcons.tint(for: list.kind)
        )
        .frame(height: ThingsMetrics.Screen.emptyStateHeight)
        return ThingsMacTodoList(
            sections: sections,
            viewModel: listModel,
            model: model,
            header: AnyView(ThingsListHeader(title: list.title, kind: list.kind)),
            empty: AnyView(empty),
            trailing: nil
        )
    }
}

/// A project or an Area in the detail pane (spec 02 sections 9 and 10): its
/// open to-dos, then for an Area its projects. Headings are a TODO (DEVIATIONS.md).
struct ThingsMacProjectScreen: View {
    let projectID: Int64
    let model: ThingsMacModel

    @Environment(\.colorScheme) private var scheme

    private var project: Project? {
        model.appState.projects.first { $0.id == projectID }
    }

    private var isArea: Bool {
        guard let project = project else { return false }
        return ThingsProjectMeta.isArea(project)
    }

    var body: some View {
        let listModel = model.viewModel(for: .anytime)
        let rows = listModel.projectRows(projectID: projectID)
        let sections = [ThingsMacSectionData(id: "project.\(projectID)", header: nil, rows: rows)]
        return ThingsMacTodoList(
            sections: sections,
            viewModel: listModel,
            model: model,
            header: AnyView(header(listModel)),
            empty: nil,
            trailing: isArea ? AnyView(children(listModel)) : nil
        )
    }

    @ViewBuilder
    private func header(_ listModel: ThingsListViewModel) -> some View {
        let title = project?.title ?? String(localized: "Project")
        if isArea {
            ThingsListHeader(title: title, kind: .area)
        } else {
            ThingsListHeader(
                title: title,
                symbolName: ThingsIcons.project,
                tint: .accent,
                progress: listModel.progress(ofProject: projectID)
            )
        }
    }

    private func children(_ listModel: ThingsListViewModel) -> some View {
        let palette = ThingsPalette(scheme)
        let kids = ThingsProjectMeta.children(of: projectID, in: model.appState.projects)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(kids) { child in
                Button {
                    model.navigate(to: .project(child.id))
                } label: {
                    HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                        ThingsProjectPie(progress: listModel.progress(ofProject: child.id))
                        Text(verbatim: child.title)
                            .font(ThingsTypography.sidebarRow)
                            .foregroundStyle(palette[.textPrimary])
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin)
                    .frame(minHeight: ThingsMetrics.Row.minHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#endif
