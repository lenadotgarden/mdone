import Foundation

/// Every Things list of one task set, computed together.
///
/// Built once per change of the inputs (tasks, Inbox project, day) and read
/// many times by the views, instead of rebuilding a list for each badge and
/// each redraw. See `ThingsListBuilder.snapshot`.
struct ThingsListSnapshot {
    /// The sections of each list, empty sections omitted.
    let sections: [ThingsList: [ThingsListSection]]
    /// The task count of each list.
    let counts: [ThingsList: Int]

    static let empty = ThingsListSnapshot(sections: [:], counts: [:])
}
