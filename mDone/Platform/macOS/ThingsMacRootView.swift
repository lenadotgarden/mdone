import SwiftUI

#if os(macOS)

/// Mac shell of the Things interface (docs/things-spec/04-macos-screens.md
/// section 1): a sidebar and one detail pane, no inspector, since a to-do
/// opens in place in the list. It replaces `MacContentView` while the
/// `thingsUIEnabled` setting is on. The menu commands reach `ThingsMacModel`
/// as a focused scene value.
struct ThingsMacRootView: View {
    @State private var model: ThingsMacModel

    @MainActor
    init(appState: AppState) {
        _model = State(initialValue: ThingsMacModel(appState: appState))
    }

    private var visibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { model.sidebarVisibility },
            set: { model.sidebarVisibility = $0 }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: visibility) {
            ThingsMacSidebar(model: model)
                .navigationSplitViewColumnWidth(
                    min: ThingsMetrics.Layout.sidebarMinWidth,
                    ideal: ThingsMetrics.Layout.sidebarWidth,
                    max: ThingsMetrics.Layout.sidebarMaxWidth
                )
        } detail: {
            detail
                .navigationTitle(model.title)
                .toolbar { toolbarContent }
        }
        .frame(minWidth: 760, minHeight: 520)
        .focusedSceneValue(\.thingsMac, model)
        .thingsMacSheets(model: model)
        .thingsTypeTravel(model: model)
        .thingsMacSystemAlerts(appState: model.appState)
        .task {
            await model.appState.refreshAll()
            await model.appState.fetchNotifications()
            await model.appState.loadServerVersionIfNeeded()
        }
        .task(id: model.appState.quickAddTrigger) {
            // mdone://create and the widgets: open a new to-do in the Inbox.
            guard model.appState.quickAddTrigger != nil else { return }
            model.appState.quickAddTrigger = nil
            model.navigate(to: .list(.inbox))
            model.newTodo()
        }
        .onAppear {
            ThingsQuickEntryController.shared.configure(appState: model.appState)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch model.route {
        case .list(let list):
            ThingsMacListScreen(list: list, model: model)
                .id(model.route)
        case .project(let id):
            ThingsMacProjectScreen(projectID: id, model: model)
                .id(model.route)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button {
                model.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!model.canGoBack)
            .help(String(localized: "Back"))
            Button {
                model.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!model.canGoForward)
            .help(String(localized: "Forward"))
        }
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                model.newTodo()
            } label: {
                Image(systemName: ThingsIcons.add)
            }
            .help(String(localized: "New To-Do"))
            Button {
                model.showQuickFind = true
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .help(String(localized: "Quick Find"))
            Button {
                model.sheet = .settings
            } label: {
                Image(systemName: "gearshape")
            }
            .help(String(localized: "Settings"))
        }
    }
}

#endif
