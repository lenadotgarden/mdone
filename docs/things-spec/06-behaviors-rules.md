# 06 - Semantic rules of Things

Legend: `[VERIFIED url]` / `[FROM-MEMORY]` / `[UNSURE]`. Main sources: 4001304 (Today/Upcoming/Anytime/Someday), 2803579 (Scheduling), 2803564 + 3743733 (Repeating), 2803581 (Tags), 2803585 (Reminders), all under https://culturedcode.com/things/support/articles/.

## 1. The model: date-based lists vs context

Two perspectives on to-dos `[VERIFIED 4001304]`:

- Context: Areas and Projects created by the user.
- Time: the default lists Inbox, Today (+ This Evening), Upcoming, Anytime, Someday, Logbook. They cannot be renamed, deleted or reordered `[VERIFIED 2803579]`.

Each to-do belongs to exactly one of the status lists: Inbox, Today (incl. This Evening), Upcoming, Anytime, Someday, or (once finished) Logbook `[VERIFIED 2803579]` ("Every to-do belongs to one of the following lists"). Anytime, Upcoming and Someday are mutually exclusive `[VERIFIED 4001304]`. A to-do can also have a parent (project or area) or none (loose).

## 2. Decision table: which list an open to-do appears in

Inputs: parent, When (start date / Someday / This Evening), Deadline, repetition.

| Condition | Status list |
|-|-|
| created with no parent and no date (quick capture) | Inbox `[VERIFIED 4001304]` |
| moved into a list (project/area) or given a date | leaves the Inbox `[VERIFIED 4001304]` |
| When = Today (start date = today) | Today |
| When = This Evening | Today, This Evening section `[VERIFIED 4001304]` |
| start date in the future | Upcoming, dormant; becomes Today on the date `[VERIFIED 4001304]` |
| When = Someday | Someday |
| no start date, not Someday, filed (or Clear from the Inbox then Move > No Project) | Anytime `[VERIFIED 2803579]` |
| deadline = today (or overdue) | also appears in Today `[VERIFIED 4001304]` ("if the start date, deadline, or repeating rule ... matches today's date") |
| deadline in the future, no start date | stays in Anytime; also visible in Upcoming on the day of the deadline `[VERIFIED 4001304]` |
| repetition rule falls on today | Today `[VERIFIED 4001304]` |
| completed or cancelled | Logbook `[VERIFIED 4001304]` |

The same row can appear in several places: a to-do from Today is also in Anytime, with a yellow star `[VERIFIED 4001304]`. A project stays visible in its area/sidebar as long as it is not inactive.

## 3. When vs Deadline

| | When (start date) | Deadline |
|-|-|-|
| Question | "When do I start?" | "When must I be done?" |
| Button | calendar | flag `[VERIFIED 2803579]` |
| Effect | hides in Upcoming until the date, then Today | keeps the item active in Anytime; appears in Today on the day itself; countdown "N days left" `[VERIFIED 2803579]` |
| Reminder | yes (time attached to the When) | no `[VERIFIED 2803585]` |
| NL | yes | yes (Mac) `[VERIFIED 9780167]` |
| Duration | no: "merely indicates the day on which you want to begin work" | n/a |
| Calendar | is not a calendar app `[VERIFIED 2803579]` | |

A deadline with several days of work: add a start date before the deadline `[VERIFIED 2803579]`.

Past deadline: the item is late, red text "N days ago" `[FROM-MEMORY]` `[UNSURE]` (wording).

## 4. Today and This Evening

- Today is a global filter, not a container `[VERIFIED 4001304]`.
- Manual order (drag) `[VERIFIED 4001304]`; what sits at the top of Today is what you take first.
- Option to group by project/area in Settings > General (synchronized) `[VERIFIED 4001304]`.
- This Evening: separate section at the bottom of Today `[VERIFIED 4001304]`. A This Evening to-do set for today appears in the section; set for a future day, it appears that day in the evening section `[FROM-MEMORY]` `[UNSURE]`.
- Calendar events: at the top of Today, if enabled, chosen Apple calendars, read-only, no sync `[VERIFIED 2803583]`.
- At the midnight switch: items whose start date = the new day move to Today; unfinished items from the day before stay in Today (as a visual "late") `[FROM-MEMORY]` `[UNSURE]`. A reminder fires a notification at the time `[VERIFIED 2803585]`.
- Reminder is not persistent, does not ring in a loop `[VERIFIED 2803585]`.
- Snooze: 15 min, 1 h, 3 h, until the next day `[VERIFIED 2803585]`.

## 5. Upcoming

