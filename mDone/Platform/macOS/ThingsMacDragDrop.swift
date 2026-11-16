import SwiftUI

#if os(macOS)
import AppKit

/// What is being dragged right now, known as soon as the drag starts.
///
/// A drop target cannot read the pasteboard while the pointer is still moving (the items
/// load asynchronously and only once the drop happens), yet the hover feedback needs to
/// know what is dragged: is this sidebar row a legal target, which section may the to-do
/// land in. The drag source records the payload here when the drag begins; the targets
/// use it for feedback only, and re-read the real payload from the pasteboard when the
/// drop happens (sidebar) or validate it against the screen (list).
///
/// There is no "drag ended" callback for `onDrag`, so a cancelled drag leaves the payload
/// behind: the next mouse down clears it, and targets also require the pasteboard to hold
/// a drag of our type (`validateDrop`). One system drag exists at a time, so one shared
/// instance is enough. Used on the main thread only.
final class ThingsDragSession {
    static let shared = ThingsDragSession()

    private(set) var payload: ThingsDragPayload?
    private var monitor: Any?

    private init() {}

    /// Records the payload and returns the item provider to hand to `onDrag`.
    func begin(_ payload: ThingsDragPayload) -> NSItemProvider {
        self.payload = payload
        installMonitorIfNeeded()
        return ThingsDragItem.provider(for: payload)
    }

    func end() {
        payload = nil
    }

    /// A new mouse down always starts a fresh interaction: forget a drag that ended
    /// without a drop on us (dropped outside the window, Esc).
    private func installMonitorIfNeeded() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.end()
            return event
        }
    }
}

/// Drag source of a sidebar row: only rows that carry a payload can be dragged.
struct ThingsSidebarDragSource: ViewModifier {
    let payload: ThingsDragPayload?

    func body(content: Content) -> some View {
        if let payload = payload {
            content.onDrag { ThingsDragSession.shared.begin(payload) }
        } else {
            content
        }
    }
}

/// Drop target on a sidebar row (a built-in list, a project or an Area). The highlight
/// shows only when the dragged payload is legal for this row (`accepts`).
struct ThingsSidebarDropDelegate: DropDelegate {
    /// Which row is highlighted, shared by all rows of the sidebar.
    let targeted: Binding<String?>
    let key: String
    /// Whether the dragged payload may be dropped here, read from the drag session.
    let accepts: () -> Bool
    /// Runs the drop with the payload read from the pasteboard. Returns false if refused.
    let perform: (ThingsDragPayload) -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: ThingsDragItem.contentTypes) && accepts()
    }

    func dropEntered(info: DropInfo) {
        if accepts() { targeted.wrappedValue = key }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: accepts() ? .move : .forbidden)
    }

    func dropExited(info: DropInfo) {
        if targeted.wrappedValue == key { targeted.wrappedValue = nil }
    }

    func performDrop(info: DropInfo) -> Bool {
        targeted.wrappedValue = nil
        guard accepts() else { return false }
        let providers = info.itemProviders(for: ThingsDragItem.contentTypes)
        let run = perform
        Task { @MainActor in
            guard let payload = await ThingsDragItem.load(from: providers) else { return }
            _ = run(payload)
            ThingsDragSession.shared.end()
        }
        return true
    }
}

/// Drop target of the whole to-do list: it tracks the insertion slot while a to-do hovers
/// and commits the drop. The list owns the state and the rules; this type only turns
/// pointer events into calls.
struct ThingsListDropDelegate: DropDelegate {
    /// The slot under a pointer height, nil when the dragged to-do cannot land anywhere.
    let slotAt: (CGFloat) -> ThingsDropSlot?
    let slot: Binding<ThingsDropSlot?>
    /// Animation of the gap opening and closing, nil with Reduce Motion.
    let animation: Animation?
    /// Commits a drop at the slot and clears the slot itself. Returns false when it
    /// changes nothing.
    let commit: (ThingsDropSlot) -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: ThingsDragItem.contentTypes)
            && ThingsDragSession.shared.payload?.todoID != nil
    }

    func dropEntered(info: DropInfo) {
        track(info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        track(info)
        return DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        update(nil)
    }

    func performDrop(info: DropInfo) -> Bool {
        let target = slotAt(info.location.y) ?? slot.wrappedValue
        guard let target = target else {
            update(nil)
            ThingsDragSession.shared.end()
            return false
        }
        // The slot is not cleared first: `commit` applies the new order and clears the slot
        // in one transaction, so the rows do not slide back and then forward again. Only
        // a drop that changes nothing closes the gap here.
        let done = commit(target)
        if !done { update(nil) }
        ThingsDragSession.shared.end()
        return done
    }

    private func track(_ info: DropInfo) {
        update(slotAt(info.location.y))
    }

    private func update(_ new: ThingsDropSlot?) {
        guard slot.wrappedValue != new else { return }
        withAnimation(animation) { slot.wrappedValue = new }
    }
}

#endif
