import SwiftUI

// SF Symbol names per list and per item field
// (docs/things-spec/01-design-tokens.md section 5). Things uses custom
// artwork, so these are stand-ins to redraw later. Symbol picks are [PROPOSAL].

/// The kinds of list that carry an icon.
enum ThingsListKind: CaseIterable {
    case inbox, today, evening, upcoming, anytime, someday, logbook, trash, area, project
}

enum ThingsIcons {
    static let inbox = "tray.fill"
    static let today = "star.fill"
    static let evening = "moon.fill"
    static let upcoming = "calendar"
    static let anytime = "square.stack.3d.up.fill"
    static let someday = "archivebox.fill"
    static let logbook = "book.closed.fill"
    static let trash = "trash.fill"
    static let area = "shippingbox.fill"
    /// Projects are drawn with ThingsProjectPie. This is the fallback glyph.
    static let project = "circle"
    static let heading = "textformat.size"
    static let deadlineFlag = "flag.fill"
    static let deadlineFlame = "flame.fill"
    static let checklist = "checklist"
    static let notes = "note.text"
    /// Small document glyph after a Mac row title when the to-do has notes.
    static let notesDocument = "doc"
    static let moreDots = "ellipsis"
    static let repeating = "repeat"
    static let tag = "tag"
    static let when = "calendar"
    static let reminder = "bell"
    static let add = "plus"
    static let checkmark = "checkmark"
    static let cancelled = "xmark"

    /// Symbol for a list kind.
    static func symbol(for kind: ThingsListKind) -> String {
        switch kind {
        case .inbox: return inbox
        case .today: return today
        case .evening: return evening
        case .upcoming: return upcoming
        case .anytime: return anytime
        case .someday: return someday
        case .logbook: return logbook
        case .trash: return trash
        case .area: return area
        case .project: return project
        }
    }

    /// Colour token of a list kind icon.
    static func tint(for kind: ThingsListKind) -> ThingsColorToken {
        switch kind {
        case .inbox: return .accent
        case .today: return .todayStar
        case .evening: return .eveningMoon
        case .upcoming: return .upcomingRed
        case .anytime: return .anytimeTeal
        case .someday: return .somedayTan
        case .logbook: return .logbookGreen
        case .trash: return .trashGray
        case .area: return .areaGray
        case .project: return .accent
        }
    }
}