- Seven days ahead starting tomorrow, one block per day `[VERIFIED 4001304]`.
- Contains dated to-dos, repetitions, deadlines, events `[VERIFIED features]`.
- The furthest away grouped by week then by month `[FROM-MEMORY]` `[UNSURE]`.
- Reschedule by drag and drop `[VERIFIED 4001304]`.
- A project with a future start date is hidden from the sidebar/Home and comes back on the date `[VERIFIED 4001304]`. Inside a project, inactive to-dos are below the active ones `[VERIFIED 4001304]`.
- A to-do with a deadline but no start date is NOT dormant (it stays active in Anytime) `[VERIFIED 4001304]`.

## 6. Anytime

- Active to-dos only. No blocking `[VERIFIED 4001304]`.
- Order: loose to-dos first, then grouped by direct parent; a parent with no active to-do is omitted `[VERIFIED 4001304]`.
- Today items carry the yellow star `[VERIFIED 4001304]`.

## 7. Someday

- Uncommitted ideas, faded visual effect `[VERIFIED 4001304]`.
- Someday items (and projects) absent from Anytime and Upcoming; Someday projects hidden from the sidebar `[VERIFIED 4001304]`.
- Review recommended every few months `[VERIFIED 4001304]`.

## 8. Inbox

- Staging area, everything that is captured (Quick Entry, Mail to Things, share extension, Magic Plus target) `[VERIFIED 4001304]`.
- Title not required (can be empty or "New To-Do") `[VERIFIED 4001304]` ("It's ok if you don't know the exact title").
- When an item leaves: temporary section "x to-dos were moved out of the Inbox", which disappears on navigation `[VERIFIED 4001304]`. You can click in it to keep editing the item `[VERIFIED 4001304]` (partial sentence in the source) `[UNSURE]`.

## 9. Logbook and archiving

- Completed and cancelled go to the Logbook `[VERIFIED 4001304]`.
- Kept indefinitely `[VERIFIED 4001304]`.
- Mac: "Move completed to Logbook" (`Shift-Cmd-Y`) forces the immediate transfer `[VERIFIED 2785159]`. The automatic frequency setting exists (immediate/daily/manual) `[FROM-MEMORY]` `[UNSURE]`.
- Emptying it: select all (`Cmd-A`) and delete. iOS: permanent. Mac: Trash, to be emptied `[VERIFIED 4001304]`.
- Search: the Logbook is not in the first level of Quick Find; "Continue Search" includes it `[VERIFIED 2803584]`.
- A heading can be archived with its to-dos `[VERIFIED features]`.
- Completed project: goes to the Logbook; "Logged Projects" via Quick Find `[VERIFIED 2803584]`.

## 10. Projects

- Elements: title, notes, tags, deadline/when, headings, to-dos, progress (pie) `[VERIFIED features]`.
- Pie: fraction of to-dos completed over the total `[FROM-MEMORY]` `[UNSURE]` (how headings/cancelled items are counted).
- Completion: a project is completed manually; if to-dos are open, Things offers "Complete all to-dos?" / "Mark all as completed" `[FROM-MEMORY]` `[UNSURE]` (text). When the last to-do is ticked, the pie is full and the project stays open until an explicit action (an offer to finish it) `[FROM-MEMORY]`.
- Project with a future start date: hibernation `[VERIFIED 4001304]`.
- Repeating project: a copy of a template; its to-dos cannot have their own repetition `[VERIFIED 2803564]`.
- Listed projects: "All Projects" (Quick Find) shows all the open ones `[VERIFIED 2803584]`.

## 11. Headings and checklists

- Heading: visual container inside a project, draggable with its content, archivable `[VERIFIED features]`. Headings are not to-dos: no checkbox. A heading has a name, possibly notes `[UNSURE]`.
- Checklist: small list of sub-steps inside a to-do, not listed outside, no dates/tags `[VERIFIED features]` ("break down the finer details of a to-do"). You cannot tick the checklists of a repeating template, only those of the copy `[VERIFIED 2803564]`.
- A to-do whose checklist items are all ticked is not completed automatically `[FROM-MEMORY]` `[UNSURE]`.

## 12. Tags

- Default tags: Home, Office, Errand, Important, Pending `[VERIFIED 2803581]`.
- Applied to to-dos, projects, areas. A tag set on a list is inherited by its children, not shown on them but taken into account for filtering/searching `[VERIFIED 2803581]`.
- Filter: tag bar at the top of the list; several tags = AND (intersection) `[VERIFIED 2803581]`.
- Hierarchy: a parent tag groups children `[VERIFIED 2803581]`; filtering by the parent includes the children `[FROM-MEMORY]` `[UNSURE]`.
- Tag order = order in the filter bar `[VERIFIED 2803581]`.
- Keyboard shortcut per tag `[VERIFIED 2803581]`.
- No colour per tag `[FROM-MEMORY]`.

