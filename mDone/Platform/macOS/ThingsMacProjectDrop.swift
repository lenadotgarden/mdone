import SwiftUI

#if os(macOS)

/// Where a project hovers while it is dragged over a project row: which row and which
/// zone of it (top edge, middle, bottom edge). Shared by the sidebar and the sub-project
/// list of an Area screen, so the feedback is the same in both.
struct ThingsProjectDropState: Equatable {
    let key: String
    let zone: ThingsRowDropZone
}

/// Heights of the rows, read by the drop delegate to tell the edges from the middle. A
/// class held in `@State`, so writing it while rows appear does not redraw anything.
final class ThingsRowHeightStore {
    var heights: [String: CGFloat] = [:]
}

/// Records the height of a row into the store, once it is laid out.
struct ThingsRowHeightReader: ViewModifier {
    let store: ThingsRowHeightStore
    let key: String

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { store.heights[key] = proxy.size.height }
                    .onChange(of: proxy.size.height) { _, newValue in store.heights[key] = newValue }
            }
        )
    }
}

/// Insertion line and row highlight for the drop state of one row.
struct ThingsProjectDropFeedback: ViewModifier {
    let state: ThingsProjectDropState?
    let key: String
    let palette: ThingsPalette
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        let zone: ThingsRowDropZone? = (state?.key == key) ? state?.zone : nil
        return content
            .overlay(alignment: .top) { line(visible: zone == .before) }
            .overlay(alignment: .bottom) { line(visible: zone == .after) }
            .animation(ThingsMotion.resolved(ThingsMotion.dropTargetHighlight, reduceMotion: reduceMotion), value: zone)
    }

    private func line(visible: Bool) -> some View {
        Capsule()
            .fill(palette[.accent])
            .frame(height: 2)
            .padding(.horizontal, ThingsMetrics.Spacing.s)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
    }
}

/// Drop target of a project row (sidebar or Area screen). A to-do dropped here is moved into
/// the project (the existing rule); a project dropped on the middle becomes its child, on
/// the top or bottom edge it lands between siblings. The state is set only when the drop
/// would do something, so the highlight never promises a refused drop.
struct ThingsProjectRowDropDelegate: DropDelegate {
    let key: String
    let state: Binding<ThingsProjectDropState?>
    let rowHeight: () -> CGFloat
    /// Whether a bottom-edge drop is a sibling drop. False for a row that shows children
    /// right under it, where "after" would be ambiguous.
    let allowsAfter: Bool
    /// The zone this payload may use on this row, nil when the row refuses it.
    let resolve: (ThingsDragPayload, ThingsRowDropZone) -> ThingsRowDropZone?
    /// Runs the drop. Returns false when it did nothing.
    let perform: (ThingsDragPayload, ThingsRowDropZone) -> Bool

    private func zone(for payload: ThingsDragPayload, info: DropInfo) -> ThingsRowDropZone? {
        var asked = ThingsRowDropZone.zone(
            y: Double(info.location.y),
            height: Double(rowHeight()),
            allowsEdges: payload.projectID != nil
        )
        if asked == .after && !allowsAfter { asked = .into }
        return resolve(payload, asked)
    }

    func validateDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: ThingsDragItem.contentTypes),
              let payload = ThingsDragSession.shared.payload else { return false }
        return zone(for: payload, info: info) != nil
    }

    func dropEntered(info: DropInfo) {
        track(info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        let legal = track(info)
        return DropProposal(operation: legal ? .move : .forbidden)
    }

    func dropExited(info: DropInfo) {
        if state.wrappedValue?.key == key { state.wrappedValue = nil }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let payload = ThingsDragSession.shared.payload,
              let chosen = zone(for: payload, info: info) else {
            state.wrappedValue = nil
            return false
        }
        state.wrappedValue = nil
        let providers = info.itemProviders(for: ThingsDragItem.contentTypes)
        let run = perform
        Task { @MainActor in
            guard let loaded = await ThingsDragItem.load(from: providers) else { return }
            _ = run(loaded, chosen)
            ThingsDragSession.shared.end()
        }
        return true
    }

    @discardableResult
    private func track(_ info: DropInfo) -> Bool {
        guard let payload = ThingsDragSession.shared.payload,
              let chosen = zone(for: payload, info: info) else {
            if state.wrappedValue?.key == key { state.wrappedValue = nil }
            return false
        }
        let next = ThingsProjectDropState(key: key, zone: chosen)
        if state.wrappedValue != next { state.wrappedValue = next }
        return true
    }
}

extension ThingsMacModel {
    /// The zone a payload may use on a project row, nil when the row refuses it. To-dos only
    /// use the middle. Reads the same rules as the drop, so hover and drop agree.
    func projectDropZone(
        for payload: ThingsDragPayload,
        on targetID: Int64,
        asked: ThingsRowDropZone
    ) -> ThingsRowDropZone? {
        switch payload {
        case .todo:
            return dropAction(for: payload, on: .project(targetID)) != nil ? ThingsRowDropZone.into : nil
        case .project(let projectID):
            return ThingsProjectDropResolver.resolvedZone(
                tree: projectTree, projectID: projectID, targetID: targetID, zone: asked
            )
        }
    }

    /// Runs a drop on a project row. Returns whether it did something.
    @discardableResult
    func handleProjectRowDrop(_ payload: ThingsDragPayload, on targetID: Int64, zone: ThingsRowDropZone) -> Bool {
        switch payload {
        case .todo:
            return handleDrop(payload, on: .project(targetID))
        case .project(let projectID):
            let tree = projectTree
            guard let outcome = ThingsProjectDropResolver.outcome(
                tree: tree, projectID: projectID, targetID: targetID, zone: zone
            ) else { return false }
            let state = appState
            switch outcome {
            case .reparent(let id, let parentID):
                guard let project = state.projects.first(where: { $0.id == id }) else { return false }
                state.setProjectExpanded(true, for: parentID)
                Task { @MainActor in
                    await state.moveProject(project, toParentId: parentID)
                }
            case .place(let placement):
                if let parentID = placement.parentID { state.setProjectExpanded(true, for: parentID) }
                Task { @MainActor in
                    await state.placeProject(placement)
                }
            }
            return true
        }
    }
}

#endif
