# 02 - iPhone screens

Legend: `[VERIFIED url]` / `[FROM-MEMORY]` / `[UNSURE]`. The wireframes are indicative (approximate proportions). Visual tokens in 01. Detailed gestures in 03. Business rules in 06.

iPhone navigation plan `[FROM-MEMORY]`:

```
Home (main lists view)
 +- Inbox | Today | Upcoming | Anytime | Someday | Logbook
 +- Area -> Project
 +- Quick Find (pull-down)  +- Settings
List -> open to-do (card in place, no push)
Project -> headings, to-dos
```

## 1. Home (list of lists)

On iPhone the root is the "main lists view" ; on iPad/Vision/Duo it is a sidebar `[VERIFIED https://culturedcode.com/things/support/articles/4001304/]` ("sidebar (Mac/iPad/iPhone Duo/Vision) and the main lists view (iPhone)").

```
+______________________________________+
|                                      |   (no title ; pull-down area = Quick Find)
|  [tray]  Inbox                    3  |   white, grey counter
|                                      |   (vertical gap ~ 16 pt)
|  [star]  Today                   12  |   counter: number of to-dos
|  [cal ]  Upcoming                    |
|  [stack] Anytime                     |
|  [box ]  Someday                     |
|                                      |
|  [book]  Logbook                     |
|                                      |
|  [pie] Project (no area)             |   projects without an area first
|  [pie] Other project                 |
|                                      |
|  [area] Work                         |   Area in bold / grey
|     [pie] Project A                  |   projects nested under their Area
|     [pie] Project B                  |
|  [area] Home                         |
|                                      |
|  [+] New List                [gear]  |   bottom bar: button on the left, Settings on the right
+______________________________________+
```

- Order and grouping: Inbox alone ; then Today, Upcoming, Anytime, Someday ; then Logbook ; then projects without an area ; then Areas with their projects `[FROM-MEMORY]`. The default lists can be neither renamed, nor deleted, nor reordered `[VERIFIED https://culturedcode.com/things/support/articles/2803579/]`.
- Projects with a future start date or in Someday disappear from this view as long as they are inactive `[VERIFIED 4001304]`.
- Counters: Inbox (number of items), Today (number ; coloured when items are overdue/near deadline) `[FROM-MEMORY]`. The other lists have no counter `[UNSURE]`.
- Tap on a row: pushes the list (standard iOS transition, edge-swipe back).
- "New List" (bottom left): sheet offering New Project / New Area `[FROM-MEMORY]` ; "Magic Plus" dragged inside this view creates a project directly in an Area `[VERIFIED https://culturedcode.com/things/support/articles/2803582/]`.
- Settings: gear icon at the bottom right `[UNSURE]` (exact position).
- Pull-down: reveals the Quick Find search bar `[VERIFIED 2803582]`.
- Edit mode: a long press on a list lifts it (drag) ; a left swipe on a project or an area selects it (action bar at the bottom) `[VERIFIED 2803582]`.
- When Today is emptied, the Today row keeps its star icon (greyed out) `[UNSURE]`.

## 2. Generic list screen (common structure)

```
+______________________________________+
| < Back                       [...]   |  transparent nav bar, '...' = list menu
|                                      |
|  [star] Today                        |  large title (34 pt bold) + icon
|                                      |
|  [ ] Buy bread            #errand    |  to-do row
|  [ ] Call Kate                       |
|  [ ] Report              flag 3 d    |
|                                      |
|                              ( + )   |  Magic Plus
+______________________________________+
```

- The large title scrolls with the list ; when you scroll down, the compact title appears in the top bar ; tapping it brings up the navigation menu (Quick Find) `[VERIFIED 2803584]` ("When you're scrolled down in a list, tap the list name at the top").
- "..." (More) button at the top right: Share, Filter by Tag, etc. `[VERIFIED 2803581]` (Filter by Tag via "More") and `[VERIFIED 2803566]` (Share via "More"). Exact menu content `[UNSURE]`.
- Filter by tag: green bar at the top when the filter is active, `x` button to clear it `[VERIFIED 2803581]`.

