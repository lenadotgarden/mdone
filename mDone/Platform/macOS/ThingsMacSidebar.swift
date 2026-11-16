import SwiftUI

#if os(macOS)

/// The sidebar of the Mac window (spec 04 section 1): the six lists with
/// counters, a separator, loose projects, then Areas with their projects, and
/// a New List button at the bottom. Dragging to-dos onto a row is a TODO.
struct ThingsMacSidebar: View {
    let model: ThingsMacModel

    @State private var collapsedAreas: Set<Int64> = []
    @Environment(\.colorScheme) private var scheme

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    private var selection: Binding<ThingsRoute?> {
        Binding(
            get: { model.route },
            set: { newValue in
                if let route = newValue { model.navigate(to: route) }
            }
        )
    }

    var body: some View {
        List(selection: selection) {
            Section {
                ForEach(ThingsList.allCases) { list in
                    listRow(list)
                }
            }
            Section {
                ForEach(model.home.looseProjects) { entry in
                    projectRow(entry, indented: false)
                }
                ForEach(model.home.areas) { area in
                    areaRows(area)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) { newListButton }
    }

    // MARK: - Rows

    /// Counters on Inbox and Today only, hidden at zero (spec 02 section 1).
    private func listRow(_ list: ThingsList) -> some View {
        let listModel = model.viewModel(for: list)
        let count = (list == .inbox || list == .today) ? listModel.count(for: list) : 0
        let kind = list.kind
        let shortcut = ThingsShortcutTable.chord(for: ThingsShortcutTable.goCommand(for: list))
        return HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            Image(systemName: ThingsIcons.symbol(for: kind))
                .foregroundStyle(palette[ThingsIcons.tint(for: kind)])
                .frame(width: ThingsMetrics.Icon.list)
            Text(verbatim: list.title)
                .font(ThingsTypography.sidebarRow)
            Spacer(minLength: 0)
            if count > 0 {
                Text(verbatim: String(count))
                    .font(ThingsTypography.counter)
                    .foregroundStyle(palette[.textSecondary])
            }
        }
        .tag(ThingsRoute.list(list))
        .help(shortcut?.display ?? "")
    }

    private func projectRow(_ entry: ThingsHomeProject, indented: Bool) -> some View {
        HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            ThingsProjectPie(progress: entry.progress)
            Text(verbatim: entry.project.title)
                .font(ThingsTypography.sidebarRow)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.leading, indented ? ThingsMetrics.Spacing.l : 0)
        .tag(ThingsRoute.project(entry.id))
    }

    @ViewBuilder
    private func areaRows(_ area: ThingsHomeProject) -> some View {
        let isCollapsed = collapsedAreas.contains(area.id)
        HStack(spacing: ThingsMetrics.Spacing.xs) {
            Button {
                toggleCollapsed(area.id)
            } label: {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 12)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette[.textSecondary])
            Image(systemName: ThingsIcons.area)
                .foregroundStyle(palette[.areaGray])
            Text(verbatim: area.project.title)
                .font(ThingsTypography.sidebarRow)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .tag(ThingsRoute.project(area.id))
        if !isCollapsed {
            ForEach(area.children) { child in
                projectRow(child, indented: true)
            }
        }
    }

    private func toggleCollapsed(_ id: Int64) {
        if collapsedAreas.contains(id) {
            collapsedAreas.remove(id)
        } else {
            collapsedAreas.insert(id)
        }
    }

    // MARK: - New List

    private var newListButton: some View {
        HStack {
            Menu {
                Button(String(localized: "New Project")) { model.sheet = .newProject }
                Button(String(localized: "New Area")) { model.sheet = .newArea }
            } label: {
                Label(String(localized: "New List"), systemImage: ThingsIcons.add)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ThingsMetrics.Spacing.m)
        .padding(.vertical, ThingsMetrics.Spacing.s)
        .background(.regularMaterial)
    }
}

#endif
