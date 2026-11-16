import SwiftUI

/// One to-do line in a Things list: the row, its separator and the swipe
/// actions of spec 03 section "Swipe droit" (When). Swipe left is Delete for now:
/// the spec's multi-select is listed in docs/things-spec/DEVIATIONS.md.
struct ThingsRowCell: View {
    let row: ThingsDisplayRow
    let viewModel: ThingsListViewModel
    /// Opens the to-do (stopgap: the existing TaskDetailSheet).
    let onOpen: (VTask) -> Void
    /// Asks the screen to show the When menu for this to-do.
    let onWhen: (VTask) -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = ThingsPalette(scheme)
        ThingsTodoRow(model: row.model, onToggle: { viewModel.tapCheckbox(row.task) })
            .contentShape(Rectangle())
            .onTapGesture { onOpen(row.task) }
            .overlay(alignment: .bottom) { ThingsDivider() }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    onWhen(row.task)
                } label: {
                    Label(String(localized: "When"), systemImage: ThingsIcons.when)
                }
                .tint(palette[.upcomingRed])
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    let task = row.task
                    Task { await viewModel.delete(task) }
                } label: {
                    Label(String(localized: "Delete"), systemImage: ThingsIcons.trash)
                }
            }
    }
}

/// The When menu opened by the right swipe (spec 03: Today, This Evening,
/// Someday, a date, clear). A calendar date picker is a TODO, see DEVIATIONS.md.
private struct ThingsWhenDialog: ViewModifier {
    @Binding var task: VTask?
    let viewModel: ThingsListViewModel

    func body(content: Content) -> some View {
        content.confirmationDialog(
            String(localized: "When"),
            isPresented: Binding(
                get: { task != nil },
                set: { isPresented in if !isPresented { task = nil } }
            ),
            titleVisibility: .visible,
            presenting: task
        ) { target in
            Button(String(localized: "Today")) { apply(.today, to: target) }
            Button(String(localized: "This Evening")) { apply(.thisEvening, to: target) }
            Button(String(localized: "Tomorrow")) { apply(.date(viewModel.tomorrow), to: target) }
            Button(String(localized: "Someday")) { apply(.someday, to: target) }
            Button(String(localized: "Clear")) { apply(ThingsWhen.none, to: target) }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }

    private func apply(_ when: ThingsWhen, to target: VTask) {
        let model = viewModel
        Task { await model.schedule(target, when: when) }
    }
}

extension View {
    /// Shows the When menu for `task` while it is non-nil.
    func thingsWhenDialog(task: Binding<VTask?>, viewModel: ThingsListViewModel) -> some View {
        modifier(ThingsWhenDialog(task: task, viewModel: viewModel))
    }
}