### To-do row (resting state)

```
 [ ]  To-do title
      One-line note preview (grey, optional)
      [tag][tag]                 flag 5 days left
```

- Checkbox on the left. Title 17 pt. If the to-do has a note: small note icon `[FROM-MEMORY]` or preview line (one line maximum) `[UNSURE]`. If it has a checklist: "x/y" indicator `[FROM-MEMORY]`.
- Tags: grey pills to the right of the title or below it `[FROM-MEMORY]`. Only tags set directly are shown, not inherited ones `[VERIFIED 2803581]`.
- Deadline: flag + "N days left" / "Today" / "N days ago", red from D-day onwards `[FROM-MEMORY]` ; "The days remaining until the deadline will show next to the to-do and count down" `[VERIFIED 2803579]`.
- Yellow star in front of the to-do in Anytime and projects when it is in Today `[VERIFIED 4001304]`.
- Reminder: time shown (e.g. "9:00") next to the title in Today `[UNSURE]`.
- Completed item: filled check, title struck through in grey, stays visible briefly then goes to the Logbook `[FROM-MEMORY]`.

## 3. Inbox

- Title "Inbox", blue tray icon.
- Content: unprocessed items, manual order, new ones at the bottom `[FROM-MEMORY]`.
- Temporary section at the bottom: "x to-dos were moved out of the Inbox", disappears when you enter another list `[VERIFIED 4001304]`.
- Any to-do moved into a list or given a date leaves the Inbox `[VERIFIED 4001304]`.
- No specific "Move to" row ; clearing When + moving to "No Project" sends it back to Anytime `[VERIFIED 2803579]` ("Anytime from the Inbox, use Move > No Project").
- Empty state text `[UNSURE]` (see 06).

## 4. Today

```
+______________________________________+
| <                            [...]   |
|  [star] Today                        |
|                                      |
|  09:00  Team meeting          (cal)  |  calendar events section (if enabled)
|  14:00  Dentist                      |
|  ____________________________________|
|  [ ] To-do A                         |
|  [ ] To-do B                         |
|  [ ] To-do C           flag 1 day    |
|                                      |
|  [moon] This Evening                 |  section header
|  [ ] Read                            |
|  [ ] Call mom                        |
|                              ( + )   |
+______________________________________+
```

- "Think of it as a filter across the entire app": start date, deadline or repeat rule = today `[VERIFIED 4001304]`.
- Calendar events section at the top if Settings > Calendar Events is enabled, for the chosen calendars ; local events are read-only, Apple Calendar only `[VERIFIED https://culturedcode.com/things/support/articles/2803583/]`.
- This Evening: section at the bottom of Today with its own icon/title `[VERIFIED 4001304]`.
- Setting: group Today by project/area (Settings > General) `[VERIFIED 4001304]` ("Enable this in Things > Settings > General").
- Items whose deadline has arrived also appear here `[VERIFIED 4001304]`.
- Manual order by drag `[VERIFIED 4001304]` ("drag and drop to-dos into the order").
- Quick reschedule: right swipe -> When `[VERIFIED 2803582]`.

## 5. Upcoming

```
+______________________________________+
|  [cal] Upcoming                      |
|                                      |
|  Tomorrow                            |  coming week: 7 days listed, starting tomorrow
|    [ ] To-do                         |
|  Wed 18                              |
|    (empty or header row only)        |
|  Thu 19                              |
|  ...                                 |
|  Next week / following months        |  then grouped by weeks then by months
|  December                            |
|    [ ] Scheduled on the 3rd          |
+______________________________________+
```

