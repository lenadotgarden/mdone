import SwiftUI

/// A built-in Things list: big title, sections, rows, empty state (spec 02
/// sections 2 to 8). Tapping a row opens the existing TaskDetailSheet as a
/// stopgap for the in-place card (docs/things-spec/DEVIATIONS.md).
struct ThingsListScreen: View {
    @State private var viewModel: ThingsListViewModel
    @State private var detailTask: VTask?
    @State private var whenTask: VTask?
    @State private var isAdding = false

    @Environment(\.colorScheme) private var scheme

    init(viewModel: ThingsListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var palette: ThingsPalette { ThingsPalette(scheme) }

    var body: some View {
        let sections = viewModel.displaySections
        ZStack(alignment: .bottomTrailing) {
            list(sections)
            #if os(iOS)
            if viewModel.list.allowsQuickAdd {
                ThingsMagicPlusButton { isAdding = true }
                    .padding(ThingsMetrics.MagicPlus.edgeMargin)
            }
            #endif
        }
        .background(palette[.bgPrimary])
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $detailTask) { task in
            TaskDetailSheet(task: task)
        }
        .thingsWhenDialog(task: $whenTask, viewModel: viewModel)
    }

    private func list(_ sections: [ThingsDisplaySection]) -> some View {
        List {
            ThingsListHeader(title: viewModel.list.title, kind: viewModel.list.kind)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            if isAdding {
                ThingsInlineAddRow { title in
                    isAdding = false
                    if title.isEmpty { return }
                    let model = viewModel
                    Task { await model.quickAdd(title: title) }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            if sections.isEmpty && !isAdding {
                ThingsEmptyState(
                    symbolName: ThingsIcons.symbol(for: viewModel.list.kind),
                    title: viewModel.list.emptyTitle,
                    message: viewModel.list.emptyMessage,
                    tint: ThingsIcons.tint(for: viewModel.list.kind)
                )
                .frame(height: ThingsMetrics.Screen.emptyStateHeight)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            ForEach(sections) { section in
                sectionView(section)
            }
            Color.clear
                .frame(height: ThingsMetrics.Screen.listBottomClearance)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
        .animation(ThingsMotion.rowRemoval, value: viewModel.rowIDs)
    }

    @ViewBuilder
    private func sectionView(_ section: ThingsDisplaySection) -> some View {
        if let style = viewModel.headerStyle(for: section) {
            Section {
                rows(of: section)
            } header: {
                ThingsSectionHeader(style: style)
                    .background(palette[.bgPrimary])
                    .textCase(nil)
            }
        } else {
            Section {
                rows(of: section)
            }
        }
    }

    private func rows(of section: ThingsDisplaySection) -> some View {
        ForEach(section.rows) { row in
            ThingsRowCell(
                row: row,
                viewModel: viewModel,
                onOpen: { task in detailTask = task },
                onWhen: { task in whenTask = task }
            )
        }
    }
}
