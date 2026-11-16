import SwiftUI

// Animation tokens (docs/things-spec/01-design-tokens.md section 7).
// Cultured Code does not publish curves: every value is [FROM-MEMORY] or [PROPOSAL].

enum ThingsMotion {
    /// Delay before a completed row leaves the list, so the user can undo.
    static let completionRemovalDelay: TimeInterval = 1.0
    /// Checkbox fill and checkmark.
    static let checkboxToggle: Animation = .spring(response: 0.3, dampingFraction: 0.8)
    /// Title greying and strikethrough.
    static let titleStrike: Animation = .easeOut(duration: 0.15)
    /// Row height collapse when it leaves the list.
    static let rowRemoval: Animation = .easeInOut(duration: 0.25)
    /// Row grows into the open card, and back.
    static let expand: Animation = .spring(response: 0.35, dampingFraction: 0.85)
    /// Card shadow fade.
    static let shadowFade: Animation = .easeInOut(duration: 0.2)
    /// Drag reorder.
    static let reorder: Animation = .spring(response: 0.28, dampingFraction: 0.8)
    /// Scale of a lifted row while dragging.
    static let liftScale: CGFloat = 1.03
    /// Move to or from This Evening.
    static let eveningToggle: Animation = .easeInOut(duration: 0.3)
    /// Project pie progress change. [PROPOSAL]
    static let pieProgress: Animation = .easeInOut(duration: 0.3)

    /// `animation` unless Reduce Motion is on, then nil (no animation).
    static func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
