# 01 - Design tokens

Reminder: Cultured Code publishes no visual values. Everything quantified here is `[FROM-MEMORY]` or `[PROPOSAL]` and must be calibrated against screenshots. The token names are proposals for the SwiftUI code (`ThingsTheme`).

Update: section 8 calibrates the Mac values and the warm dark palette against the Mac screenshots (`reference/mac-dark-0N.png`), with a MEASURED, ESTIMATED, DERIVED or UNSURE tag on each value. It overrides sections 2 to 4 for everything it covers.

## 1. Visual principles

- "A clean sheet of paper": white background, borderless content, very few separators `[VERIFIED https://culturedcode.com/things/features/]` (press quote: "a clean, crisp piece of paper").
- On opening, a to-do "turns into a blank sheet": the item grows into a white card with a drop shadow, the secondary fields (tags, checklist, When, Deadline) are tucked into a corner as long as they are unused `[VERIFIED features]`.
- Everything is animated with an in-house toolkit ("Everything you do in Things is nicely animated for pop") `[VERIFIED features]`.
- Haptic feedback everywhere ("Haptic Feedback") `[VERIFIED features]`.
- Dark mode and Dynamic Type supported, "Black" theme (pure black) for widgets `[VERIFIED https://culturedcode.com/things/support/articles/2803567/]`.

## 2. Colours

### 2.1 Accent and semantics `[FROM-MEMORY]` unless stated

| Token | Light | Dark | Usage |
|-|-|-|-|
| accent (blue) | #1E7BF4 `[UNSURE]` approx #007AFF-like | #3D8FF7 | buttons, links, Magic Plus, selection, Inbox badge, arrows |
| todayStar (yellow) | #FFCC00 approx `[UNSURE]` | #FFD60A | Today icon, star in front of a Today to-do inside Anytime/projects |
| eveningMoon | #3A59D1 blue-violet `[UNSURE]` | #5E7CF5 | This Evening icon and section title |
| deadlineFlame (red) | #FF3B30 approx `[UNSURE]` | #FF453A | flag/flame + "X days left" ; when overdue: stronger |
| inboxBlue | = accent | | tray icon |
| upcomingRed | #F2405D approx `[UNSURE]` | | Upcoming calendar icon (red-pink) |
| anytimeTeal | #35B6A7 approx `[UNSURE]` | | Anytime icon (stack of layers) |
| somedayTan | #D8B98A approx `[UNSURE]` | | Someday icon (tan box) |
| logbookGreen | #4CC260 approx `[UNSURE]` | | Logbook icon (book with a check) |
| areaGray | #8E8E93 | | Area icon (box/chest) |
| filterBarGreen | #34C759 approx | | active tag filter bar `[VERIFIED https://culturedcode.com/things/support/articles/2803581/]` ("tap the green filter bar") ; exact tint `[UNSURE]` |

### 2.2 Neutrals

| Token | Light | Dark `[FROM-MEMORY]` |
|-|-|-|
| bgPrimary (list, window) | #FFFFFF | #1C1C1E (Dark theme) or #000000 (Black theme, Appearance setting) |
| bgSidebar / iPhone Home | #F5F6F8 translucent Mac sidebar ; iPhone Home #FFFFFF | #2C2C2E |
| bgExpandedTodo (open card) | #FFFFFF + shadow | #2C2C2E |
| textPrimary | #1D1D1F `[UNSURE]` approx black | #F2F2F7 |
| textSecondary (note preview, tags, counters) | #8E8E93 | #98989D |
| textPlaceholder | #C7C7CC | #48484A |
| separator | #E5E5EA, 0.5 pt, left inset aligned with the title text | #38383A |
| checkboxBorder | #B8BCC4 `[UNSURE]` | #636366 |
| tagPillBg | #EDEDF0 | #3A3A3C |
| tagPillText | #6D6D72 | #AEAEB2 |
| selectionRow (multi-select) | accent at 12 % | accent at 22 % |
| somedayDim | textPrimary at 50 % (Someday items "visually take a back seat") `[VERIFIED https://culturedcode.com/things/support/articles/4001304/]` | same |

### 2.3 Tags

Things 3 tags have no colour of their own: uniform grey pill `[FROM-MEMORY]`. Only the filter bar turns green when a filter is active `[VERIFIED 2803581]`. Tags shipped by default: Home, Office, Errand, Important, Pending `[VERIFIED 2803581]`. Tags can be grouped (nested) `[VERIFIED 2803581]`.

### 2.4 Checkbox

