import Foundation

/// Titles, icons and empty texts of the built-in lists (spec 02 sections 1 to 8,
/// empty texts from 06 section 15, all of them [UNSURE] there).
extension ThingsList {
    var kind: ThingsListKind {
        switch self {
        case .inbox: return .inbox
        case .today: return .today
        case .upcoming: return .upcoming
        case .anytime: return .anytime
        case .someday: return .someday
        case .logbook: return .logbook
        }
    }

    var title: String {
        switch self {
        case .inbox: return String(localized: "Inbox")
        case .today: return String(localized: "Today")
        case .upcoming: return String(localized: "Upcoming")
        case .anytime: return String(localized: "Anytime")
        case .someday: return String(localized: "Someday")
        case .logbook: return String(localized: "Logbook")
        }
    }

    var emptyTitle: String {
        switch self {
        case .inbox: return String(localized: "Inbox is empty")
        case .today: return String(localized: "Today is empty")
        case .upcoming: return String(localized: "Nothing scheduled")
        case .anytime: return String(localized: "Nothing to do anytime")
        case .someday: return String(localized: "Nothing for someday")
        case .logbook: return String(localized: "Your logbook is empty")
        }
    }

    var emptyMessage: String? {
        switch self {
        case .inbox: return String(localized: "New to-dos land here.")
        case .today: return String(localized: "Enjoy your day.")
        case .upcoming, .anytime, .someday, .logbook: return nil
        }
    }

    /// Whether the Magic Plus is shown on this list. The Logbook only holds
    /// finished to-dos.
    var allowsQuickAdd: Bool {
        self != .logbook
    }
}
