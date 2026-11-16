import SwiftUI

#if os(iOS)
/// iPhone shell of the Things interface: a navigation stack rooted at Home
/// (docs/things-spec/02-ios-screens.md section 1). It replaces MainTabView while
/// the `thingsUIEnabled` setting is on.
struct ThingsRootView: View {
    @Environment(AppState.self) private var appState
    @Environment(FocusManager.self) private var focusManager
    @State private var path: [ThingsRoute] = []
    @State private var showSettings = false
    @State private var showUndoCompletionPrompt = false

    var body: some View {
        NavigationStack(path: $path) {
            ThingsHomeScreen(
                viewModel: ThingsHomeViewModel(appState: appState),
                onOpenSettings: { showSettings = true }
            )
            .navigationDestination(for: ThingsRoute.self) { route in
                destination(for: route)
            }
        }
        .task {
            await appState.refreshAll()
            await appState.fetchNotifications()
            await appState.loadServerVersionIfNeeded()
        }
        .onChange(of: appState.quickAddTrigger) { _, newValue in
            // mdone://create and the widgets: land on the Inbox.
            if newValue != nil {
                path = [.list(.inbox)]
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsScreen()
            }
        }
        .fullScreenCover(isPresented: Bindable(focusManager).showFocusView) {
            FocusSessionView()
        }
        .errorBanner(Bindable(appState).activeError) {
            Task { await appState.refreshAll() }
        }
        .alert(
            "Some changes could not be synced",
            isPresented: Binding(
                get: { !appState.failedSyncMessages.isEmpty },
                set: { isPresented in
                    if !isPresented { appState.failedSyncMessages = [] }
                }
            )
        ) {
            Button("OK", role: .cancel) { appState.failedSyncMessages = [] }
        } message: {
            Text(appState.failedSyncMessages.joined(separator: "\n\n"))
        }
        .onShake {
            if appState.canUndoLastCompletion {
                showUndoCompletionPrompt = true
            }
        }
        .confirmationDialog(
            undoPromptTitle,
            isPresented: $showUndoCompletionPrompt,
            titleVisibility: .visible
        ) {
            Button("Undo Completion") {
                Task { await appState.undoLastCompletion() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func destination(for route: ThingsRoute) -> some View {
        switch route {
        case .list(let list):
            ThingsListScreen(viewModel: ThingsListViewModel(list: list, appState: appState))
        case .project(let id):
            ThingsProjectScreen(projectID: id, appState: appState)
        }
    }

    private var undoPromptTitle: String {
        if let title = appState.undoableCompletionTitle {
            return String(localized: "Undo completing \u{201C}\(title)\u{201D}?")
        }
        return String(localized: "Undo completion?")
    }
}
#endif