| State | Rendering `[FROM-MEMORY]` |
|-|-|
| open to-do | rounded square 22x22 pt (iPhone), 16x16 pt (Mac), radius 5 pt (iPhone) / 4 pt (Mac), 1.5 pt checkboxBorder stroke, empty inside |
| completed to-do | filled accent square (or faded grey depending on context), white check ; the title turns grey and is struck through after a short delay |
| cancelled to-do | grey square with an `x` cross ; title struck through |
| Today to-do inside Anytime/project | yellow star shown in front of the checkbox (the checkbox stays) `[VERIFIED 4001304]` ("yellow star in front of them") |
| project | "progress pie" disc: accent stroke circle, filled sector proportional to completion `[VERIFIED features]` ("Progress Pies") |
| checklist item | small circle (not a square) `[VERIFIED https://culturedcode.com/things/support/articles/2803582/]` ("Tap the circle in front") 16 pt iPhone |
| repeating template | blue circular arrow in front of the title `[VERIFIED https://culturedcode.com/things/support/articles/2803564/]` ("blue circle arrow") |

## 3. Typography (SF Pro, Dynamic Type)

Things follows Dynamic Type on iOS, with a "Custom" option under Settings > Appearance ; on Mac a "Text Size" slider under Settings > General, with the sidebar fading out at large sizes `[VERIFIED https://culturedcode.com/things/support/articles/8537373/]`.

| Element | iPhone | Mac | Weight |
|-|-|-|-|
| List title (Today, Inbox, project title) | 34 pt (largeTitle) `[UNSURE]` | 26 pt `[UNSURE]` | bold |
| To-do title in a list | 17 pt (body) | 13 pt | regular |
| Open to-do title | 17 pt | 14 pt | regular (no bold) |
| Note preview / notes | 15 pt | 12-13 pt | regular, textSecondary |
| Project heading | 20 pt (title3) `[UNSURE]` | 16 pt | semibold, accent colour ; rule under the title (hairline accent) |
| Section title (This Evening, day in Upcoming) | 17-20 pt | 13-16 pt | semibold |
| Day in Upcoming (big numeral) | 28 pt `[UNSURE]` | 26 pt | bold + day name in grey 15 pt |
| Sidebar / Home row | 17 pt | 13 pt | regular ; counters 15/12 pt secondary |
| Tags pill | 13 pt (footnote) | 11 pt | regular |
| Deadline label ("5 days left") | 13 pt | 11 pt | regular, red if <= 0 |

No styling in titles: Markdown affects neither to-do titles nor project/area names `[VERIFIED https://culturedcode.com/things/support/articles/4438545/]` ("styling will not show in to-do titles or names of projects or areas"). Notes support Markdown, the markers stay visible `[VERIFIED 4438545]`.

## 4. Spacing and dimensions

Values `[FROM-MEMORY]` / `[PROPOSAL]`, to be calibrated.

| Element | iPhone | Mac |
|-|-|-|
| List horizontal margin | 16 pt (checkbox x=16) | 20 pt |
| Minimum to-do row height | 44 pt (title alone) ; ~ 52-58 pt with tags/deadline/notes | 28-30 pt (title alone) |
| Checkbox to title spacing | 12 pt | 8 pt |
| Row separator | 0.5 pt, left inset 50 pt, right 0 | 0.5 pt hairline |
| Open to-do (card) | 8 pt margin around, 16 pt inner padding, radius 10 pt `[UNSURE]`, soft shadow (y 2, blur 12, 12 % black) | radius 8 pt, shadow y 2 blur 10 |
| Capsule button radius (tags, When) | capsule (radius = h/2) | same |
| Magic Plus | 56 pt disc, accent blue, white plus, shadow ; position: bottom-right corner, 16 pt from the edges, above the home bar | n/a (+ button at the bottom left of the window, 22 pt) |
| Mac sidebar | 220 pt wide, resizable 180-400 pt `[UNSURE]` | |
| iPhone Home row | 44-48 pt, icon 24 pt at x=16, title x=56 | |
| List icon | 24 pt iPhone, 18 pt Mac | |

## 5. Icons per list (to be redrawn)

| Element | Glyph | Colour |
|-|-|-|
| Inbox | open tray | accent blue |
| Today | filled star (5 rounded points) | todayStar |
| This Evening | crescent moon | eveningMoon |
| Upcoming | calendar (page with a header band) | upcomingRed |
| Anytime | stack of layers (3 stacked diamonds) | anytimeTeal |
| Someday | cardboard box/crate | somedayTan |
| Logbook | open book with a check | logbookGreen |
| Trash | waste bin (Mac sidebar, only shown when not empty) | grey |
| Area | grey box/chest `[UNSURE]` | areaGray |
| Project | progress pie disc | accent |
| Deadline | flag `[VERIFIED https://culturedcode.com/things/support/articles/2803579/]` ("deadline button ... the flag button") | deadlineFlame |
| When | calendar / star depending on state | grey ; yellow if Today |
| Tags | label | grey |
| Checklist | bulleted list | grey |
| Repeat | circular arrows | grey ; blue for a template |
| Reminder | bell / clock | grey |
| Magic Plus | white `+` on a blue disc | |

