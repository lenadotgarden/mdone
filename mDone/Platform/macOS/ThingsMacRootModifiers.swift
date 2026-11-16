import SwiftUI

#if os(macOS)

/// Sheets and the delete confirmation of the Things window.
private struct ThingsMacSheets: ViewModifier {
    let model: ThingsMacModel

    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(get: { model.sheet }, set: { model.sheet = $0 })) { sheet in
                switch sheet {
                case .newProject:
                    ThingsMacNewListSheet(model: model, isArea: false)
                case .newArea:
                    ThingsMacNewListSheet(model: model, isArea: true)
                case .settings:
                    ThingsMacSettingsSheet()
                }
            }
            // Quick Find is a card over the window rather than a sheet, so Type Travel
            // keeps the key focus in the same window (spec 04 section 6).
            .overlay {
                if model.showQuickFind {
                    ThingsQuickFindView(model: model)
                }
            }
            .alert(
                String(localized: "Delete this to-do?"),
                isPresented: Binding(
                    get: { model.pendingDeletion != nil },
                    set: { isPresented in
                        if !isPresented { model.pendingDeletion = nil }
                    }
                ),
                presenting: model.pendingDeletion
            ) { task in
                Button(String(localized: "Delete"), role: .destructive) { model.confirmDeletion(task) }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: { task in
                Text(verbatim: task.title)
            }
    }
}

/// What `MacContentView` shows for errors and for the sync, server and store
/// notices, so the Things window does not hide them.
private struct ThingsMacSystemAlerts: ViewModifier {
    let appState: AppState

    func body(content: Content) -> some View {
        content
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
            .alert(
                "Update your Vikunja server",
                isPresented: Binding(
                    get: { appState.showServerUpdateNotice },
                    set: { isPresented in
                        if !isPresented { appState.acknowledgeServerUpdateNotice() }
                    }
                )
            ) {
                Button("OK", role: .cancel) { appState.acknowledgeServerUpdateNotice() }
            } message: {
                Text(appState.serverVersion.map(ServerUpdateNotice.message) ?? "")
            }
            .alert(
                "Offline database rebuilt",
                isPresented: Binding(
                    get: { appState.storeRecoveryMessage != nil },
                    set: { isPresented in
                        if !isPresented { appState.storeRecoveryMessage = nil }
                    }
                )
            ) {
                Button("OK", role: .cancel) { appState.storeRecoveryMessage = nil }
            } message: {
                Text(appState.storeRecoveryMessage ?? "")
            }
    }
}

extension View {
    func thingsMacSheets(model: ThingsMacModel) -> some View {
        modifier(ThingsMacSheets(model: model))
    }

    func thingsMacSystemAlerts(appState: AppState) -> some View {
        modifier(ThingsMacSystemAlerts(appState: appState))
    }
}

/// Title field for New Project and New Area (the New List button of the sidebar).
struct ThingsMacNewListSheet: View {
    let model: ThingsMacModel
    let isArea: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""

    private var trimmed: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: ThingsMetrics.Spacing.m) {
            Text(isArea ? String(localized: "New Area") : String(localized: "New Project"))
                .font(.headline)
            TextField(String(localized: "Title"), text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit { create() }
            HStack {
                Spacer()
                Button(String(localized: "Cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(String(localized: "Create")) { create() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(trimmed.isEmpty)
            }
        }
        .padding(ThingsMetrics.Spacing.xl)
        .frame(width: 340)
    }

    private func create() {
        if trimmed.isEmpty { return }
        model.createProject(title: trimmed, isArea: isArea)
        dismiss()
    }
}

/// The existing Settings screen in a sheet, with the "Interface Things" switch.
struct ThingsMacSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SettingsScreen()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(String(localized: "Done")) { dismiss() }
                    }
                }
        }
        .frame(minWidth: 520, minHeight: 600)
    }
}

#endif
