import SwiftUI

// Spacing, sizes and radii (docs/things-spec/01-design-tokens.md section 4).
// All values are [FROM-MEMORY] or [PROPOSAL]; [UNSURE] ones are tagged.

/// Picks a value per platform. iOS gets `ios`, every other platform gets `mac`.
enum ThingsPlatform {
    static func value<T>(ios: T, mac: T) -> T {
        #if os(iOS)
        return ios
        #else
        return mac
        #endif
    }
}

enum ThingsMetrics {
    /// Generic spacing scale.
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Layout {
        /// Horizontal margin of lists (checkbox x position).
        static let listHorizontalMargin: CGFloat = ThingsPlatform.value(ios: 16, mac: 20)
        /// Width of the macOS sidebar. [UNSURE]
        static let sidebarWidth: CGFloat = 220
        static let sidebarMinWidth: CGFloat = 180
        static let sidebarMaxWidth: CGFloat = 400
        /// Pull-down distance that switches to Quick Find. [UNSURE]
        static let pullDownThreshold: CGFloat = 60
    }

    enum Checkbox {
        static let size: CGFloat = ThingsPlatform.value(ios: 22, mac: 16)
        /// Corner radius of the rounded square box.
        static let cornerRadius: CGFloat = ThingsPlatform.value(ios: 5, mac: 4)
        /// Draw a circle instead of a rounded square. The spec describes a rounded square.
        static let isCircular: Bool = false
        static let borderWidth: CGFloat = 1.5
        /// Checkmark and cross size as a fraction of the box size.
        static let glyphScale: CGFloat = 0.6
        /// Diameter of the in-progress dot as a fraction of the box size.
        static let inProgressDotScale: CGFloat = 0.4
        /// Checklist item circle. [UNSURE] on macOS.
        static let checklistItemSize: CGFloat = ThingsPlatform.value(ios: 16, mac: 14)
    }

    enum Row {
        /// Minimum height of a to-do row showing only a title.
        static let minHeight: CGFloat = ThingsPlatform.value(ios: 44, mac: 28)
        static let verticalPadding: CGFloat = ThingsPlatform.value(ios: 10, mac: 5)
        static let checkboxTitleSpacing: CGFloat = ThingsPlatform.value(ios: 12, mac: 8)
        /// Space between the title block lines.
        static let lineSpacing: CGFloat = 3
        /// Hairline separator thickness.
        static let separatorThickness: CGFloat = 0.5
        /// Left inset of the separator, aligned on the title text.
        static let separatorInset: CGFloat =
            Layout.listHorizontalMargin + Checkbox.size + checkboxTitleSpacing
        /// Width reserved for the Today star in front of the checkbox.
        static let starSize: CGFloat = ThingsPlatform.value(ios: 12, mac: 10)
        static let maxVisibleTags: Int = 3
        static let indicatorIconSize: CGFloat = ThingsPlatform.value(ios: 12, mac: 10)
    }

    enum Card {
        /// Opened to-do card. Corner radius is [UNSURE].
        static let cornerRadius: CGFloat = ThingsPlatform.value(ios: 10, mac: 8)
        static let outerMargin: CGFloat = 8
        static let innerPadding: CGFloat = 16
        static let shadowRadius: CGFloat = ThingsPlatform.value(ios: 12, mac: 10)
        static let shadowOffsetY: CGFloat = 2
    }

    enum Chip {
        static let horizontalPadding: CGFloat = ThingsPlatform.value(ios: 8, mac: 6)
        static let verticalPadding: CGFloat = ThingsPlatform.value(ios: 3, mac: 2)
    }

    enum Icon {
        /// List icon (Home row, header, sidebar).
        static let list: CGFloat = ThingsPlatform.value(ios: 24, mac: 18)
        /// Icon in the big list header.
        static let header: CGFloat = ThingsPlatform.value(ios: 28, mac: 22)
        static let homeRowHeight: CGFloat = 46
    }

    enum Pie {
        static let ringWidth: CGFloat = 1.5
        /// Gap between the ring and the filled sector.
        static let gap: CGFloat = 1.5
        static let rowSize: CGFloat = ThingsPlatform.value(ios: 22, mac: 16)
        static let headerSize: CGFloat = ThingsPlatform.value(ios: 30, mac: 22)
    }

    enum Header {
        static let topPadding: CGFloat = ThingsPlatform.value(ios: 8, mac: 12)
        static let bottomPadding: CGFloat = ThingsPlatform.value(ios: 12, mac: 12)
        static let iconTitleSpacing: CGFloat = ThingsPlatform.value(ios: 10, mac: 8)
        /// Space above a section header.
        static let sectionTopPadding: CGFloat = ThingsPlatform.value(ios: 20, mac: 16)
        static let sectionBottomPadding: CGFloat = 6
        /// Hairline under a project heading.
        static let headingRuleThickness: CGFloat = 0.5
    }

    enum Empty {
        static let iconSize: CGFloat = ThingsPlatform.value(ios: 44, mac: 36)
        static let spacing: CGFloat = 10
        static let maxTextWidth: CGFloat = 280
    }

    enum Deadline {
        /// At or below this many days left, the label turns red.
        static let urgentThresholdDays: Int = 0
    }
}