## 13. Repetition

Two patterns `[VERIFIED 3743733]`:

1. After completion: the next to-do is created only after the previous one is ticked; the repetition interval is kept from the completion date. Verbatim example: water the plants every week; if done on Saturday instead of Wednesday, the next one falls on the following Saturday. The first copy appears in Today immediately; reschedule it if needed `[VERIFIED 3743733]`.
2. Regular (daily, weekly, monthly, yearly): a new one is created according to the calendar, whether the previous one is finished or not. Watch out for copies piling up in daily `[VERIFIED 3743733]`. Mutually exclusive options: specific days (e.g. Mon-Fri, 3rd Tuesday) and end date `[VERIFIED 3743733]` `[VERIFIED 2803564]`.

Model: "Behind every repeating to-do or project is a template"; each occurrence is a copy created in Today from that template `[VERIFIED 2803564]`.
- Template identified by a blue circular arrow; editing the template changes the future copies; editing a copy keeps nothing `[VERIFIED 2803564]`.
- Actions on the rule: Edit Rule, Create Next Copy, Show Previous Copy, Pause, Resume, Stop `[VERIFIED 2803564]`.
- Repeating deadlines: "Add deadlines" checkbox + "days earlier"; the deadline falls on the repetition day, the item appears N days earlier `[VERIFIED 2803564]`.
- Reminder possible on the template `[VERIFIED 2803564]`.
- Repeating list: grouped templates (loose at the top, then by parent), sorted by next occurrence, paused or waiting at the bottom `[VERIFIED 2803564]`.
- Early completion of a template or of a copy in Upcoming: possible `[VERIFIED 2803564]`.
- A to-do copy, or a to-do inside a repeating project, cannot have its own repetition `[VERIFIED 2803564]`.

## 14. Natural language (When and Deadline)

Languages: EN, DE, FR, IT, ES, RU, ZH, JA `[VERIFIED 9780167]`. Examples `[VERIFIED 9780167]`:

| Input | Result |
|-|-|
| tod... | Today |
| tomorrow, Monday, next week | relative |
| 10-3 | 3 October (format depends on region) |
| 10-3 9 | 9am on 3 October (reminder) |
| 2p | reminder at 2pm |
| 17d | in 17 days (w weeks, mo months, y years) |
| 17d from jul9 / jul9 + 17d | 17 days after 9 July |
| wed jul... | list of Wednesdays in July |
| 3rd wed jul | 3rd Wednesday of July |
| 3rd wed jul 2026 | same in 2026 |
| last fri jul | last Friday of July |

Words do not need to be complete. Reminders only on the start date, not on the deadline `[VERIFIED 9780167]`.

## 15. Empty-state texts and labels

The sources give none. Everything below is `[UNSURE]`: to test on a real Things or replace with our own text `[PROPOSAL]`.

| List | Candidate text / visual `[UNSURE]` |
|-|-|
| Inbox | large empty tray icon, no text or "Inbox is empty" |
| Today | large star + "Today is empty" / "Enjoy your day" |
| Upcoming | empty listed days, no text |
| Anytime | nothing |
| Someday | nothing |
| Logbook | nothing |
| Empty project | blank line, no text |

Safe UI labels `[VERIFIED]`: "x to-dos were moved out of the Inbox", "This is a copy of a repeating to-do", "Continue Search", "Add Reminder", "Clear", "Add Tags", "Manage Tags", "Set Tags", "Filter by Tag", "Add deadlines", "days earlier", "Edit Rule...", "Create Next Copy", "Show Previous Copy", "Pause", "Resume", "Stop", "After Completion", "Regularly", "Show Calendar Events", "New Tag", "Quick Entry", "Autofill", "Plus Button".

## 16. Misc

- Scheduling shortcuts: see 05. Right swipe: When `[VERIFIED 2803582]`.
- Creation: a to-do created from a list inherits the context (Today -> start date today; project -> in that project; heading -> under that heading; Upcoming -> that day) `[FROM-MEMORY]`.
- Duplication (`Cmd-D`) creates a copy next to it `[VERIFIED 2785159]`.
- Trash: Mac deletion goes to Trash; iOS permanent `[VERIFIED 4001304]`.
- Cancel: status distinct from completed, cross, struck through `[VERIFIED 2785159]` (Cancel selected item).

## Summary [UNSURE]

Empty-state texts; project completion rule and confirmation label; pie counting; midnight switch of unfinished items; This Evening on a future day; exact grouping order of Upcoming beyond 7 days; Logbook frequency setting; filtering by parent tag; auto-completion of a to-do whose checklist is ticked; wording of "late".
