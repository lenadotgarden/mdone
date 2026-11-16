import SwiftUI

// Sizes for the Things screens and the Magic Plus button
// (docs/things-spec/01-design-tokens.md section 4, 02-ios-screens.md section 2).
// All values are [PROPOSAL].

extension ThingsMetrics {
    enum MagicPlus {
        static let size: CGFloat = 56
        static let glyphSize: CGFloat = 24
        static let edgeMargin: CGFloat = 20
        static let shadowRadius: CGFloat = 8
        static let shadowOffsetY: CGFloat = 3
        static let pressedScale: CGFloat = 0.94
    }

    enum Screen {
        /// Empty space at the end of a list so the Magic Plus never hides the last row.
        static let listBottomClearance: CGFloat = 96
        /// Height given to the empty state inside a list.
        static let emptyStateHeight: CGFloat = 320
        /// Vertical space between the groups of the Home screen.
        static let homeGroupSpacing: CGFloat = 16
    }
}
