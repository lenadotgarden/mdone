import SwiftUI

// Spacing, sizes and radii (docs/things-spec/01-design-tokens.md section 4).
// macOS values are read from docs/things-spec/reference/mac-dark-0N.png, which are
// 2x retina captures (1 pt = 2 px), so each is MEASURED to about 1 pt, or
// ESTIMATED where the comment says so. iOS values are still [FROM-MEMORY] or
// [PROPOSAL]; [UNSURE] ones are tagged.

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
        /// Horizontal inset of row content inside the selection highlight (the
        /// checkbox starts this far from the row edge). Mac MEASURED: row 522, checkbox 532.
        static let listHorizontalMargin: CGFloat = ThingsPlatform.value(ios: 16, mac: 10)
        /// Widest the Mac list column gets (selection highlight width). MEASURED: 1020 pt
        /// in a 1448 pt pane, centred within about 6 pt.
        static let contentMaxWidth: CGFloat = 1020
        /// Width of the macOS sidebar. MEASURED: 302 pt in the screenshots (a wide window
        /// with a large Text Size); Things' own default is smaller, so min and ideal stay modest.
        static let sidebarWidth: CGFloat = 240
        static let sidebarMinWidth: CGFloat = 200
        static let sidebarMaxWidth: CGFloat = 400
        /// Sidebar width measured in the screenshots.
        static let sidebarWidthMeasured: CGFloat = 302
        /// Pull-down distance that switches to Quick Find. [UNSURE]
        static let pullDownThreshold: CGFloat = 60
    }

    enum Checkbox {
        /// Mac MEASURED 12 pt (x 32..44 in 2x crops).
        static let size: CGFloat = ThingsPlatform.value(ios: 22, mac: 12)
        /// Corner radius of the rounded square box. Mac ESTIMATED.
        static let cornerRadius: CGFloat = ThingsPlatform.value(ios: 5, mac: 3)
        /// Draw a circle instead of a rounded square. The spec describes a rounded square.
        static let isCircular: Bool = false
        /// Mac ESTIMATED 1 pt hairline.
        static let borderWidth: CGFloat = ThingsPlatform.value(ios: 1.5, mac: 1)
        /// Checkmark and cross size as a fraction of the box size.
        static let glyphScale: CGFloat = 0.6
        /// Diameter of the in-progress dot as a fraction of the box size.
        static let inProgressDotScale: CGFloat = 0.4
        /// Dash pattern of the Someday checkbox on Mac (MEASURED: the box is dashed there).
        static let somedayDash: [CGFloat] = [2, 2]
        /// Checklist item circle. [UNSURE] on macOS.
        static let checklistItemSize: CGFloat = ThingsPlatform.value(ios: 16, mac: 12)
    }

    enum Row {
        /// Height of a to-do row with a title only. Mac MEASURED 28 pt (row pitch).
        static let minHeight: CGFloat = ThingsPlatform.value(ios: 44, mac: 28)
        /// Height of a two-line row (title and project line). Mac MEASURED 38 pt.
        static let twoLineHeight: CGFloat = ThingsPlatform.value(ios: 58, mac: 38)
        static let verticalPadding: CGFloat = ThingsPlatform.value(ios: 10, mac: 3)
        /// Checkbox right edge to title left edge. Mac MEASURED: box 32..44, title 53.
        static let checkboxTitleSpacing: CGFloat = ThingsPlatform.value(ios: 12, mac: 9)
        /// Space between the title block lines. Mac ESTIMATED.
        static let lineSpacing: CGFloat = ThingsPlatform.value(ios: 3, mac: 0)
        /// Hairline separator thickness (iOS only, the Mac list has no row separators: MEASURED).
        static let separatorThickness: CGFloat = 0.5
        /// Left inset of the separator, aligned on the title text.
        static let separatorInset: CGFloat =
            Layout.listHorizontalMargin + Checkbox.size + checkboxTitleSpacing
        /// Selection highlight corner radius. Mac ESTIMATED 6 pt.
        static let selectionCornerRadius: CGFloat = 6
        /// Width reserved for the Today star in front of the checkbox.
        static let starSize: CGFloat = ThingsPlatform.value(ios: 12, mac: 10)
        static let maxVisibleTags: Int = 3
        static let indicatorIconSize: CGFloat = ThingsPlatform.value(ios: 12, mac: 10)
        /// Gap between title and the trailing notes icon or tag pill. MEASURED about 5 pt.
        static let trailingItemSpacing: CGFloat = 5
        /// Gap between the title and a tag pill. MEASURED about 8 pt.
        static let tagLeadingSpacing: CGFloat = 8
        /// Emoji and name spacing in the project line. ESTIMATED.
        static let projectLineSpacing: CGFloat = 3
    }

    enum Card {
        /// Opened to-do card. Mac MEASURED about 12 pt (large, continuous).
        static let cornerRadius: CGFloat = ThingsPlatform.value(ios: 10, mac: 12)
        /// Outset of the card beyond the row highlight. Mac MEASURED 4 pt left, 5 pt right.
        static let outerMargin: CGFloat = ThingsPlatform.value(ios: 8, mac: 0)
        static let outset: CGFloat = 4
        /// Space above and below the card in the list (the neighbours stay 38/28 apart). ESTIMATED.
        static let verticalMargin: CGFloat = 10
        /// Left and right padding of the title row. Mac MEASURED 14 pt.
        static let innerPadding: CGFloat = ThingsPlatform.value(ios: 16, mac: 14)
        /// Top padding above the title line. Mac MEASURED 18 pt.
        static let topPadding: CGFloat = ThingsPlatform.value(ios: 16, mac: 18)
        /// Bottom padding under the toolbar line. Mac MEASURED 19 pt.
        static let bottomPadding: CGFloat = ThingsPlatform.value(ios: 16, mac: 19)
        /// Minimum height of the notes area (empty "Notes" placeholder). Mac MEASURED 60 pt.
        static let notesMinHeight: CGFloat = ThingsPlatform.value(ios: 44, mac: 60)
        /// Gap between the title line and the notes area. Mac MEASURED 7 pt.
        static let titleNotesGap: CGFloat = 7
        /// Trailing padding of the icon toolbar. Mac MEASURED 28 pt.
        static let toolbarTrailingPadding: CGFloat = 28
        /// Spacing between toolbar icons. Mac MEASURED 32 pt centre to centre.
        static let toolbarIconPitch: CGFloat = 32
        static let toolbarIconSize: CGFloat = 13
        static let shadowRadius: CGFloat = ThingsPlatform.value(ios: 12, mac: 12)
        static let shadowOffsetY: CGFloat = 3
        /// Gap from the card bottom to the centre of the breadcrumb. Mac MEASURED 17 pt.
        static let breadcrumbGap: CGFloat = 8
        static let breadcrumbHeight: CGFloat = 18
        /// Breadcrumb right edge sits this far inside the card. Mac MEASURED 17 pt.
        static let breadcrumbTrailingInset: CGFloat = 17
    }

    enum Chip {
        static let horizontalPadding: CGFloat = ThingsPlatform.value(ios: 8, mac: 7)
        static let verticalPadding: CGFloat = ThingsPlatform.value(ios: 3, mac: 2)
        /// Tag pill height in a Mac row. MEASURED 16 pt.
        static let tagHeight: CGFloat = 16
        static let tagBorderWidth: CGFloat = 0.75
        /// Filter bar pill height. MEASURED 20 pt.
        static let filterHeight: CGFloat = 20
        /// Date pill in front of a project row ("Thu"). MEASURED 16 pt high.
        static let datePillHeight: CGFloat = 16
        static let datePillCornerRadius: CGFloat = 4
    }

    enum Icon {
        /// List icon (Home row, header, sidebar).
        static let list: CGFloat = ThingsPlatform.value(ios: 24, mac: 18)
        /// Icon in the big list header. Mac MEASURED 22 pt (icon 32..54 in 2x crop).
        static let header: CGFloat = ThingsPlatform.value(ios: 28, mac: 22)
        /// Icon in a section header (moon, calendar, box). Mac MEASURED 14 pt.
        static let section: CGFloat = 14
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
        /// Space above the big list title. Mac ESTIMATED: title centre 84 pt, toolbar 52 pt.
        static let topPadding: CGFloat = ThingsPlatform.value(ios: 8, mac: 18)
        /// Space under the big list title when nothing else sits in the header. Mac MEASURED 27 pt.
        static let bottomPadding: CGFloat = ThingsPlatform.value(ios: 12, mac: 26)
        static let iconTitleSpacing: CGFloat = ThingsPlatform.value(ios: 10, mac: 8)
        /// Space above a section header (previous row bottom to header top).
        /// Mac MEASURED between 34 and 46 pt, 40 used.
        static let sectionTopPadding: CGFloat = ThingsPlatform.value(ios: 20, mac: 40)
        /// Space between the rule and the first row. Mac MEASURED 9 to 10 pt.
        static let sectionBottomPadding: CGFloat = ThingsPlatform.value(ios: 6, mac: 9)
        /// Gap between the section title line and its rule. Mac MEASURED 6 pt.
        static let sectionRuleGap: CGFloat = 6
        /// Rule under a section header. Mac MEASURED one device pixel (0.5 pt).
        static let sectionRuleThickness: CGFloat = 0.5
        /// Horizontal inset of the section rule inside the row width. Mac MEASURED 6 to 8 pt.
        static let sectionRuleInset: CGFloat = 7
        /// Hairline under a project heading.
        static let headingRuleThickness: CGFloat = 0.5
        /// Space between the title and the calendar box in Today. Mac MEASURED 13 pt.
        static let calendarBoxTopGap: CGFloat = 13
        /// Space between the filter bar and the first row when the bar is shown. Mac MEASURED 46 pt
        /// from the pill bottom to the first row top.
        static let filterBarBottomGap: CGFloat = 46
    }

    enum CalendarBox {
        /// Mac MEASURED: 1000 x 66 for three lines.
        static let cornerRadius: CGFloat = 10
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 9
        static let linePitch: CGFloat = 16
        static let barWidth: CGFloat = 3
        static let barHeight: CGFloat = 11
        /// Inset of the box from the row width. MEASURED 10 pt.
        static let outerInset: CGFloat = 10
        /// Gap between the box and the filter bar. MEASURED 16 pt.
        static let bottomGap: CGFloat = 16
    }

    enum FooterLink {
        /// Space above "Hide later items". Mac MEASURED 38 pt from the last row bottom.
        static let topPadding: CGFloat = 38
        /// Space between "Hide later items" and "Show N logged items". MEASURED 23 pt.
        static let stackGap: CGFloat = 8
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

    /// Drag reorder on the Mac list.
    enum Reorder {
        /// Distance before a press becomes a drag.
        static let minimumDistance: CGFloat = 5
        /// Shadow under the lifted row.
        static let liftShadowRadius: CGFloat = 10
        static let liftShadowOffsetY: CGFloat = 4
        /// Thickness of the accent insertion line shown at the drop slot.
        static let insertionLineThickness: CGFloat = 2
    }
}
