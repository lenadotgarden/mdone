import SwiftUI

#if os(macOS)

/// A popover the menu commands can ask the open to-do card to show.
enum ThingsMacPopover: Equatable {
    case when, deadline, tags, move
}

/// A popover shown on the selected row itself (Cmd S, Shift Cmd D), without opening the
/// to-do card. Identifiable so a row can hang it on `popover(item:)`.
struct ThingsMacRowPopover: Identifiable, Equatable {
    let kind: ThingsMacPopover
    let taskID: Int64

    var id: String { "\(taskID).\(kind)" }
}

/// A field of the open to-do card a command can put the cursor in.
enum ThingsMacEditorField: Equatable {
    case checklist
}

enum ThingsMacSheet: Identifiable {
    case newProject, newArea, settings

    var id: Int {
        switch self {
        case .newProject: return 0
        case .newArea: return 1
        case .settings: return 2
        }
    }
}

/// State of the Mac Things window: the list on screen, the selected and the
/// open to-do, and the pending requests the menu commands raise. It is the bridge
/// between `ThingsMacCommands` (which find it as a focused scene value) and the
/// views (which read it). The actions are in `ThingsMacModel+Actions`.
///
/// Selection is a single to-do for now: multi-select is a TODO in DEVIATIONS.md.
@Observable
@MainActor
final class ThingsMacModel {
    let appState: AppState
    /// Projects and Areas of the sidebar.
    let home: ThingsHomeViewModel

    /// What the detail pane shows.
    private(set) var route: ThingsRoute = .list(.today)
    private(set) var backStack: [ThingsRoute] = []
    private(set) var forwardStack: [ThingsRoute] = []

    var selectedTaskID: Int64?
    /// The to-do shown as an open card, if any.
    var expandedTaskID: Int64?
    /// To-do ids in display order, published by the list on screen for the arrow keys.
    var visibleTaskIDs: [Int64] = []
    /// Shows the empty row for a new to-do: at the top of the list, or right below the to-do
    /// `insertAfterTaskID` when that is set (Space).
    var isAddingTodo = false
    var insertAfterTaskID: Int64?
    /// When or Deadline popover hanging on a row.
    var rowPopover: ThingsMacRowPopover?

    /// Undo and redo history of this window (`ThingsMacModel+Undo`).
    var undoStack = ThingsUndoStack()
    /// Old task id to the id of the task that replaced it after an Undo Delete.
    @ObservationIgnored var idAliases: [Int64: Int64] = [:]
    var isUndoRunning = false

    /// Popover or field requested by a command, consumed by the open card.
    var pendingPopover: ThingsMacPopover?
    var editorFocusRequest: ThingsMacEditorField?
    /// Bumped by Cmd Return: the open card saves and closes.
    var commitRequest = 0
    /// Bumped to give the keyboard focus back to the list.
    var listFocusToken = 0

    /// The project whose Move popover is open in the sidebar (Shift Cmd M with a project on screen).
    var projectMoveRequest: Int64?
    /// Projects and Areas folded in the sidebar.
    var collapsedProjectIDs: Set<Int64> = []

    var sheet: ThingsMacSheet?
    var showQuickFind = false
    var pendingDeletion: VTask?
    var sidebarVisibility: NavigationSplitViewVisibility = .all

    @ObservationIgnored private var viewModels: [ThingsList: ThingsListViewModel] = [:]

    init(appState: AppState) {
        self.appState = appState
        self.home = ThingsHomeViewModel(appState: appState)
    }

    // MARK: - View models

    /// One list view model per list, kept so a ticked box keeps its delay across redraws.
    func viewModel(for list: ThingsList) -> ThingsListViewModel {
        if let existing = viewModels[list] { return existing }
        let created = ThingsListViewModel(list: list, appState: appState)
        viewModels[list] = created
        return created
    }

    /// The view model of the list on screen. Projects use the Anytime one for
    /// its actions and progress, like the iPhone project screen.
    var activeViewModel: ThingsListViewModel {
        if case .list(let list) = route { return viewModel(for: list) }
        return viewModel(for: .anytime)
    }