- "At the top of Upcoming, you'll see the next seven days listed separately, starting with tomorrow" `[VERIFIED 4001304]`.
- Contains scheduled to-dos (future start date), upcoming repeats, deadlines, calendar events `[VERIFIED features]` ("scheduled to-dos, repeating to-dos, deadlines, and calendar events").
- Reschedule by dragging and dropping onto another day `[VERIFIED 4001304]`.
- Beyond 7 days: groups by week then by month `[FROM-MEMORY]` `[UNSURE]` (exact granularity).
- Projects with a future start date are listed there too `[VERIFIED 4001304]`.
- Deadline: the to-do appears in Upcoming on the day of its deadline, with a flag `[VERIFIED 4001304]`.

## 6. Anytime

- Title "Anytime", teal icon.
- Order: loose to-dos (no parent) at the top, then grouped under their direct parent (project or area) ; a list without any active to-do does not appear `[VERIFIED 4001304]`.
- To-dos from Today carry the yellow star `[VERIFIED 4001304]`.
- Also contains to-dos with a deadline (active ones) `[VERIFIED 4001304]`.

## 7. Someday

- Title "Someday", box icon.
- Dimmed content (visually set back) `[VERIFIED 4001304]`.
- Someday projects hidden from Home and the sidebar `[VERIFIED 4001304]`.
- Same groupings as Anytime `[FROM-MEMORY]`.

## 8. Logbook

- Title "Logbook", green book/check icon.
- Groups by period (Today, Yesterday, months/years) `[FROM-MEMORY]` `[UNSURE]`.
- Completed or cancelled items (cancelled = cross) `[VERIFIED 4001304]` ("completed or cancelled").
- Kept indefinitely ; bulk deletion via selection (Cmd A on an external keyboard or multi-select) ; deleting on iOS is permanent `[VERIFIED 4001304]`.
- Completed projects are listed too ; "Logged Projects" via Quick Find `[VERIFIED 2803584]`.
- Auto-archive: "Move completed to Logbook" immediately or deferred (Mac `Shift-Cmd-Y`) `[VERIFIED https://culturedcode.com/things/support/articles/2785159/]`.

## 9. Area view

```
+______________________________________+
| <                            [...]   |
|  [area] Work                         |  bold title + Area icon
|  Area notes (optional)               |  (Markdown text area)
|  [tag]                               |
|                                      |
|  [ ] Loose to-do of the area         |  to-dos directly in the area
|  [ ] Other                           |
|  ____                                |
|  [pie] Project A      (n remaining)  |  projects of the area (pies)
|  [pie] Project B                     |
+______________________________________+
```

- An Area holds loose to-dos and projects `[FROM-MEMORY]`.
- "More > Add Tags" to tag the area ; items inherit the tag `[VERIFIED 2803581]`.
- No checkbox on an Area (never "completed") `[FROM-MEMORY]`.
- When Magic Plus is dragged inside Home, a new project is created in the Area `[VERIFIED 2803582]`.
- A moved Area takes its projects with it `[VERIFIED 2803582]`.

## 10. Project view

```
+______________________________________+
| <                            [...]   |
|  [pie] Project title                 |  bold title 28-34 pt, pie on the left
|  Project notes (Markdown)            |
|  [tag]  [flag deadline]  [when]      |
|                                      |
|  [ ] To-do without heading           |
|  [ ] To-do                           |
|                                      |
|  Heading 1  ________________________ |  heading: accent text + line
|  [ ] To-do under heading             |
|  [ ] To-do                           |
|                                      |
|  Heading 2  ________________________ |
|  [ ] ...                             |
|                                      |
|  (completed to-dos: "x completed" link?)  [UNSURE]
+______________________________________+
```

- Header: progress pie + title ; notes ; deadline/when ; tags. `[FROM-MEMORY]`.
- Project "..." menu: Add Tags, Repeat, Share, Move?, Complete Project, Delete `[VERIFIED 2803564]` (Repeat), `[VERIFIED 2803581]` (Add Tags), `[VERIFIED 2803566]` (Share) ; the rest `[UNSURE]`.
- Headings: group the to-dos ; can be archived with their content ; draggable with their group `[VERIFIED features]` ("archive your heading and all of its to-dos"). A heading has its own menu (Archive, Move, Delete...) `[FROM-MEMORY]`.
- Inside a project, inactive to-dos (future start date) are placed below the active ones `[VERIFIED 4001304]`.
- A project to-do that is in Today carries the star `[VERIFIED 4001304]`.
- Creating a heading: drag Magic Plus to the far left edge of the screen `[VERIFIED 2803582]`.
- Completing a project: see 06.
- Project with a deadline: flag and remaining days to the right of the title `[FROM-MEMORY]`.

