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
/// its open to-dos, then the "Upcoming" and "Someday" groups with their icon and rule,
/// then for an Area its projects, then "Hide later items" and "Show N logged items".
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

    private var isArea: Bool {
        guard let project = project else { return false }
        return ThingsProjectMeta.isArea(project)
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

        var sections = [ThingsMacSectionData(id: "project.\(projectID)", header: nil, rows: main)]
        if showsLater {
            if !upcoming.isEmpty {
                sections.append(ThingsMacSectionData(
                    id: "project.\(projectID).upcoming",
                    header: .icon(title: String(localized: "Upcoming"), symbolName: ThingsIcons.upcoming, tint: .upcomingRed),
                    rows: upcoming
                ))
            }
            if !someday.isEmpty {
                sections.append(ThingsMacSectionData(
                    id: "project.\(projectID).someday",
                    header: .icon(title: String(localized: "Someday"), symbolName: ThingsIcons.someday, tint: .somedayTan),
                    rows: someday
                ))
            }
        }
        if showsLogged && !logged.isEmpty {
            sections.append(ThingsMacSectionData(
                id: "project.\(projectID).logged", header: nil, rows: logged, allowsReorder: false
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
    }

    /// Finished to-dos of the project, newest first. Only those `AppState.tasks` holds.
    private func loggedRows(now: Date, calendar: Calendar) -> [ThingsDisplayRow] {
        let finished = ThingsChecklist.topLevel(model.appState.tasks)
            .filter { $0.projectId == projectID && $0.done }
            .sorted { $0.id > $1.id }
        if finished.isEmpty { return [] }
        let section = ThingsListSection(id: "project.\(projectID).logged", kind: .normal, tasks: finished)
        let mapped = ThingsRowMapper.displaySections(
            [section], list: nil, pendingDone: [], now: now, calendar: calendar
        )
        return mapped.first?.rows ?? []
    }

    // MARK: - Header and footer

    @ViewBuilder
    private func header(_ listModel: ThingsListViewModel, hasLater: Bool, loggedCount: Int) -> some View {
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
            if isArea { children(listModel) }
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

    /// The projects of an Area: pie, bold title and a small count badge (mac-dark-03.png).
    private func children(_ listModel: ThingsListViewModel) -> some View {
        let palette = ThingsPalette(scheme)
        let kids = ThingsProjectMeta.children(of: projectID, in: model.appState.projects)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(kids) { child in
                let openCount = model.appState.tasksForProject(child.id).count
                Button {
                    model.navigate(to: .project(child.id))
                } label: {
                    HStack(spacing: ThingsMetrics.Row.checkboxTitleSpacing) {
                        ThingsProjectPie(progress: listModel.progress(ofProject: child.id), size: ThingsMetrics.Checkbox.size + 4)
                        Text(verbatim: child.title)
                            .font(ThingsTypography.todoTitle.weight(.semibold))
                            .foregroundStyle(palette[.textPrimary])
                            .lineLimit(1)
                        if openCount > 0 {
                            Text(verbatim: String(openCount))
                                .font(ThingsTypography.datePill)
                                .foregroundStyle(palette[.textSecondary])
                                .padding(.horizontal, 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .strokeBorder(palette[.tagPillBorder], lineWidth: ThingsMetrics.Chip.tagBorderWidth)
                                )
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, ThingsMetrics.Layout.listHorizontalMargin - 2)
                    .frame(minHeight: ThingsMetrics.Row.minHeight)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, ThingsMetrics.Spacing.s)
    }
}

#endif