    /// The full project tree of the sidebar (Areas, projects, deeper levels).
    var projectTree: ThingsProjectTree {
        ThingsProjectTree.build(projects: appState.projects, inboxProjectID: appState.defaultProject?.id)
    }

    var selectedTask: VTask? {
        guard let id = selectedTaskID else { return nil }
        return appState.tasks.first { $0.id == id }
    }

    /// The title of the window.
    var title: String {
        switch route {
        case .list(let list):
            return list.title
        case .project(let id):
            return appState.projects.first { $0.id == id }?.title ?? String(localized: "Project")
        }
    }

    // MARK: - Navigation

    func navigate(to target: ThingsRoute) {
        if target == route { return }
        backStack.append(route)
        forwardStack.removeAll()
        route = target
        clearSelection()
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(route)
        route = previous
        clearSelection()
    }

    func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(route)
        route = next
        clearSelection()
    }

    func toggleSidebar() {
        sidebarVisibility = (sidebarVisibility == .detailOnly) ? .all : .detailOnly
    }

    // MARK: - Selection

    func clearSelection() {
        selectedTaskID = nil
        expandedTaskID = nil
        isAddingTodo = false
        insertAfterTaskID = nil
        rowPopover = nil
    }

    /// Selects a to-do. Selecting another one closes the open card.
    func select(_ id: Int64?) {
        if id != expandedTaskID { expandedTaskID = nil }
        selectedTaskID = id
    }

    func moveSelection(by step: Int) {
        let ids = visibleTaskIDs
        if ids.isEmpty { return }
        guard let current = selectedTaskID, let index = ids.firstIndex(of: current) else {
            select(step >= 0 ? ids.first : ids.last)
            return
        }
        let next = min(max(index + step, 0), ids.count - 1)
        select(ids[next])
    }

    func selectFirst() { select(visibleTaskIDs.first) }

    func selectLast() { select(visibleTaskIDs.last) }

    // MARK: - Open card

    func open(_ id: Int64) {
        selectedTaskID = id
        expandedTaskID = id
    }

    func openSelected() {
        guard let id = selectedTaskID else { return }
        expandedTaskID = id
    }

    func collapseEditor() {
        expandedTaskID = nil
        listFocusToken += 1
    }

    /// Shows a popover for the selected to-do. When and Deadline (Cmd S, Shift Cmd D) hang on
    /// the row itself, or on the open card when the card is already open; Tags and Move
    /// open the card first, their buttons live there.
    func requestPopover(_ popover: ThingsMacPopover) {
        guard let id = selectedTaskID else { return }
        switch popover {
        case .when, .deadline:
            if expandedTaskID == id {
                pendingPopover = popover
            } else {
                rowPopover = ThingsMacRowPopover(kind: popover, taskID: id)
            }
        case .tags, .move:
            expandedTaskID = id
            pendingPopover = popover
        }
    }

    /// Closes the popover of a row and gives the keyboard back to the list.
    func closeRowPopover() {
        rowPopover = nil
        listFocusToken += 1
    }

    /// Move (Shift Cmd M): the selected to-do when there is one, else the
    /// project or Area on screen (its popover opens in the sidebar).
    func requestMove() {
        if selectedTaskID != nil {
            requestPopover(.move)
            return
        }
        if case .project(let id) = route, projectTree.node(id: id) != nil {
            projectMoveRequest = id
        }
    }

    func requestChecklist() {
        guard let id = selectedTaskID else { return }
        expandedTaskID = id
        editorFocusRequest = .checklist
    }

    func saveAndClose() {
        if expandedTaskID != nil { commitRequest += 1 }
    }
}

// MARK: - Commands bridge

struct ThingsMacModelKey: FocusedValueKey {
    typealias Value = ThingsMacModel
}

extension FocusedValues {
    /// The model of the key window, set by `ThingsMacRootView`. Nil while the
    /// classic Mac interface is shown, which turns the Things menu items off.
    var thingsMac: ThingsMacModel? {
        get { self[ThingsMacModelKey.self] }
        set { self[ThingsMacModelKey.self] = newValue }
    }
}

#endif
