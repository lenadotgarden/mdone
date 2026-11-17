# 04 - macOS screens

Legend `[VERIFIED url]` / `[FROM-MEMORY]` / `[UNSURE]`. The full shortcut list is in 05. Tokens in 01.

## 1. Main window

```
+________________________________________________________________+
| (o)(o)(o)   [<][>]   Today                     [ + ] [search]  |  title bar / toolbar
+________________________+_______________________________________+
| Inbox              3   |  [star] Today                         |
|                        |                                       |
| [star] Today      12   |  [ ] To-do A                          |
| [cal]  Upcoming        |  [ ] To-do B             #tag  flag 2d|
| [stack]Anytime         |  [ ] To-do C                          |
| [box]  Someday         |                                       |
|                        |  [moon] This Evening                  |
| [book] Logbook         |  [ ] To-do D                          |
|                        |                                       |
| [pie] Loose project    |                                       |
| v [area] Work          |                                       |
|    [pie] Project A     |                                       |
|    [pie] Project B     |                                       |
| > [area] Home          |                                       |
|                        |                                       |
| [+ New List]           |                           [ + ]       |  window footer
+________________________+_______________________________________+
```

- Sidebar: Inbox, Today, Upcoming, Anytime, Someday, Logbook, (Trash if not empty), then loose projects, then Areas with collapsible projects `[FROM-MEMORY]`. "The sidebar neatly groups projects underneath their area" `[VERIFIED https://culturedcode.com/things/features/]`.
- Counters to the right of the rows ; Today and Inbox at the very least `[FROM-MEMORY]`.
- Sidebar can be hidden: `Cmd-/` ; in "Slim" mode, the list title is clickable for navigation `[VERIFIED https://culturedcode.com/things/features/]` + `[VERIFIED https://culturedcode.com/things/support/articles/2785159/]` (`Cmd-/`, `Shift-Cmd-O` navigation popover).
- Toolbar can be hidden with `Opt-Cmd-T` `[VERIFIED 2785159]`.
- Multiple windows: `Ctrl-Cmd-N` new window ; Cmd-click to open a list/project/area in a new window ; Opt + New Window button opens the same list `[VERIFIED 2785159]`. Dragging to-dos between windows `[VERIFIED features]`.
- Expand/Collapse all Areas: Cmd-click on a chevron ; a single Area: Opt-Cmd-click `[VERIFIED 2785159]`.
- Toolbar: back/forward buttons, + button (new to-do), share button, search (appears as you type: Type Travel) `[FROM-MEMORY]` ; "New Window button is in the upper-right corner" `[VERIFIED 2785159]`.
- No permanent inspector pane: details open in place inside the list (card) `[FROM-MEMORY]`. There is therefore no third column, unlike other apps ; do not create one `[FROM-MEMORY]`.

## 2. Lists (same rules as iOS, see 02/06)

| List | Mac specifics `[FROM-MEMORY]` unless stated |
|-|-|
| Inbox | same as iOS ; "x to-dos were moved out of the Inbox" `[VERIFIED 4001304]` |
| Today | calendar events at the top `[VERIFIED 2803583]` ; This Evening as a section ; Settings > General to group by project/area `[VERIFIED 4001304]` |
| Upcoming | 7 separate days starting tomorrow `[VERIFIED 4001304]` ; drag and drop to reschedule `[VERIFIED 4001304]` ; calendar events too `[VERIFIED 2803583]` |
| Anytime | `[VERIFIED 4001304]` as on iOS |
| Someday | dimmed content `[VERIFIED 4001304]` |
| Logbook | `Shift-Cmd-Y` for "Move completed to Logbook" `[VERIFIED 2785159]` ; Trash for permanent deletion (empty the bin) `[VERIFIED 4001304]` |
| Area / Project | notes, tags, headings, progress ; "More" next to the title: Add Tags, Repeat, Share `[VERIFIED 2803581]` `[VERIFIED 2803564]` `[VERIFIED 2803566]` |
| Special lists | View > Go To: Tomorrow, Deadlines, Repeating, All Projects, Logged Projects `[VERIFIED 2803584]` |
| Filter bar | tag bar at the top of the list ; click = filter, "All" button = clear, Cmd-click = multi-tag (AND) `[VERIFIED 2803581]` ; `Ctrl-Esc` leaves the filter `[VERIFIED 2785159]` |

## 3. Open to-do (expanded)

Double-click, Return, or clicking an already selected title opens it `[VERIFIED 2803581]` (double-click) / `[VERIFIED 2785159]` (Return opens).

```
+______________________________________________________________+
|  [ ]  To-do title                                            |
|       Notes (Markdown)                                       |
|                                                              |
|       [ ] checklist item                                     |
|       [ ] item                                               |
|                                                              |
|  [tag][tag]                          [star Today]  [flag 5d] |
|  [Tags] [Checklist] [When]  [Deadline]              [More]   |  action bar
+______________________________________________________________+
```