In the original app these icons are custom drawn (proprietary SVGs): redraw them.

## 6. Haptics `[FROM-MEMORY]` (presence `[VERIFIED features]`)

| Event | Proposed iOS feedback |
|-|-|
| completing a to-do (checkbox tap) | UIImpactFeedbackGenerator .light (or .soft) |
| lifting an item to drag | .medium impact |
| dropping an item | .light |
| Magic Plus: lifting | .medium ; hovering the Inbox target or the left edge (heading) | selection feedback |
| entering multi-select (left swipe) | selection changed |
| sweeping the selection along the right edge | selection changed on every row |
| pull-down reaching the Quick Find threshold | .light |
| shake undo | .warning notification |

## 7. Animations `[FROM-MEMORY]` + SwiftUI `[PROPOSAL]`

Cultured Code does not publish the curves. Recommended equivalents:

| Interaction | Observed behaviour | Proposed SwiftUI |
|-|-|-|
| completing a to-do | the check fills in (~ 0.15 s), title goes grey and struck through, after ~ 1 s (lets you undo) the row shrinks and disappears ; or stays until "Move completed to Logbook" depending on the setting | `withAnimation(.spring(response:0.3,dampingFraction:0.8))` check ; removal after `DispatchQueue` 1.0 s with `.easeInOut(0.25)` on the height |
| opening a to-do (expand-to-edit) | the row grows into a white card, neighbouring rows slide, shadow appears | `matchedGeometryEffect` + `.spring(response:0.35,dampingFraction:0.85)` ; shadow fade 0.2 s |
| closing | reverse, same timings | same |
| reorder (drag) | lifted item, slightly enlarged (scale 1.03), shadow, the others part | `.spring(response:0.28,dampingFraction:0.8)` |
| Magic Plus drag | the button follows the finger, an empty row opens under the finger at the insertion point ; on release: the row becomes a new to-do in edit mode | same |
| opening the When picker | popover/sheet from the bottom ; calendar with monthly scrolling | standard sheet |
| This Evening toggle | the item slides to the bottom section | `.easeInOut(0.3)` |
| pull-down search | the search bar is revealed, the content moves down ; past the threshold, switches to search | threshold ~ 60 pt `[UNSURE]` |

## Recap of [UNSURE]

All the hex values in 2.1 and 2.2 ; list title, heading and Upcoming day sizes ; open card radii ; Mac sidebar width ; pull-down threshold ; exact Area icon ; exact filter bar tint.

## 8. Calibration against Mac screenshots ("dark warm" palette)

Source: `reference/mac-dark-01.png` to `05.png`, 3500 x 2218 px, 2x retina capture (1 pt = 2 px). Window 1750 pt, sidebar 302 pt wide, list column 1020 pt (centred in the 1448 pt detail pane). Value grading: `MEASURED` = read on the screenshot to about 1 pt or from a pixel sample ; `ESTIMATED` = read by eye on the screenshot, to 1 pt or a few levels ; `DERIVED` = light variant deduced from the dark one, no light screenshot ; `UNSURE` = still a guess (iOS, light palette). The code lives in `DesignSystem/Tokens`, one comment per value carries the same tag. The warm dark palette replaces the iOS cool grey as the default dark palette (iOS included).

### 8.1 Colours (dark)

