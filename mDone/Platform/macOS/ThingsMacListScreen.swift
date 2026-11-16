import SwiftUI

#if os(macOS)
import EventKit

/// Calendar events of today for the box above the Today list (spec 04 section 2,
/// mac-dark-01.png). Reads EventKit only when access was already granted, so opening
/// Today never shows a permission prompt; with no access the box is not shown.
private enum ThingsTodayEvents {
    static func load() async -> [ThingsCalendarEventLine] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }
        let service = CalendarService()
        let events = await service.eventsForDate(Date())
        return events.map { event in
            ThingsCalendarEventLine(id: event.id, title: event.title, barHex: hex(of: event.calendarColor))
        }
    }

    private static func hex(of color: CGColor?) -> UInt32? {
        guard let color = color,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = color.converted(to: space, intent: .defaultIntent, options: nil),
              let parts = converted.components,
              parts.count >= 3 else { return nil }
        func byte(_ value: CGFloat) -> UInt32 {
            UInt32(max(0, min(255, (value * 255).rounded())))
        }
        return (byte(parts[0]) << 16) | (byte(parts[1]) << 8) | byte(parts[2])
    }
}

/// A built-in Things list in the detail pane (spec 04 section 2): the same
/// view model and header as the iPhone screen, with the Mac list underneath.
/// Today also shows the calendar events box, and any list whose to-dos carry tags
/// shows the filter bar ("All", one chip per tag).
struct ThingsMacListScreen: View {
    let list: ThingsList
    let model: ThingsMacModel

    @State private var filterTag: String?
    @State private var events: [ThingsCalendarEventLine] = []

    var body: some View {
        let listModel = model.viewModel(for: list)
        let all = listModel.displaySections.map { section in
            ThingsMacSectionData(
                id: section.id,
                header: listModel.headerStyle(for: section),
                rows: ThingsRowMapper.applyingProjectLine(
                    to: section.rows,
                    projects: model.appState.projects,
                    inboxProjectID: listModel.inboxProjectID
                )
            )
        }
        let tags = uniqueTags(in: all)
        let active: String? = {
            guard let tag = filterTag, tags.contains(tag) else { return nil }
            return tag
        }()
        let sections = filtered(all, tag: active)
        let showsEvents = list == .today && !events.isEmpty
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
            header: AnyView(header(showsEvents: showsEvents, tags: tags, active: active)),
            empty: AnyView(empty),
            trailing: nil
        )
        .onAppear { model.home.parentForNewProject = nil }
        .task(id: list) {
            if list == .today {
                events = await ThingsTodayEvents.load()
            } else {
                events = []
            }
        }
    }

    // MARK: - Header

    private func header(showsEvents: Bool, tags: [String], active: String?) -> some View {
        let hasBar = !tags.isEmpty
        let titleGap: CGFloat = showsEvents
            ? ThingsMetrics.Header.calendarBoxTopGap
            : (hasBar ? ThingsMetrics.CalendarBox.bottomGap : ThingsMetrics.Header.bottomPadding)
        return VStack(alignment: .leading, spacing: 0) {
            ThingsListHeader(title: list.title, kind: list.kind, bottomPadding: titleGap)
            if showsEvents {
                ThingsCalendarEventsBox(lines: events)
                    .padding(.bottom, hasBar ? ThingsMetrics.CalendarBox.bottomGap : ThingsMetrics.Header.bottomPadding)
            }
            if hasBar {
                ThingsFilterBar(tags: tags, selection: active) { tag in
                    withAnimation(ThingsMotion.rowRemoval) { filterTag = tag }
                }
                .padding(.bottom, ThingsMetrics.Header.filterBarBottomGap)
            }
        }
    }

    // MARK: - Filter

    private func uniqueTags(in sections: [ThingsMacSectionData]) -> [String] {
        var seen: [String] = []
        for section in sections {
            for row in section.rows {
                for tag in row.model.tags where !seen.contains(tag) {
                    seen.append(tag)
                }
            }
        }
        return seen
    }

    private func filtered(_ sections: [ThingsMacSectionData], tag: String?) -> [ThingsMacSectionData] {
        guard let tag = tag else { return sections }
        return sections.compactMap { section in
            let rows = section.rows.filter { $0.model.tags.contains(tag) }
            if rows.isEmpty { return nil }
            return ThingsMacSectionData(
                id: section.id,
                header: section.header,
                rows: rows,
                allowsReorder: section.allowsReorder
            )
        }
    }
}

