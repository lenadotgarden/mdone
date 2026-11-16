import Foundation

/// The built-in Things lists that are computed from tasks rather than stored
/// (docs/things-spec/06-behaviors-rules.md, section 1). Order is the sidebar
/// order.
enum ThingsList: String, CaseIterable, Identifiable, Hashable {
    case inbox
    case today
    case upcoming
    case anytime
    case someday
    case logbook

    var id: String { rawValue }
}

/// One block of a list: a group of tasks under an optional header.
struct ThingsListSection: Identifiable, Equatable {
    enum Kind: Equatable, Hashable {
        /// The plain, header-less block.
        case normal
        /// The "This Evening" block at the bottom of Today.
        case evening
        /// One calendar day. The date is that day's start of day.
        case dateGroup(Date)
        /// One calendar month, used by Upcoming beyond the first seven days.
        /// The date is the first day's start of day.
        case monthGroup(Date)
        /// Tasks whose deadline is before today, at the top of Today.
        case overdue
    }

    /// Stable within a list, so SwiftUI can diff sections.
    let id: String
    let kind: Kind
    var tasks: [VTask]
}
