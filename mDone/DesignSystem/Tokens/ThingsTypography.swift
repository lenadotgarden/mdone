import SwiftUI

// Fonts (docs/things-spec/01-design-tokens.md section 3).
// iOS uses Dynamic Type text styles. macOS uses fixed point sizes (the Mac
// Things text size slider is not modelled yet). All sizes are [FROM-MEMORY];
// [UNSURE] ones are tagged.

enum ThingsTypography {
    /// Big list title (Today, project title). 34 pt iOS, 26 pt Mac. [UNSURE]
    static let listTitle: Font = ThingsPlatform.value(
        ios: Font.largeTitle.weight(.bold),
        mac: Font.system(size: 26, weight: .bold))

    /// To-do title in a list. 17 pt iOS, 13 pt Mac.
    static let todoTitle: Font = ThingsPlatform.value(
        ios: Font.body,
        mac: Font.system(size: 13, weight: .regular))

    /// Notes and notes preview. 15 pt iOS, 12 pt Mac.
    static let notes: Font = ThingsPlatform.value(
        ios: Font.subheadline,
        mac: Font.system(size: 12, weight: .regular))

    /// Project heading. 20 pt iOS, 16 pt Mac, semibold. [UNSURE]
    static let heading: Font = ThingsPlatform.value(
        ios: Font.title3.weight(.semibold),
        mac: Font.system(size: 16, weight: .semibold))

    /// Section title such as This Evening. 17 pt iOS, 13 pt Mac, semibold.
    static let sectionTitle: Font = ThingsPlatform.value(
        ios: Font.headline,
        mac: Font.system(size: 13, weight: .semibold))

    /// Big day number in Upcoming. 28 pt iOS, 26 pt Mac, bold. [UNSURE]
    static let upcomingDayNumber: Font = ThingsPlatform.value(
        ios: Font.title.weight(.bold),
        mac: Font.system(size: 26, weight: .bold))

    /// Day name next to the Upcoming number. 15 pt iOS, 13 pt Mac. [UNSURE] on Mac
    static let upcomingDayName: Font = ThingsPlatform.value(
        ios: Font.subheadline,
        mac: Font.system(size: 13, weight: .regular))

    /// Sidebar and Home row title. 17 pt iOS, 13 pt Mac.
    static let sidebarRow: Font = ThingsPlatform.value(
        ios: Font.body,
        mac: Font.system(size: 13, weight: .regular))

    /// Counters next to list rows. 15 pt iOS, 12 pt Mac.
    static let counter: Font = ThingsPlatform.value(
        ios: Font.subheadline.monospacedDigit(),
        mac: Font.system(size: 12, weight: .regular).monospacedDigit())

    /// Tag pill text. 13 pt iOS, 11 pt Mac.
    static let tagPill: Font = ThingsPlatform.value(
        ios: Font.footnote,
        mac: Font.system(size: 11, weight: .regular))

    /// Deadline label ("5 days left"). 13 pt iOS, 11 pt Mac.
    static let deadline: Font = ThingsPlatform.value(
        ios: Font.footnote,
        mac: Font.system(size: 11, weight: .regular))

    /// Empty state headline. [PROPOSAL]
    static let emptyTitle: Font = ThingsPlatform.value(
        ios: Font.title3.weight(.semibold),
        mac: Font.system(size: 16, weight: .semibold))

    /// Empty state message. [PROPOSAL]
    static let emptyMessage: Font = notes
}