/// A project or an Area in the detail pane (spec 02 sections 9 and 10, mac-dark-03.png):
/// its sub-projects at the top (nested, foldable, see `ThingsMacSubprojectList`), its open
/// to-dos, then the "Upcoming" and "Someday" groups with their icon and rule, then
/// "Hide later items" and "Show N logged items".
/// Headings are a TODO (DEVIATIONS.md).
struct ThingsMacProjectScreen: View {
    let projectID: Int64
    let model: ThingsMacModel

    @State private var showsLater = true
    @State private var showsLogged = false
    @Environment(\.colorScheme) private var scheme

    private var project: Project? {
        model.appState.projects.first { $0.id == projectID }
    }

    /// The project in the tree: an Area is any root with sub-projects (or the marker),
    /// whatever its description says.
    private var node: ThingsProjectNode? {
        model.projectTree.node(id: projectID)
    }

    private var isArea: Bool {
        if let node = node { return node.isArea }
        guard let project = project else { return false }
        return ThingsProjectMeta.isArea(project)
    }

    /// Whether the screen lists sub-projects at the top (any project with children).
    private var hasSubprojects: Bool {
        node?.hasChildren ?? false
    }

    /// Sections and counts of the screen, computed outside `body` (it uses loops).
    private struct ScreenData {
        var sections: [ThingsMacSectionData]
        var hasLater: Bool
        var loggedCount: Int
    }

    private func buildData(_ listModel: ThingsListViewModel) -> ScreenData {
        let calendar = Calendar.current
        let now = Date()
        let rows = ThingsRowMapper.applyingProjectLine(
            to: listModel.projectRows(projectID: projectID),
            projects: model.appState.projects,
            inboxProjectID: listModel.inboxProjectID,
            hiddenProjectID: projectID
        )
        var main: [ThingsDisplayRow] = []
        var upcoming: [ThingsDisplayRow] = []
        var someday: [ThingsDisplayRow] = []
        for row in rows {
            switch ThingsWhen.resolve(task: row.task, now: now, calendar: calendar) {
            case .someday: someday.append(row)
            case .date: upcoming.append(row)
            default: main.append(row)
            }
        }
        upcoming = ThingsRowMapper.applyingDatePills(to: upcoming, now: now, calendar: calendar)
        let logged = loggedRows(now: now, calendar: calendar)
        let hasLater = !upcoming.isEmpty || !someday.isEmpty

        var sections = [ThingsMacSectionData(id: ThingsSectionID.project(projectID), header: nil, rows: main)]
        if showsLater {
            if !upcoming.isEmpty {
                sections.append(ThingsMacSectionData(
                    id: ThingsSectionID.projectUpcoming(projectID),
                    header: .icon(title: String(localized: "Upcoming"), symbolName: ThingsIcons.upcoming, tint: .upcomingRed),
                    rows: upcoming
                ))
            }
            if !someday.isEmpty {
                sections.append(ThingsMacSectionData(
                    id: ThingsSectionID.projectSomeday(projectID),
                    header: .icon(title: String(localized: "Someday"), symbolName: ThingsIcons.someday, tint: .somedayTan),
                    rows: someday
                ))
            }
        }
        if showsLogged && !logged.isEmpty {
            sections.append(ThingsMacSectionData(
                id: ThingsSectionID.projectLogged(projectID), header: nil, rows: logged, allowsReorder: false
            ))
        }
        return ScreenData(sections: sections, hasLater: hasLater, loggedCount: logged.count)
    }

