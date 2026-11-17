# Things 3 spec (Cultured Code) for the mDone redesign

Target: SwiftUI engineers who have never seen Things. Goal: reproduce the UI/UX of Things 3 move for move (iPhone + macOS), with the app renamed and the icons redrawn. Personal use.

Language: English. Things UI terms and labels stay as the app displays them (Inbox, Today, This Evening, Upcoming, Anytime, Someday, Logbook, Magic Plus, Quick Entry, Quick Find, Type Travel, When, Deadline...).

## Reliability convention

Every non-trivial claim carries a tag:

- `[VERIFIED url]`: read on the cited page (textual aspect; exact visual values are never given by Cultured Code).
- `[FROM-MEMORY]`: knowledge of the app, not re-checkable without a device. Reliable for structure and behaviour, approximate for pixels.
- `[UNSURE]`: to be validated before freezing. Recap list at the end of this file.
- `[PROPOSAL]`: design choice of our fork, not a fact about Things (mostly in 01 for the SwiftUI values and in 07).

Golden rule: the pixel, hex and duration values in 01 are `[FROM-MEMORY]` or `[PROPOSAL]` estimates unless stated otherwise. Cultured Code publishes neither a visual spec nor code. Calibrate by visual comparison against screenshots of the app as soon as a device is available.

## Files

| File | Content |
|-|-|
| 00-README.md | this index, sources, [UNSURE] |
| 01-design-tokens.md | colours, type, spacing, radii, icons, haptics, animations |
| 02-ios-screens.md | every iPhone screen with ASCII wireframes |
| 03-ios-gestures.md | every iOS gesture and its exact result |
| 04-macos-screens.md | Mac window, Quick Entry, Quick Find, popovers, menus, preferences, drag and drop |
| 05-macos-shortcuts.md | complete Mac keyboard shortcut table (verified) |
| 06-behaviors-rules.md | semantic rules (lists, dates, repetition, Logbook, tags, empty states) |
| 07-vikunja-mapping.md | how Things concepts map onto Vikunja v2, gaps, conventions |
| 08-drag-and-drop.md | Mac drag and drop model: payload, insertion slot, planes, sidebar, accessibility |

## Sources

All read on 2026-11-16 with `curl` (text extraction from the HTML).

Cultured Code support pages (base https://culturedcode.com/things/support/articles/):

- 2785159 Keyboard Shortcuts for Mac (complete table, source of 05)
- 2803582 Using Gestures (iPhone, iPad, Vision)
- 4001304 An In-Depth Look at Today, Upcoming, Anytime, and Someday
- 2803579 Scheduling To-Dos in Things
- 2803564 Using Repeating To-Dos ; 3743733 Choosing a Repeat Pattern
- 2803581 Using Tags
- 2803584 Searching and Navigating with Quick Find
- 2803583 Connecting Your Calendars
- 9780167 Using Natural Language Input
- 2803585 Setting a Reminder
- 2803567 Using Things' Widgets
- 2249437 Adding To-Dos From Anywhere On Your Mac Through Quick Entry
- 4438545 Writing Notes in Things ; 4651820 Markdown Guide
- 8537373 Changing the Text Size
- 2803566 Using the OS Share Feature
- 2877019 Speaking to Siri ; 2157909 Using Things on Apple Watch
- 1059358 Discover Great Features (article index)

Others: https://culturedcode.com/things/features/ (page "What's new in the all-new Things": Magic Plus, Jump Start, Quick Find, Type Travel, Slim Mode, progress pies, haptics, animations).

Memory: general knowledge of Things 3 for iOS/macOS (up to roughly the end of 2025). The screenshots on the site are videos, unusable here: no pixel value could be measured.

Other repo files consulted: `docs/vikunja-api-inventory.md` (v2 API, minimum Vikunja 2.5.0).

## Writing constraints

No em dash and no doubled hyphen: single hyphen only. The ASCII wireframes use `|`, `+`, `_`, `=` for the lines.

## Recap list of [UNSURE]

See the "Recap of [UNSURE]" section at the end of each file from 01 to 07. Summary of the most important ones:

1. Exact hex values of all the colours (01).
2. Exact sizes and weights of list titles, headings, notes (01).
3. Exact row heights, corner radii (01).
4. Real animation curves and durations (01).
5. Exact empty state texts per list (06).
6. Exact position of the buttons in the bottom bar of the iPhone Home screen (02).
7. Exact order of the actions in the "..." menus (02).
8. Behaviour of the Today order in Vikunja (07).
