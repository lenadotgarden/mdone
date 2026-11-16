import SwiftUI

#if os(macOS)
import AppKit

/// Sidebar look, from the Things reference screenshots (mac-dark-01 to 05).
/// Values without a DesignSystem token live here until a token exists, see
/// docs/things-spec/WIRING-AGENT1.md.
private enum ThingsSidebarStyle {
    /// Highlight of the selected row: the primary text color at low opacity,
    /// close to #3b3e42 on the dark sidebar.
    static let selectionOpacity: Double = 0.12
    /// Gap between the groups (lists, loose projects, each Area).
    static let groupGap: CGFloat = ThingsMetrics.Spacing.l
    /// Corner radius of the highlight.
    static let highlightRadius: CGFloat = 6
    /// Extra indent per tree level below the first project level.
    static let levelIndent: CGFloat = ThingsMetrics.Spacing.l
    static let chevronWidth: CGFloat = 10
    /// Chevron opacity when the pointer is elsewhere: visible, so the tree is discoverable.
    static let chevronRestingOpacity: Double = 0.55

    /// The built-in lists in their three visual groups.
    static let listGroups: [[ThingsList]] = [
        [ThingsList.inbox],
        [ThingsList.today, ThingsList.upcoming, ThingsList.anytime, ThingsList.someday],
        [ThingsList.logbook]
    ]
}

/// The sidebar of the Mac window (spec 04 section 1): Inbox, then the four
/// time lists, then Logbook, then loose projects, then every Area with its
/// whole subtree (projects, sub-projects, any depth, foldable), and a New
/// List button at the bottom. Drag a to-do or a project onto a row to move it.
struct ThingsMacSidebar: View {
    let model: ThingsMacModel