| Token | Hex | Grade | Usage |
|-|-|-|-|
| bgPrimary | #302C2A | MEASURED | window and list background |
| bgSidebar | #312D2C | MEASURED | sidebar background |
| bgSidebarSelection | #3B3E42 | MEASURED | selected sidebar row |
| selectionRow | #393C3F | MEASURED | selected list row |
| bgCalendarBox | #3F3B39 | MEASURED | calendar events box, date pill |
| separator | #4F4B4A | MEASURED | 1 px rule under a section header |
| bgExpandedTodo | #3B3735 | ESTIMATED | open to-do card |
| textPrimary | #F4F2F0 | ESTIMATED | titles |
| textSecondary | #8F8B89 | ESTIMATED | project row, notes icon |
| textPlaceholder | #77726F | ESTIMATED | "Notes", card bar icons |
| textMutedLink | #7A7674 | ESTIMATED | "Hide later items", "Show N logged items" |
| checkboxBorder | #7C7875 | ESTIMATED | checkbox stroke |
| tagPillBorder / tagPillText | #6A6664 / #9A9694 | ESTIMATED | tag pill (stroke only) |
| chipFill / chipText | #8F8B89 / #2B2725 | ESTIMATED | selected "All" pill |
| todayStar | #FFD60A | ESTIMATED | star |
| eveningMoon | #A9B7F3 | ESTIMATED | This Evening moon |
| upcomingRed | #F0476B | ESTIMATED | calendar icon |
| anytimeTeal | #3BAFA8 | ESTIMATED | Anytime icon |
| somedayTan | #DCC48C | ESTIMATED | Someday icon |
| logbookGreen | #57C26A | ESTIMATED | Logbook icon |
| areaTint | #7CCFAE | ESTIMATED | Area cube in the header |
| accent, deadlineFlame, filterBarGreen | unchanged | UNSURE | not visible in the screenshots |

Light variants: `DERIVED` for bgCalendarBox (#F1F1F3) and bgSidebarSelection (#DADDE3), `UNSURE` for the rest (no light screenshot).

### 8.2 Mac dimensions (pt)

| Element | Value | Grade |
|-|-|-|
| Row height, title alone | 28 | MEASURED (row pitch) |
| Row height, title + project row | 38 | MEASURED |
| Checkbox | 12, radius 3, 1 pt stroke, vertically centred in the row | MEASURED size, ESTIMATED radius and stroke |
| Someday box | 2 / 2 dashed stroke | MEASURED (dashes), ESTIMATED pattern |
| Left gutter | highlight at x = 0, box at x = 10 | MEASURED |
| Box to title | 9 (title at x = 31 from the row edge) | MEASURED |
| Highlight radius | 6 continuous | ESTIMATED |
| Separators between rows | none | MEASURED |
| To-do title | 14 regular | ESTIMATED |
| Project row | 12 regular, emoji included in the text | ESTIMATED |
| Notes icon after the title | 10, gap 5 | MEASURED position, ESTIMATED size |
| Inline tag pill | 0.75 stroke, 16 high capsule, text 11 medium, 8 after the title | MEASURED height, ESTIMATED the rest |
| Date pill ("Thu") | 16 high, radius 4, bgCalendarBox fill, text 11 | MEASURED height |
| List title | 22 bold, icon 22, gap 8, centre at y = 84 (toolbar 52) | MEASURED centre, ESTIMATED body |
| First to-do title | 27 (no box or filter) | MEASURED |
| Today events box | 1000 x 66 for 3 rows, radius 10, margin 12 / 9, pitch 16, bar 3 x 11, text 12 | MEASURED except radius and text (ESTIMATED) |
| Title to box / box to filter / filter to first row | 13 / 16 / 46 | MEASURED |
| Filter pill | 20 high, text 12 semibold, "All" = filled capsule | MEASURED height, ESTIMATED text |
| Section header | icon 14, title 14 bold at x = 31, 0.5 rule at 6 under the text, 7 margin on each side | MEASURED positions, ESTIMATED body |
| Space before a header / rule to the first row | 40 / 9 | MEASURED (34 to 46 depending on the previous row) |
| Open card | offset 4 outside the row, radius 12, inner margin 14, top 18, bottom 19, notes area 60 minimum | MEASURED except radius (ESTIMATED) |
| Card bar | when on the left at x = 35, 3 icons of 13 pt, pitch 32, right margin 28 | MEASURED |
| Breadcrumb under the card | 12 semibold, aligned 17 from the card's right edge, 17 under the card | MEASURED |
| Card shadow | radius 12, y 3, black at 30 % (dark) | ESTIMATED (almost invisible in the screenshots) |
| "Hide later items" | 12, 38 under the last row, at x = 10 ; "Show N logged items" 23 lower | MEASURED |
| Sidebar width | 302 | MEASURED (the screenshot width, the code keeps 240 ideal for a normal window) |

Values from the original spec made obsolete by this table: 4 (Mac card: radius 8, shadow y 2 blur 10), 3 (Mac list title 26, to-do title 13), 4 (Mac checkbox 16, row height 28 to 30, margin 20).

### 8.3 Reordering animations

Not in the screenshots (static), therefore `[PROPOSAL]`: row lift `scale 1.03` + shadow (spring 0.2 / 0.75), other rows parting (`ThingsMotion.reorder`, spring 0.28 / 0.8), keyboard swap Cmd Opt arrow (`ThingsMotion.reorderSwap`, spring 0.26 / 0.82), return to place on a network failure.