- Fields and buttons: Tags (click -> input field, Return), When, Deadline (flag), Checklist (`Shift-Cmd-C`), More (Share..., Repeat...) `[VERIFIED 2803581]` `[VERIFIED 2803566]` `[VERIFIED 2803564]`.
- "In the toolbar at the bottom of the window, click More > Share..." `[VERIFIED 2803566]`.
- Esc: closes and saves ; `Cmd-Return`: saves and closes `[VERIFIED 2785159]` ("In the main app, the Esc key collapses open to-dos and saves changes").
- Removing a tag: click the tag then Delete `[VERIFIED 2803581]`.
- Hovering in front of a to-do: a calendar button appears on the left ("hover your mouse in front of a to-do and click the calendar button") `[VERIFIED features]` (Jump Start).
- Find in Text (`Cmd-F` inside notes via Shift-Cmd-F) `[VERIFIED 2785159]`.
- Links: `Opt-Cmd-Return` opens the link under the cursor `[VERIFIED 2785159]`.
- A to-do copied from a repeating one: "This is a copy of a repeating to-do" link `[VERIFIED 2803564]`.

## 4. Popovers

### When (Jump Start), `Cmd-S`

```
+__________________________+
| [ type a date ...      ] |  NL field ("tues 8am", "17d") [VERIFIED 9780167]
| [star] Today             |
| [moon] This Evening      |
| [box]  Someday           |
|  < nov 2026 >            |
|  calendar month          |
| [+] Add Reminder         |
| [Clear]                  |
+__________________________+
```

- Type to filter/interpret ; Return to confirm `[VERIFIED 9780167]`.
- Add Reminder: time field then Done `[VERIFIED 2803585]`.
- The `Cmd-T/E/R/O` shortcuts bypass the popover `[VERIFIED 2785159]`.

### Deadline, `Shift-Cmd-D`

- Same calendar popover, with NL and a Clear button `[VERIFIED 9780167]` `[VERIFIED 2803579]`.

### Tags

- Popover with the tag list, checkboxes, search ; `Shift-Cmd-T` ; dedicated Window > Tags window (`Ctrl-Cmd-T`) to manage them, assign shortcuts, nest by drag, reorder `[VERIFIED 2803581]`.
- Drag and drop a to-do onto a tag or a tag onto a to-do `[VERIFIED 2803581]`.

### Move dialog (`Shift-Cmd-M`)

- Search field, list of Inbox, Areas, projects ; Enter to confirm ; can target headings and inactive projects `[VERIFIED 4001304]` + `[VERIFIED features]` ("Quick Move").

### Repeat (`Shift-Cmd-R`)

- Panel with mode (After completion / Daily / Weekly / Monthly / Yearly), interval, days selectable via the + button, "Add deadlines" with "days earlier", end date, OK `[VERIFIED 2803564]` `[VERIFIED 3743733]`.
- Rule menu (on the template): Edit Rule..., Create Next Copy, Show Previous Copy, Pause, Resume, Stop `[VERIFIED 2803564]`.

## 5. Quick Entry (global)

```
+__________________________________________+
| [ ] To-do title                          |
|     Notes                                |
|  [Inbox v]  [tags] [When] [Deadline]     |
|                          [Cancel] [Save] |
+__________________________________________+
```

- Default global shortcut: `Ctrl-Space` ; configurable in Things > Settings > Quick Entry `[VERIFIED https://culturedcode.com/things/support/articles/2249437/]`.
- Floating window near the cursor/centre `[FROM-MEMORY]`. Title, notes, destination list choice (Inbox by default), tags, When, Deadline ; "All the keyboard shortcuts ... work inside of Quick Entry as well" `[VERIFIED 2249437]`.
- Save / Cancel buttons ; `Esc` closes and discards ; `Cmd-Return` closes and saves `[VERIFIED 2249437]`.
- Tab navigation requires macOS "Keyboard Navigation" `[VERIFIED 2249437]`.
- Known bug: Apple blocks shortcuts with Shift as the only modifier (macOS 15.2) `[VERIFIED 2249437]`.

### Quick Entry with Autofill

- `Ctrl-Opt-Space` by default ; captures the link of the current Safari page, Mail message or Finder file into the to-do notes ; requires a "Helper" to be installed ; Settings > Quick Entry > "Enable shortcut for Quick Entry with Autofill" `[VERIFIED 2249437]`.
- Can file directly under a heading `[VERIFIED 2249437]`.

## 6. Quick Find and Type Travel