## 11. Inline to-do editor / open to-do

A tap on a to-do opens it in place: white card with a shadow, the keyboard appears for the title `[VERIFIED features]`.

```
+______________________________________+
|  +__________________________________+|
|  | [ ] To-do title                   ||  title field, 17 pt
|  |     Notes                        ||  note area (Markdown), placeholder "Notes"
|  |                                  ||
|  |     [ ] Checklist item    ===    ||  grip on the right to reorder
|  |     [ ] Other item        ===    ||
|  |                                  ||
|  |  [tag] [tag]                     ||  tag pills
|  |  [star] Today          flag 5 d  ||  When on the left, Deadline on the right
|  |                                  ||
|  |  (cal) (tag) (list) (flag)  ...  ||  icon bar: When, Tags, Checklist, Deadline, "..."
|  +__________________________________+|
+______________________________________+
|  iOS keyboard                  (v)   |  button to dismiss the keyboard
+______________________________________+
```

Details `[FROM-MEMORY]` unless stated:

- Empty fields are "tucked into a corner": only the icon row (When/calendar, Tags, Checklist, Deadline/flag) is visible at the bottom of the card as long as they are unfilled `[VERIFIED features]`.
- Fields: Title, Notes, Tags, When, Deadline, Checklist, plus a "..." (More) menu at the bottom right with: Repeat, Move, Share, Find in Text, Manage Tags, Duplicate, Delete `[VERIFIED 2803564]` (More > Repeat), `[VERIFIED 4438545]` ("..." > Find in Text), `[VERIFIED 2803581]` (Manage Tags), `[VERIFIED 2803566]` (More > Share). Order `[UNSURE]`.
- Button at the top right to dismiss the keyboard `[VERIFIED 2803564]` ("Tap the button in the upper right to dismiss the keyboard").
- Bottom bar: More on the left? The articles say "More > Repeat at the bottom of your screen" `[VERIFIED 2803564]` so More sits in the bottom bar.
- Formatting in notes: press inside the note area -> "Format" popover with Markdown styles, ">" for more options `[VERIFIED 4438545]`.
- Notes accept Markdown: `**bold**`, `*italic*`, `::highlight::`, `#` headings, `-` lists, `1.`, `- [ ]` tasks, `[...]()` links, `` ` `` code `[VERIFIED 2785159]`. Links are displayed in their full form `[VERIFIED 4438545]`.
- No images/attachments `[VERIFIED 4438545]`.
- Checklist: tap on the circle = complete ; left swipe = delete ; grip on the right (three bars) = reorder via long press `[VERIFIED 2803582]`. Pasting a bulleted list converts it into a checklist `[VERIFIED features]`. Mac: `Shift-Cmd-C` new checklist `[VERIFIED 2785159]`.
- Repeat lives in "More" ; when a template is opened: blue arrow `[VERIFIED 2803564]`.
- A copy of a repeating to-do displays "This is a copy of a repeating to-do", tappable through to the template `[VERIFIED 2803564]`.
- Closing: tap outside the card or the Done button ; automatic save `[FROM-MEMORY]`.
- Creation: a brand new to-do opens straight away in edit mode with the keyboard `[FROM-MEMORY]`.
- In the Inbox via Magic Plus, the Quick Entry popover lets you pick another list by tapping "Inbox" `[VERIFIED 2803582]` ("Tap Inbox in the Quick Entry popover to file your to-do in another list").

## 12. When picker (Jump Start)

Opened via the to-do's calendar icon, a tap on the displayed date, a right swipe on the row, or the `Cmd-S` shortcut `[VERIFIED 2803579]`. On iPhone: sheet from the bottom (compact popover) `[FROM-MEMORY]`.

```
+______________________________________+
|  (pull-down: NL text field)          |  "Pull down in the date picker to type"  [VERIFIED 2803582]
|                                      |
|  [star]  Today                       |
|  [moon]  This Evening                |
|  [box]   Someday                     |
|                                      |
|  < November 2026 >                   |  monthly calendar grid
|  M  T  W  T  F  S  S                 |  (week starts by region)
|  ..  ..  16 17 18 ..                 |  today circled/starred
|                                      |
|  [+] Add Reminder                    |  -> time picker (barrel) then Set
|  [x] Clear                           |
+______________________________________+
```

- Options: Today, This Evening, Someday ; clicking a date in the grid = Upcoming ; Clear = removes all scheduling and puts it in Anytime `[VERIFIED 2803579]`.
- Add Reminder: "Tap -> + Add Reminder, set a reminder time from the time picker, tap Set -> Done" `[VERIFIED https://culturedcode.com/things/support/articles/2803585/]`. The time picker is a "barrel" (wheel) `[VERIFIED features]`.
- Natural language: pull down inside the picker to type ("tues 8am") then the blue Return key `[VERIFIED https://culturedcode.com/things/support/articles/9780167/]`. Examples in 06.
- Notification snooze: 15 min, 1 h, 3 h, until the next day `[VERIFIED 2803585]`.
- More content: after a selection the popover closes (the article says it can close as soon as a date + reminder is set, hence the use of NL) `[VERIFIED 2803585]`.

## 13. Deadline picker

- Flag button inside the open card. Calendar popover with a Clear button `[VERIFIED 2803579]`.
- No reminder for a deadline `[VERIFIED 2803585]`.
- NL inside the iPhone Deadline picker requires a hardware keyboard `[VERIFIED 9780167]` (original limitation ; not necessarily something to reproduce `[PROPOSAL]`).

## 14. Tag picker

- Popover/sheet with the list of tags (checkboxes), "New Tag" at the top, Done button `[VERIFIED 2803581]`.
- Pull-down to search for a tag `[VERIFIED 2803582]`.
- "Manage Tags": create, delete, rename, group (blue button to the right of the tag > Group), reorder via long press `[VERIFIED 2803581]`.
- Multi-select: bottom bar More > Set Tags `[VERIFIED 2803581]`.
- Tags inheritable from a list `[VERIFIED 2803581]`.

## 15. Move sheet

- Opened by More > Move (selected to-do/list) `[FROM-MEMORY]`.
- Search bar at the top (filters as you type) `[VERIFIED features]` ("Quick Move ... Type to filter down the list").
- List: Inbox, Areas and projects (visual nesting), option "No Project" / "No Area"... `[VERIFIED 2803579]` ("Move > No Project").
- Can also target a heading inside a project `[FROM-MEMORY]` ; the Mac Move dialog lets you add to inactive projects `[VERIFIED 4001304]`.

## 16. Quick Find (search)

- Triggered by pulling down on a list `[VERIFIED 2803584]`. On iPad/Duo always at the top of the sidebar.
- First level: names of to-dos, projects, areas, tags, default lists, headings `[VERIFIED 2803582]`.
- "Continue Search" at the bottom extends to notes, checklists, Logbook `[VERIFIED 2803584]`.
- Navigation: type the name of a list (e.g. "tod") then pick it to go there ; also works for special lists: Tomorrow, Deadlines, Repeating, All Projects, Logged Projects `[VERIFIED 2803584]`.
- Typing a tag gives an app-wide filter `[VERIFIED features]`.
- One result = a row with an icon and a title ; tap = go to the item `[FROM-MEMORY]`.

## 17. Settings

Screen reachable from Home. Entries `[FROM-MEMORY]` unless stated:

- Things Cloud (account, sync) `[VERIFIED https://culturedcode.com/things/support/articles/2803586/]` (sync service).
- General: Group Today by project/area `[VERIFIED 4001304]`, badge count, "Add new to-dos to the top/bottom" `[UNSURE]`.
- Appearance: Light/Dark/Black theme, Custom text size `[VERIFIED 8537373]`, widget appearance `[VERIFIED 2803567]`.
- Calendar Events: Show Calendar Events switch, list of calendars, Close button at the top right `[VERIFIED 2803583]`.
- Notifications / Reminders, Siri AI (beta) `[VERIFIED https://culturedcode.com/things/support/articles/2877019/]`.
- Mail to Things, Shortcuts, About / Help `[FROM-MEMORY]`.
- Typing "Settings" in Quick Find leads there `[VERIFIED 2803584]` ("Access Settings ... by typing their name").

## 18. Magic Plus

- Blue `+` button, at the bottom right of every list `[FROM-MEMORY]`.
- Tap: new to-do at the top/bottom of the current list (depending on the setting `[UNSURE]`), in edit mode ; inside Today -> start date Today ; inside Upcoming -> that day ; inside Inbox -> Inbox ; inside a project -> in the project `[FROM-MEMORY]`.
- Drag: "Drag the Magic Plus Button anywhere ... your new to-do will be inserted where you drop it" `[VERIFIED 2803582]` ; inside Today at the desired spot, under a heading, in the right day of Upcoming `[VERIFIED features]`.
- Drag towards the Inbox target at the bottom left: creates it in the Inbox whatever the current list `[VERIFIED 2803582]`.
- Drag towards the left edge inside a project: creates a heading at that spot `[VERIFIED 2803582]`.
- Drag inside Home: creates a project in the Area you drop on `[VERIFIED 2803582]`.
- Extended long press -> same effect as drag `[UNSURE]`.
- In a list filtered by tag, the new to-do receives the tag `[UNSURE]`.

## 19. Multi-select mode

- Entry: left swipe on a to-do (selects it), or tap on others. "swiping a to-do not only shows you the actions you can perform, but it also immediately enters multi-select mode" `[VERIFIED features]`.
- Selection circles on the right ; dragging your finger along the right edge selects a group `[VERIFIED 2803582]`.
- Bottom bar: actions (When, Move, Tags (More > Set Tags), Duplicate, Delete...) `[VERIFIED 2803581]` (More > Set Tags) ; exact list `[UNSURE]`.
- Long press on a selected item: drags the whole selection `[VERIFIED 2803582]`.
- Selecting Areas/projects: left swipe on a project or an area `[VERIFIED 2803582]`.
- Exit: Done button or empty tap `[UNSURE]`.

## 20. Share extension / adding from other apps

- iOS share sheet: "Add to Things" (extension) ; creates a to-do with a title, notes (URL) and a list choice ; Quick Entry style popover `[FROM-MEMORY]`.
- Outgoing share: More > Share on a to-do or list, plain text ; children's notes/tags not included `[VERIFIED https://culturedcode.com/things/support/articles/2803566/]`.
- Mail to Things (personal address) `[VERIFIED https://culturedcode.com/things/support/articles/1059358/]` (existence).
- Siri / Shortcuts / URL scheme: see sources `[VERIFIED 2877019]`.
- Widgets: Home/Lock Screen (Today, Upcoming, custom lists, tags), + button to the Inbox, interactive checkbox `[VERIFIED 2803567]`.
- Apple Watch: Today only, with checklists and headings `[VERIFIED https://culturedcode.com/things/support/articles/2157909/]`.

## Recap of [UNSURE]

Settings button position ; Home counters ; exact content of the "..." menus (list, project, to-do) ; multi-select action bar ; Logbook and Upcoming grouping beyond 7 days ; position (top/bottom) of new to-dos ; tags on Magic Plus inside a filtered list ; notes icon on the row ; exiting multi-select mode.