    var body: some View {
        let listModel = model.viewModel(for: .anytime)
        let data = buildData(listModel)
        return ThingsMacTodoList(
            sections: data.sections,
            viewModel: listModel,
            model: model,
            header: AnyView(header(listModel, hasLater: data.hasLater, loggedCount: data.loggedCount)),
            empty: nil,
            trailing: AnyView(footer(listModel, hasLater: data.hasLater, loggedCount: data.loggedCount))
        )
        .onAppear { model.home.parentForNewProject = projectID }
        .onChange(of: projectID) { _, newID in model.home.parentForNewProject = newID }
    }

    /// Finished to-dos of the project, newest first. Only those `AppState.tasks` holds.
    private func loggedRows(now: Date, calendar: Calendar) -> [ThingsDisplayRow] {
        let finished = ThingsChecklist.topLevel(model.appState.tasks)
            .filter { $0.projectId == projectID && $0.done }
            .sorted { $0.id > $1.id }
        if finished.isEmpty { return [] }
        let section = ThingsListSection(id: ThingsSectionID.projectLogged(projectID), kind: .normal, tasks: finished)
        let mapped = ThingsRowMapper.displaySections(
            [section], list: nil, pendingDone: [], now: now, calendar: calendar
        )
        return mapped.first?.rows ?? []
    }

    // MARK: - Header and footer

    /// Title row, then the sub-projects (Area or any project with children), like the Work
    /// screen of Things: they come before the to-dos.
    private func header(_ listModel: ThingsListViewModel, hasLater: Bool, loggedCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow(listModel, hasLater: hasLater, loggedCount: loggedCount)
            if hasSubprojects {
                ThingsMacSubprojectList(parentID: projectID, model: model, listModel: listModel)
            }
        }
    }

    @ViewBuilder
    private func titleRow(_ listModel: ThingsListViewModel, hasLater: Bool, loggedCount: Int) -> some View {
        let title = project?.title ?? String(localized: "Project")
        let more = AnyView(
            ThingsMoreMenu {
                if hasLater {
                    Button(showsLater ? String(localized: "Hide Later Items") : String(localized: "Show Later Items")) {
                        withAnimation(ThingsMotion.rowRemoval) { showsLater.toggle() }
                    }
                }
                if loggedCount > 0 {
                    Button(showsLogged ? String(localized: "Hide Logged Items") : String(localized: "Show Logged Items")) {
                        withAnimation(ThingsMotion.rowRemoval) { showsLogged.toggle() }
                    }
                }
                if hasSubprojects {
                    Button(String(localized: "Expand All")) {
                        model.appState.setAllProjectsExpanded(true, tree: model.projectTree)
                    }
                    Button(String(localized: "Collapse All")) {
                        model.appState.setAllProjectsExpanded(false, tree: model.projectTree)
                    }
                }
                Button(String(localized: "Move Project...")) { model.projectMoveRequest = projectID }
            }
        )
        if isArea {
            ThingsListHeader(title: title, kind: .area, trailing: more)
        } else {
            ThingsListHeader(
                title: title,
                symbolName: ThingsIcons.project,
                tint: .accent,
                progress: listModel.progress(ofProject: projectID),
                trailing: more
            )
        }
    }

    private func footer(_ listModel: ThingsListViewModel, hasLater: Bool, loggedCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: ThingsMetrics.FooterLink.stackGap) {
                if hasLater {
                    ThingsFooterLink(
                        title: showsLater ? String(localized: "Hide later items") : String(localized: "Show later items")
                    ) {
                        withAnimation(ThingsMotion.rowRemoval) { showsLater.toggle() }
                    }
                }
                if loggedCount > 0 {
                    ThingsFooterLink(
                        title: showsLogged
                            ? String(localized: "Hide logged items")
                            : String(localized: "Show \(loggedCount) logged items")
                    ) {
                        withAnimation(ThingsMotion.rowRemoval) { showsLogged.toggle() }
                    }
                }
            }
            .padding(.top, (hasLater || loggedCount > 0) ? ThingsMetrics.FooterLink.topPadding : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#endif