- Type Travel: no key combination required, you just start typing anywhere ; the search opens immediately `[VERIFIED features]` ("As soon as you strike a key, the search is on") `[VERIFIED 2803584]`.
- `Cmd-F` also opens the search `[VERIFIED 2785159]`.
- Instant results: to-dos, projects, areas, tags, default/special lists, headings ; "Continue Search" for notes/checklists/Logbook `[VERIFIED 2803584]`.
- Navigation: type "tod" then Return -> Today ; "finan" -> area Finances ; "next action" -> heading `[VERIFIED 2803584]`.
- `Cmd-Return` or Cmd-click: open the result in a new window `[VERIFIED 2785159]`.
- Typing a tag: app-wide filter `[VERIFIED features]`.

## 7. Menu bar (app menus) `[FROM-MEMORY]`, details `[VERIFIED 2785159]`

| Menu | Main entries |
|-|-|
| Things | About, Settings... (`Cmd-,`), Services, Hide, Quit |
| File | New To-Do, New Project, New Heading, New Repeating To-Do `[VERIFIED 2803564]`, New Window, Close, Print |
| Edit | Undo/Redo, Cut/Copy/Paste, Duplicate, Select All, Find (Quick Find), Find in Text/Find and Replace, Markdown submenu, Spelling, Substitutions `[VERIFIED 4438545]` |
| Items | Complete, Cancel, When (Show When, Today, This Evening, Anytime, Someday), Add Deadline, Repeat..., Tags, Move..., Move to Top/Bottom, Show in Parent List `[VERIFIED 2785159]` `[VERIFIED 2803564]` ("Items > Repeat") |
| View | Show/Hide Sidebar, Toolbar, Go To (special lists: Tomorrow, Deadlines, Repeating, All Projects, Logged Projects), Show/Hide later items `[VERIFIED 2803584]` `[VERIFIED 2785159]` |
| Window | Minimize, Zoom, Tags (window) `[VERIFIED 2803581]`, new window |
| Help | Keyboard Shortcuts (support page) `[VERIFIED 2785159]` |

Any shortcut can be redefined in System Settings for any command visible in the menus `[VERIFIED 2785159]`.

## 8. Settings (Things > Settings) `[FROM-MEMORY]` unless stated

- General: Text Size (slider) `[VERIFIED 8537373]`, Group Today by project/area `[VERIFIED 4001304]`, Show Mac badge count / Dock counter `[UNSURE]`, Move completed to Logbook: Immediately / Daily / Manually `[UNSURE]`.
- Calendar Events: Show Calendar Events in Today and Upcoming checkbox + calendars `[VERIFIED 2803583]`.
- Quick Entry: shortcuts, Autofill + Helper option `[VERIFIED 2249437]`.
- Things Cloud `[VERIFIED 2803586]`.
- Appearance: "Icon & widget style" `[VERIFIED 2803567]`.
- Notifications `[UNSURE]`.

## 9. Menu bar extra / badge

- Dock badge: number of Today to-dos (+ red if deadlines are due?) `[UNSURE]`.
- No official menu bar extra (Things does not have one) `[FROM-MEMORY]` ; everything goes through Quick Entry, the widget and the Dock badge.
- macOS widgets: desktop and Notification Center since Sonoma ; same types as iOS `[VERIFIED 2803567]`.

## 10. Drag and drop (Mac)

| Source | Target | Result `[FROM-MEMORY]` unless stated |
|-|-|-|
| to-do | another position in the list | reorders |
| to-do | list in the sidebar (Today, Someday, project, area) | moves/schedules into that list |
| to-do | day in Upcoming | start date = that day `[VERIFIED 4001304]` |
| to-do | tag in the Tags window | applies the tag `[VERIFIED 2803581]` |
| tag | to-do | applies the tag `[VERIFIED 2803581]` |
| tag | another tag | nests `[VERIFIED 2803581]` |
| multiple to-dos | anywhere | moves them as a block |
| heading | another position in the project | moves it with its to-dos `[VERIFIED features]` |
| heading | another window | moves it to another project `[VERIFIED 2803582]` (iPad) |
| project | area in the sidebar | files it in the area |
| to-do | another Things window | moves it between lists `[VERIFIED features]` |
| multi-line text | list | one to-do per line (like `Cmd-V`) `[VERIFIED 2785159]` |

## 11. Miscellaneous interactions

- Space on a selected to-do: new to-do underneath `[VERIFIED 2785159]`.
- `Cmd-V` of multi-line text: one to-do per line `[VERIFIED 2785159]`.
- Opt-click on the checkbox: cancels instead of completing `[VERIFIED 2785159]`.
- Hover in front of a to-do: When (calendar) button `[VERIFIED features]`.
- Selection: arrow keys, Shift to extend, Opt to jump to the extremes `[VERIFIED 2785159]`.
- Touch Bar: access to frequent commands `[VERIFIED features]`.

## Recap of [UNSURE]

Sidebar width ; exact position of the toolbar buttons ; exact content of the File/Items/View menus ; exact Settings > General options ; Dock badge behaviour ; "Move completed to Logbook" menu (options) ; exact appearance of the popovers.