    @State private var hovered: String?
    @State private var dropTarget: String?
    @State private var projectDrop: ThingsProjectDropState?
    @State private var rowHeights = ThingsRowHeightStore()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        let tree = model.projectTree
        // Fold state is persisted by AppState (absent = expanded), so every level is open
        // by default and the choice survives a relaunch.
        let collapsed = model.appState.collapsedProjectIDs
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<ThingsSidebarStyle.listGroups.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(ThingsSidebarStyle.listGroups[index]) { list in
                            listRow(list)
                        }
                    }
                    .padding(.bottom, ThingsSidebarStyle.groupGap)
                }
                ForEach(tree.looseProjects) { node in
                    nodeRow(node, collapsed: collapsed)
                }
                ForEach(tree.areas) { area in
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(tree.visibleSubtree(of: area, collapsed: collapsed)) { node in
                            nodeRow(node, collapsed: collapsed)
                        }
                    }
                    .padding(.top, ThingsSidebarStyle.groupGap)
                }
            }
            .padding(.horizontal, ThingsMetrics.Spacing.s)
            .padding(.vertical, ThingsMetrics.Spacing.s)
        }
        .background(palette[.bgSidebar])
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.upArrow) { moveRoute(by: -1, tree: tree, collapsed: collapsed) }
        .onKeyPress(.downArrow) { moveRoute(by: 1, tree: tree, collapsed: collapsed) }
        .onChange(of: model.route) { _, newRoute in revealRoute(newRoute, tree: tree) }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }

    // MARK: - Rows

    /// Counters on Inbox and Today only, hidden at zero (spec 02 section 1).
    private func listRow(_ list: ThingsList) -> some View {
        let listModel = model.viewModel(for: list)
        let count = (list == .inbox || list == .today) ? listModel.count(for: list) : 0
        let kind = list.kind
        let shortcut = ThingsShortcutTable.chord(for: ThingsShortcutTable.goCommand(for: list))
        return shell(
            route: .list(list), key: "list-" + list.rawValue, indent: 0, foldID: nil,
            movableProject: nil,
            target: .list(list),
            dragPayload: nil,
            allowsAfterDrop: false
        ) {
            Image(systemName: ThingsIcons.symbol(for: kind))
                .foregroundStyle(palette[ThingsIcons.tint(for: kind)])
                .frame(width: ThingsMetrics.Icon.list)
            Text(verbatim: list.title)
                .font(ThingsTypography.sidebarRow)
                .lineLimit(1)
            Spacer(minLength: 0)
            if count > 0 {
                Text(verbatim: String(count))
                    .font(ThingsTypography.counter)
                    .foregroundStyle(palette[.textSecondary])
            }
        }
        .help(shortcut?.display ?? "")
    }

    /// An Area (bold, box icon) or a project (progress pie, regular weight).
    /// Projects directly under an Area are not indented, like in Things;
    /// deeper levels indent one step each.
    private func nodeRow(_ node: ThingsProjectNode, collapsed: Set<Int64>) -> some View {
        let indent = CGFloat(max(node.depth - 1, 0)) * ThingsSidebarStyle.levelIndent
        let progress = node.isArea ? 0 : model.viewModel(for: .anytime).progress(ofProject: node.id)
        return shell(
            route: .project(node.id), key: "project-\(node.id)", indent: indent,
            foldID: node.hasChildren ? node.id : nil,
            movableProject: node.project,
            target: .project(node.id),
            dragPayload: .project(node.id),
            allowsAfterDrop: !(node.hasChildren && !collapsed.contains(node.id))
        ) {
            if node.isArea {
                Image(systemName: ThingsIcons.area)
                    .foregroundStyle(palette[.areaGray])
                    .frame(width: ThingsMetrics.Icon.list)
                Text(verbatim: node.title)
                    .font(ThingsTypography.sidebarRow.weight(.bold))
                    .lineLimit(1)
            } else {
                ThingsProjectPie(progress: progress)
                    .frame(width: ThingsMetrics.Icon.list)
                Text(verbatim: node.title)
                    .font(ThingsTypography.sidebarRow)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contextMenu {
            Button(String(localized: "Move Project...")) { model.projectMoveRequest = node.id }
            if node.hasChildren {
                Button(collapsed.contains(node.id) ? String(localized: "Expand") : String(localized: "Collapse")) {
                    model.appState.toggleProjectFold(node.id)
                }
            }
        }
    }

    /// Common chrome of every row: highlight, hover chevron, tap to open,
    /// drop target and (for projects) the Move popover.
    private func shell<Content: View>(
        route: ThingsRoute,
        key: String,
        indent: CGFloat,
        foldID: Int64?,
        movableProject: Project?,
        target: ThingsDropTarget,
        dragPayload: ThingsDragPayload?,
        allowsAfterDrop: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isSelected = model.route == route
        let isDropTarget = dropTarget == key
        let selectedFill: Color = palette[.textPrimary].opacity(ThingsSidebarStyle.selectionOpacity)
        let isIntoProject = projectDrop?.key == key && projectDrop?.zone == .into
        let fill: Color = (isDropTarget || isIntoProject) ? palette[.selectionRow] : (isSelected ? selectedFill : Color.clear)
        return HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
            content()
        }
        .padding(.leading, ThingsMetrics.Spacing.m + indent)
        .padding(.trailing, ThingsMetrics.Spacing.s)
        .padding(.vertical, ThingsMetrics.Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: ThingsSidebarStyle.highlightRadius).fill(fill))
        .overlay(alignment: .leading) {
            if let foldID = foldID {
                chevron(foldID: foldID, emphasized: hovered == key)
                    .padding(.leading, indent)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { model.navigate(to: route) }
        .onHover { inside in
            if inside {
                hovered = key
            } else if hovered == key {
                hovered = nil
            }
        }
        .animation(ThingsMotion.resolved(ThingsMotion.dropTargetHighlight, reduceMotion: reduceMotion), value: isDropTarget)
        .modifier(ThingsRowHeightReader(store: rowHeights, key: key))
        .modifier(ThingsProjectDropFeedback(state: projectDrop, key: key, palette: palette, reduceMotion: reduceMotion))
        .modifier(ThingsSidebarDragSource(payload: dragPayload))
        .modifier(rowDrop(key: key, target: target, allowsAfter: allowsAfterDrop))
        .popover(isPresented: moveBinding(for: movableProject), arrowEdge: .trailing) {
            if let project = movableProject {
                ThingsMacProjectMovePopover(project: project, model: model, onClose: { model.projectMoveRequest = nil })
            }
        }
        .accessibilityAddTraits(.isButton)
    }

    /// Lists keep the plain drop rule. A project or Area row also takes a project dropped on
    /// its top or bottom edge (sibling order) or its middle (becomes its child).
    private func rowDrop(key: String, target: ThingsDropTarget, allowsAfter: Bool) -> RowDrop {
        switch target {
        case .list:
            return RowDrop(
                projectDelegate: nil,
                listDelegate: ThingsSidebarDropDelegate(
                    targeted: $dropTarget,
                    key: key,
                    accepts: { acceptsDrop(on: target) },
                    perform: { payload in model.handleDrop(payload, on: target) }
                )
            )
        case .project(let targetID):
            return RowDrop(
                projectDelegate: ThingsProjectRowDropDelegate(
                    key: key,
                    state: $projectDrop,
                    rowHeight: { rowHeights.heights[key] ?? 0 },
                    allowsAfter: allowsAfter,
                    resolve: { payload, zone in model.projectDropZone(for: payload, on: targetID, asked: zone) },
                    perform: { payload, zone in model.handleProjectRowDrop(payload, on: targetID, zone: zone) }
                ),
                listDelegate: nil
            )
        }
    }

    /// Whether the payload being dragged may be dropped on `target`: the highlight shows
    /// only then.
    private func acceptsDrop(on target: ThingsDropTarget) -> Bool {
        guard let payload = ThingsDragSession.shared.payload else { return false }
        return model.dropAction(for: payload, on: target) != nil
    }

    /// Disclosure chevron of a row with children. Always visible, a little stronger on hover.
    private func chevron(foldID: Int64, emphasized: Bool) -> some View {
        let isCollapsed = model.appState.collapsedProjectIDs.contains(foldID)
        return Button {
            if NSEvent.modifierFlags.contains(.command) {
                model.appState.setAllProjectsExpanded(isCollapsed, tree: model.projectTree)
            } else {
                model.appState.toggleProjectFold(foldID)
            }
        } label: {
            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .frame(width: ThingsSidebarStyle.chevronWidth, height: ThingsMetrics.Icon.list)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette[.textSecondary])
        .opacity(emphasized ? 1 : ThingsSidebarStyle.chevronRestingOpacity)
    }

    private func moveBinding(for project: Project?) -> Binding<Bool> {
        Binding(
            get: {
                guard let project = project else { return false }
                return model.projectMoveRequest == project.id
            },
            set: { shown in
                if !shown, let project = project, model.projectMoveRequest == project.id {
                    model.projectMoveRequest = nil
                }
            }
        )
    }

    // MARK: - Keyboard

    /// Up and Down in the sidebar open the previous or next row.
    private func moveRoute(by step: Int, tree: ThingsProjectTree, collapsed: Set<Int64>) -> KeyPress.Result {
        var routes: [ThingsRoute] = ThingsList.allCases.map { ThingsRoute.list($0) }
        for node in tree.visibleNodes(collapsed: collapsed) { routes.append(.project(node.id)) }
        guard let index = routes.firstIndex(of: model.route) else { return .ignored }
        let next = index + step
        if next < 0 || next >= routes.count { return .handled }
        model.navigate(to: routes[next])
        return .handled
    }

    /// Unfolds the ancestors of a project that was just opened (from the Area screen, Quick
    /// Find or a drop), so its row is not hidden under a folded parent.
    private func revealRoute(_ route: ThingsRoute, tree: ThingsProjectTree) {
        guard case .project(let id) = route else { return }
        for ancestor in tree.ancestorIDs(of: id) where !model.appState.isProjectExpanded(ancestor) {
            model.appState.setProjectExpanded(true, for: ancestor)
        }
    }

    // MARK: - Bottom bar

    /// New List on the left, a folding menu (stand-in for the tag filter) on the right.
    private var bottomBar: some View {
        HStack {
            Menu {
                Button(String(localized: "New Project")) { model.sheet = .newProject }
                Button(String(localized: "New Area")) { model.sheet = .newArea }
            } label: {
                Label(String(localized: "New List"), systemImage: ThingsIcons.add)
                    .font(ThingsTypography.sidebarRow)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            Spacer(minLength: 0)
            Menu {
                Button(String(localized: "Expand All")) {
                    model.appState.setAllProjectsExpanded(true, tree: model.projectTree)
                }
                Button(String(localized: "Collapse All")) {
                    model.appState.setAllProjectsExpanded(false, tree: model.projectTree)
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .foregroundStyle(palette[.textSecondary])
        .padding(.horizontal, ThingsMetrics.Spacing.m)
        .padding(.vertical, ThingsMetrics.Spacing.s)
        .background(palette[.bgSidebar])
    }
}

/// The drop modifier of a row: a project row or a list row, whichever delegate applies.
private struct RowDrop: ViewModifier {
    let projectDelegate: ThingsProjectRowDropDelegate?
    let listDelegate: ThingsSidebarDropDelegate?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let projectDelegate = projectDelegate {
            content.onDrop(of: ThingsDragItem.contentTypes, delegate: projectDelegate)
        } else if let listDelegate = listDelegate {
            content.onDrop(of: ThingsDragItem.contentTypes, delegate: listDelegate)
        } else {
            content
        }
    }
}

#endif
