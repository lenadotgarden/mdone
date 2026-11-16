import SwiftUI

#if os(macOS)

/// Sizes of the sub-project list that no DesignSystem token covers yet (see
/// docs/things-spec/WIRING-AGENT-C2.md for the suggested tokens).
private enum ThingsSubprojectStyle {
    /// Extra indent per nesting level.
    static let levelIndent: CGFloat = 20
    /// Width reserved for the fold chevron, so pies line up with and without children.
    static let chevronWidth: CGFloat = 12
    static let badgeRadius: CGFloat = 3
    static let badgeHorizontalPadding: CGFloat = 4
    static let highlightRadius: CGFloat = 6
}

/// The sub-projects of an Area or project, at the top of its screen (spec 02 section 9,
/// mac-dark-03.png): one row per project with the progress pie, the bold title and a small
/// badge with the open to-do count. Nested projects are indented and foldable, the fold state
/// is shared with the sidebar (`AppState.collapsedProjectIDs`). A click opens the project.
/// Rows are drag sources and drop targets like the sidebar rows: drop a project on the middle
/// of a row to nest it, on an edge to reorder.
struct ThingsMacSubprojectList: View {
    let parentID: Int64
    let model: ThingsMacModel
    let listModel: ThingsListViewModel

    @State private var projectDrop: ThingsProjectDropState?
    @State private var rowHeights = ThingsRowHeightStore()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let tree = model.projectTree
        let collapsed = model.appState.collapsedProjectIDs
        let rows = tree.descendantRows(of: parentID, collapsed: collapsed)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(rows) { row in
                line(row, collapsed: collapsed)
            }
        }
        .padding(.bottom, rows.isEmpty ? 0 : ThingsMetrics.Spacing.s)
    }

    private func line(_ row: ThingsProjectRow, collapsed: Set<Int64>) -> some View {
        let palette = ThingsPalette(scheme)
        let node = row.node
        let key = "sub-\(node.id)"
        let isFolded = collapsed.contains(node.id)
        let isInto = projectDrop?.key == key && projectDrop?.zone == .into
        let openCount = model.appState.tasksForProject(node.id).filter { !$0.done }.count
        return HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            chevron(for: node, isFolded: isFolded, palette: palette)
            ThingsProjectPie(
                progress: listModel.progress(ofProject: node.id),
                size: ThingsMetrics.Checkbox.size + 4
            )
            Text(verbatim: node.title)
                .font(ThingsTypography.todoTitle.weight(.semibold))
                .foregroundStyle(palette[.textPrimary])
                .lineLimit(1)
            if openCount > 0 {
                Text(verbatim: String(openCount))
                    .font(ThingsTypography.datePill)
                    .foregroundStyle(palette[.textSecondary])
                    .padding(.horizontal, ThingsSubprojectStyle.badgeHorizontalPadding)
                    .overlay(
                        RoundedRectangle(cornerRadius: ThingsSubprojectStyle.badgeRadius, style: .continuous)
                            .strokeBorder(palette[.tagPillBorder], lineWidth: ThingsMetrics.Chip.tagBorderWidth)
                    )
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, ThingsMetrics.Layout.listHorizontalMargin - 2 + CGFloat(row.depth) * ThingsSubprojectStyle.levelIndent)
        .padding(.trailing, ThingsMetrics.Layout.listHorizontalMargin)
        .frame(minHeight: ThingsMetrics.Row.minHeight)
        .background(
            RoundedRectangle(cornerRadius: ThingsSubprojectStyle.highlightRadius)
                .fill(isInto ? palette[.selectionRow] : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { model.navigate(to: .project(node.id)) }
        .modifier(ThingsRowHeightReader(store: rowHeights, key: key))
        .modifier(ThingsProjectDropFeedback(state: projectDrop, key: key, palette: palette, reduceMotion: reduceMotion))
        .modifier(ThingsSidebarDragSource(payload: .project(node.id)))
        .onDrop(of: ThingsDragItem.contentTypes, delegate: ThingsProjectRowDropDelegate(
            key: key,
            state: $projectDrop,
            rowHeight: { rowHeights.heights[key] ?? 0 },
            allowsAfter: !(node.hasChildren && !isFolded),
            resolve: { payload, zone in model.projectDropZone(for: payload, on: node.id, asked: zone) },
            perform: { payload, zone in model.handleProjectRowDrop(payload, on: node.id, zone: zone) }
        ))
        .popover(isPresented: moveBinding(for: node.id), arrowEdge: .bottom) {
            ThingsMacProjectMovePopover(project: node.project, model: model, onClose: { model.projectMoveRequest = nil })
        }
        .contextMenu {
            Button(String(localized: "Move Project...")) { model.projectMoveRequest = node.id }
            if node.hasChildren {
                Button(isFolded ? String(localized: "Expand") : String(localized: "Collapse")) {
                    model.appState.toggleProjectFold(node.id)
                }
            }
        }
        .accessibilityAddTraits(.isButton)
    }

    /// The fold chevron of a row with children, an empty slot of the same width otherwise.
    @ViewBuilder
    private func chevron(for node: ThingsProjectNode, isFolded: Bool, palette: ThingsPalette) -> some View {
        if node.hasChildren {
            Button {
                model.appState.toggleProjectFold(node.id)
            } label: {
                Image(systemName: isFolded ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(palette[.textSecondary])
                    .frame(width: ThingsSubprojectStyle.chevronWidth, height: ThingsMetrics.Icon.list)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(width: ThingsSubprojectStyle.chevronWidth, height: ThingsMetrics.Icon.list)
        }
    }

    /// The Move popover opens here only while the sidebar is hidden; with the sidebar visible
    /// the sidebar row owns it (one popover per request).
    private func moveBinding(for id: Int64) -> Binding<Bool> {
        Binding(
            get: { model.projectMoveRequest == id && model.sidebarVisibility == .detailOnly },
            set: { shown in
                if !shown, model.projectMoveRequest == id { model.projectMoveRequest = nil }
            }
        )
    }
}

#endif
