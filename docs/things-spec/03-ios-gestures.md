# 03 - iOS gestures (iPhone, with iPad notes)

Official basis: https://culturedcode.com/things/support/articles/2803582/ (Using Gestures) `[VERIFIED]`. Every addition is marked.

## Gesture table

| Gesture | Where | Exact result | Source |
|-|-|-|-|
| Tap checkbox | to-do row | completes the to-do: check + struck-through title, then it goes to the Logbook ; tapping again during the delay undoes it | `[FROM-MEMORY]` |
| Tap on the row | list | opens the to-do in place (expand-to-edit), keyboard on the title | `[FROM-MEMORY]` |
| Tap on a project/area row | Home, Area | enters the list (push) | `[FROM-MEMORY]` |
| Right swipe on a to-do | list | opens the When picker (Today, This Evening, Someday, calendar, Add Reminder) | `[VERIFIED 2803582]` ("Swipe right to bring up When") |
| Left swipe on a to-do | list | selects the to-do and enters multi-select ; the bottom action bar appears | `[VERIFIED 2803582]` ("To select a to-do, swipe it to the left") |
| Swipe/tap on others | multi-select | adds to the selection | `[VERIFIED 2803582]` |
| Drag the finger down along the right edge | multi-select | selects a consecutive group | `[VERIFIED 2803582]` ("dragging your finger down the right side") |
| Left swipe on a project/area | Home | selects the project/area | `[VERIFIED 2803582]` |
| Long press on a to-do | list | lifts the item under the finger ; drag to reorder ; drop to place | `[VERIFIED 2803582]` ("tap and hold a to-do until it pops up under your finger") |
| Long press on a selected to-do | multi-select | all selected items gather under the finger and move together | `[VERIFIED 2803582]` |
| Drag a to-do onto another day | Upcoming | changes the start date | `[VERIFIED 4001304]` |
| Long press on a list | Home | lifts the list (Area: takes its projects with it) | `[VERIFIED 2803582]` |
| Long press on a heading | project | lifts the heading (with its to-dos for group moves) | `[VERIFIED 2803582]` + `[VERIFIED features]` |
| Left swipe on a heading | project | selects the heading | `[VERIFIED 2803582]` |
| Tap Magic Plus | any list | new to-do at the list's default location | `[VERIFIED features]` ("tapping it creates a new to-do") |
| Drag Magic Plus | list | new to-do inserted at the drop point | `[VERIFIED 2803582]` |
| Drag Magic Plus onto the Inbox target (bottom left) | list | new to-do in the Inbox | `[VERIFIED 2803582]` |
| Drag Magic Plus towards the left edge | project | new heading at that spot | `[VERIFIED 2803582]` |
| Drag Magic Plus | Home | new project in the hovered Area | `[VERIFIED 2803582]` |
| Pull-down | list | reveals the Quick Find search | `[VERIFIED 2803582]` |
| Pull-down inside the When picker | picker | natural language input field | `[VERIFIED 2803582]` |
| Pull-down inside the tag popover | tag picker | tag search field | `[VERIFIED 2803582]` |
| Long press on the grip (3 bars) | checklist | reorders the item | `[VERIFIED 2803582]` |
| Tap circle | checklist | completes the item | `[VERIFIED 2803582]` |
| Left swipe on a checklist item | checklist | deletes the item | `[VERIFIED 2803582]` |
| Tap on the scrolled list name | list | opens Quick Find navigation | `[VERIFIED 2803584]` |
| Edge swipe (left edge towards the right) | navigation stack | back to the previous view (standard iOS) | `[FROM-MEMORY]` |
| Shake | global | Undo (undoes the last action) / Redo | `[FROM-MEMORY]` |
| Pull-down on Home | Home | search | `[FROM-MEMORY]` |
| Long tap on Magic Plus then release without moving | list | same as a tap `[UNSURE]` | |
| Tap on the date (When) inside the card | open to-do | opens the When picker `[VERIFIED 2803579]` | |
| Tap on the flag | open to-do | opens the Deadline picker `[VERIFIED 2803579]` | |
| Tap on a tag | open to-do | opens the tag picker `[VERIFIED 2803581]` | |
| Tap on the sticky list title | list | "..." menu: see 02 | `[UNSURE]` |

## Behaviour details

### Right swipe (When)

- Reveals a calendar icon/action under the row ; a decisive swipe opens it ; the picker appears as a popover/sheet `[FROM-MEMORY]`.
- No "completes" right swipe: completion only goes through the checkbox `[FROM-MEMORY]`.

### Left swipe (selection)

- Shows no buttons along the row (no red "Delete"): it goes straight into selection mode and brings up the bottom bar. Source: "swiping a to-do not only shows you the actions you can perform, but it also immediately enters multi-select mode" `[VERIFIED features]`.
- Exit: clear all selections, or tap Done `[UNSURE]`.

### Drag and drop (reordering)

- The long press lifts the item (slight scale + shadow + haptic), the other rows part `[VERIFIED 2803582]` for the lift, animations `[FROM-MEMORY]`.
- Drop between two items = new position. Inside a project, dropping under a heading attaches the to-do to that heading `[FROM-MEMORY]`.
- Inside Today, dropping in the This Evening area puts it in This Evening `[FROM-MEMORY]`.
- Inside Upcoming, dropping on a day = reschedule `[VERIFIED 4001304]`.
- On iPad/Vision with the sidebar visible: dropping a to-do on a sidebar list moves it there `[VERIFIED 2803582]`.

### Magic Plus: drag details

1. Press on the button: it lifts under the finger (enlarged, shadow).
2. The finger moves ; an empty row opens at the insertion point, following the position, the other rows part `[FROM-MEMORY]`.
3. Special zones appear: Inbox target at the bottom left `[VERIFIED 2803582]` ; left edge for a heading inside a project `[VERIFIED 2803582]`.
4. Release: the to-do is created and opened in edit mode with the keyboard. Releasing in an invalid zone falls back to a tap `[UNSURE]`.

### Pull-down

- First threshold: the Search bar appears ; pulling further or touching the bar focuses it with the keyboard `[FROM-MEMORY]`.
- Inside a picker: NL text field `[VERIFIED 2803582]`.

### Shake

- iOS system undo ; the standard alert box "Undo ..." with the action name `[FROM-MEMORY]`. Redo available by shaking again `[UNSURE]`.

### Double tap

- No specific double tap in the sources `[UNSURE]` ; on Mac a double click opens a to-do `[VERIFIED 2803581]` ("Double-click a to-do to open it").

### iPad (out of scope, but useful for shared gestures)

- Drag between windows, drop onto the sidebar, sidebar collapse by swipe `[VERIFIED 2803582]` / `[VERIFIED features]` ("Slim Mode").

## Recap of [UNSURE]

Exiting multi-select ; Magic Plus invalid release behaviour ; double tap ; pull-down thresholds ; Redo by shake.
