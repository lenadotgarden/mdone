# 07 - Mapping Things to Vikunja v2

This whole file is `[PROPOSAL]` (design of our fork) backed by the facts of the Vikunja model. Vikunja facts: `[VERIFIED docs/vikunja-api-inventory.md]` (mDone repo, API v2, server >= 2.5.0) or `[FROM-MEMORY]` (known Vikunja data model: fields `start_date`, `end_date`, `due_date`, `reminders`, `repeat_after`, `repeat_mode`, `priority`, `position`, `related_tasks`, `labels`, `parent_project_id`, `done_at`). Validate every field against `/api/v2/openapi.json` before freezing `[UNSURE]`.

Things reminder: see 06 for the semantics to reproduce.

## 1. Mapping table

| Things concept | Vikunja | Gap / convention |
|-|-|-|
| To-do | Task | direct |
| Title / Notes | `title` / `description` (Markdown, or HTML depending on the client) | Vikunja web writes HTML into `description`; our app will write Markdown: see §4 |
| Inbox | "Inbox" project (the user's default project, the profile's `default_project_id`) `[FROM-MEMORY]` | convention: Inbox = that project; a to-do leaves the Inbox when it is moved to another project or given a When |
| Area | top-level project marked as an Area | no "Area" type in Vikunja: see §2 |
| Project | child project of an Area, or root project (= project with no area) | direct via `parent_project_id` |
| Sub-project of a project | does not exist in Things | ignored (max depth 2: Area > Project); deeper Vikunja projects are displayed flat `[PROPOSAL]` |
| Heading | bucket of a dedicated Kanban view | see §3 |
| Checklist item | sub-task (`subtask` relation) | see §5 |
| When = date | `start_date` (local date of the start day) | see §6 |
| When = Today | `start_date` = today or earlier (but see §6) | Today is computed, not stored |
| When = This Evening | `start_date` + reserved label `things:evening` | see §7 |
| When = Someday | reserved label `things:someday` | see §8 |
| When = Anytime | null `start_date`, no Someday label, inside a project or Area | computed |
| Reminder | absolute `reminders[]` (`reminder` datetime) | a single reminder per to-do in the UI, like Things |
| Deadline | `due_date` | direct |
| Repeat | `repeat_after` (seconds) + `repeat_mode` | significant gaps: see §9 |
| Tag | Label | no colour on the Things side; ignore `hex_color` when displaying `[PROPOSAL]` |
| Nested tag | no label hierarchy | naming convention "Parent/Child" `[PROPOSAL]` `[UNSURE]` |
| Cancelled | `done = true` + label `things:cancelled` | see §10 |
| Logbook | `done = true` sorted by `done_at` desc | direct |
| Trash | no (2.8.0 has a server trash: `/tasks/deleted`, `/tasks/{id}/restore`) `[VERIFIED docs/vikunja-api-inventory.md]` | use the server trash if version >= 2.8 |
| Priority | `priority` 0-5 | does not exist in Things: do not display it; preserve it on write (PATCH only sends the changed fields) `[VERIFIED docs/vikunja-api-inventory.md]` |
| Order within a list | `position` per view (`PUT /tasks/{id}/position`, body `{position, project_view_id}`) `[VERIFIED docs/vikunja-api-inventory.md]` | see §11 |
| Project progress pie | computed client-side (done / total) | no server field |
| Project notes | project `description` | direct |
| Project deadline | no project `due_date` | gap: see §12 |
| Project start date / Someday | no field | gap: see §12 |
| Area notes / tags | project `description`; tags: no labels on projects | gap: see §12 |
| Archive (project Logbook) | `is_archived = true` or project marked done via a label? | see §12 |
| Calendar events | local EventKit, not Vikunja | like Things: local read, no write `[VERIFIED 2803583]` |

## 2. Areas

Options evaluated:

1. Root project whose title is the Area name, with a marker: description starting with a `things:area` line (plain line), or a reserved `hex_color`, or the presence of a "things:area" label (labels do not apply to projects: rule it out).
2. Root project "Areas" holding the Areas as children. Rejected: adds a parasitic level.
3. Structural convention: any project that has children = Area. A project with no child and no parent = free project. Ambiguous for an empty Area.

Recommendation: option 1 with a marker in `description` (first line `things:area`), because it is the only free field, it survives the API and it is not visible in the Vikunja web when placed in an HTML comment. An Area has no to-dos of its own on the Vikunja side, but Things allows loose to-dos in an Area: they live as direct tasks of that Area project `[PROPOSAL]`. Risk: if the Area is also a normal Vikunja project, the web app lets you add tasks to it (which is consistent).

Tradeoff: without a marker, an ordinary root project created in the web app shows up as a "free project" in our app (acceptable).

## 3. Headings

Two candidates:

| Option | + | - |
|-|-|-|
| A. Buckets of a Kanban view `things-headings` | native structure, position per bucket, API present (`/projects/{id}/views/{view}/buckets/tasks`, move card `PUT .../buckets/{bucket}/tasks`) `[VERIFIED docs/vikunja-api-inventory.md]`, visible in the web app | one task = one bucket; must create and maintain a dedicated view; paging of the buckets `[VERIFIED docs/vikunja-api-inventory.md]`; order of "to-dos outside a heading" = default bucket |
| B. fake task with label `things:heading` | simple, unified order in the list view | pollutes counters, appears in the web app as a task, risk of completing it by mistake |
| C. prefix in the task `description` | no server structure | fragile |

Recommendation: A. A Things project with headings gets a Kanban view named `things-headings`, created as needed; the first bucket (default) = "to-dos without a heading" (no title displayed); every other bucket = a heading. Archiving a heading = marking the bucket (name prefixed `[archived]`) or completing its tasks `[UNSURE]`. If the project has no headings, no extra view to create.

Order: the `position` of the tasks in the `things-headings` view gives the intra-heading order; the order of the buckets gives the order of the headings `[UNSURE]` (bucket `position` field to verify).

## 4. Notes

Vikunja stores `description` as HTML (Tiptap editor) in the web; Things' Markdown is not native there. Choice: our app stores raw Markdown; the web app will display it as text. If the user also edits on the web, the description becomes HTML: the app must detect it (presence of tags) and display it tolerantly or convert HTML to Markdown `[PROPOSAL]` `[UNSURE]` (exact rendering of the web editor).

## 5. Checklists

| Option | + | - |
|-|-|-|
| A. sub-tasks (`related_tasks.subtask`, `POST /tasks/{id}/relations`) `[VERIFIED docs/vikunja-api-inventory.md]` | typed structure, tickable, order by `position` | each item is a real task: it appears in every list unless excluded; must filter out the tasks that have a `parenttask` relation; one call per item |
| B. Markdown boxes `- [ ]` in `description` | a single PATCH, atomic, no filtering | does not sync cleanly with Vikunja sub-tasks; parsing to maintain; confusion with Markdown notes |

Recommendation: A, with an `expand=subtasks` filter to bring back only top-level tasks `[VERIFIED docs/vikunja-api-inventory.md]`, and hiding of any task that has a parent. Sub-tasks inherit the parent's project. Things forbids dates/tags on checklist items: do not expose them `[VERIFIED features]` (the items are plain steps).

If latency or volume is a problem: fall back to B `[PROPOSAL]`.

## 6. When = start_date, and "Today"

Vikunja distinguishes `start_date`, `end_date`, `due_date`, all datetimes. Mapping:

- `start_date` = start day. Representation: datetime at 12:00 local of the chosen day, so that a timezone offset of less than 12 h does not change the day `[PROPOSAL]` `[UNSURE]` (alternative: 00:00 UTC + floating date convention). The day is read back in local time.
- `end_date`: unused by the Things UI, preserve it as is.
- `due_date` = Deadline, same noon representation.
- Today = unfinished tasks with `start_date <= end of day` OR `due_date <= end of day` (the deadline reached), excluding Someday. Vikunja filter: `done = false && (start_date <= now || due_date <= now)` (DSL syntax to validate `[UNSURE]`); safest: download and filter client-side `[PROPOSAL]`.
- Upcoming = `start_date > end of day` or `due_date > end of day` with no start date; groups computed client-side.
- Anytime = null `start_date`, neither Someday nor Inbox.
- A to-do in Today whose `start_date` has been past for several days stays in Today (this is Things behaviour too `[FROM-MEMORY]`).
- Reminder: `reminders = [{reminder: <absolute datetime>}]` on the task; when a reminder is set, the `start_date` of the reminder day is set too `[PROPOSAL]`. At most one reminder in the UI. Vikunja's `relative_to` (relative to due/start/end) are not used.
- "Start at 9:00" reminders put the day in `start_date` and the time in the reminder, not in `start_date`.

## 7. This Evening

No equivalent. Options:

| Option | + | - |
|-|-|-|
| A. reserved label `things:evening` | simple, readable by other clients; survives date changes | visible in the web app labels; must be hidden in our UI; cleanup as the day passes |
| B. sentinel time (e.g. `start_date` at 18:00 local) | no label | conflicts with real times; 12:00 is already used as "the day"; fragile |
| C. local field only | no pollution | lost on sync; not consistent across devices |

Recommendation: A. Rule: `things:evening` only makes sense if `start_date` is set (day). Clearing the When removes the label. Today shows in a This Evening section the Today tasks carrying that label. At midnight, the label stays valid for a future day (cf. 06 §4) `[UNSURE]`.

## 8. Someday

- Reserved label `things:someday` (A); a Someday task has no `start_date` (otherwise contradiction: the label wins and `start_date` is ignored).
- Variant B: dedicated "Someday" project: loses its place in the original Area/project. Rejected.
- Someday project: see §12.

## 9. Repetition

Vikunja fields: `repeat_after` (seconds) and `repeat_mode`: 0 = fixed interval from `due_date`, 1 = monthly (same day of the month), 2 = from the completion date (`from current date`) `[FROM-MEMORY]` `[UNSURE]` (to validate). Vikunja does not create a copy: on completion, the same task is set back to `done = false` with advanced dates (the `done: true` PATCH "rolls the due date forward" `[VERIFIED docs/vikunja-api-inventory.md]`).

| Things feature | Feasible? |
|-|-|
| After completion | yes: `repeat_mode = 2` |
| Regular daily/weekly | yes: `repeat_mode = 0`, `repeat_after = 86400*n` or `604800*n` |
| Regular monthly | yes: `repeat_mode = 1` (1 month); no "every 2 months" `[UNSURE]` |
| Yearly | `repeat_after = 31536000` approximate; drifts over leap years |
| Specific days (Mon-Fri, 3rd Tuesday) | no: gap |
| End date | no: gap (can be handled app-side by stopping the repetition) |
| Template + copies | no: a single task; the notion of "copy" disappears; the Repeating list = tasks with `repeat_after > 0` |
| Pause / Resume | no: simulate by setting `repeat_after = 0` and saving the old value in a label/description `[UNSURE]` |
| "days earlier" deadlines | partially: the `start_date` vs `due_date` gap is kept as dates advance `[UNSURE]` |

Recommendation: expose After completion + simple Daily/Weekly/Monthly/Yearly first; hide the rest; document the gaps in the UI. Any richer rule = app-side convention in `description` (block `things:repeat {...}`) `[PROPOSAL]`, not recommended for v1.

## 10. Cancelled

Vikunja has no cancelled status. Convention: `done = true` + label `things:cancelled`. Logbook display: a cross instead of a tick. Remove the label when "uncancelling".

## 11. Order (position)

- Vikunja holds a `position` per (task, view). Each project has views (list, Kanban...) `[VERIFIED docs/vikunja-api-inventory.md]` (`/projects/{id}/views`).
- Things lists that are "intrinsic" to the project (the project itself, an Area): use the project's List view for `position`.
- Cross-cutting lists (Today, Upcoming, Anytime, Someday, Inbox): Things stores a global order per list. Vikunja has no view for that. Options: (1) use the `position` of the List view of the original project (the order of Today then follows the order in each respective project: acceptable for an MVP), (2) create Vikunja "saved filters" (pseudo-projects, negative ids) `[VERIFIED docs/vikunja-api-inventory.md]` for Today/Anytime and use their views for the position `[UNSURE]` (positions of saved filters), (3) local order only (not synchronized). Recommendation: (1) for v1; Inbox = Inbox project so native position.

## 12. Unresolved gaps for projects and areas

| Things need | Workaround |
|-|-|
| Tags on project/area | label not applicable to a project: store the tag list in `description` on the first line `things:tags a,b` `[PROPOSAL]` `[UNSURE]`; inherited at runtime by the app |
| Project deadline / start date | same: `things:deadline YYYY-MM-DD`, `things:start YYYY-MM-DD` at the top of the description; or ignore |
| Someday project | `things:someday` in the project description |
| Completed project (Logbook) | `is_archived = true` (the server takes it out of the lists) + date in `things:completed`; or complete all its tasks. `GET /projects` with `is_archived=true` returns both active and archived `[VERIFIED docs/vikunja-api-inventory.md]` |
| Cancelled project | archived + `things:cancelled` |
| Repeating project | gap: not supported in v1 |
| Pie | computed: done / total of its tasks (excluding sub-tasks) |

This dependency on the project `description` field must be encapsulated in a single module (`ProjectMetaCodec`) that reads and writes a block of lines at the top and preserves the rest of the text.

## 13. Tags (labels)

- Things tag = Vikunja label. API: `GET/POST /labels`, `POST/DELETE /tasks/{id}/labels` `[VERIFIED docs/vikunja-api-inventory.md]`.
- App-side reserved tags: `things:` prefix (evening, someday, cancelled): to hide from every tag screen, from the filter and from search.
- Per-letter tag shortcuts (Mac): local storage.
- Tag order: local (Vikunja has no label order).
- Tags inherited by the list: computed app-side, no write on the tasks `[VERIFIED 2803581]` (do not materialize them).

## 14. Quick Entry / Inbox / Share

- Creation: `POST /projects/{inboxId}/tasks` `[VERIFIED docs/vikunja-api-inventory.md]`.
- Direct creation in a project: `POST /projects/{id}/tasks`.
- Magic Plus in a time-based list: creates in the Inbox project (or the contextual parent) then `PATCH` with `start_date` if Today/Upcoming.
- Move: `PATCH` of `project_id`.

## 15. Atomic updates

Always `PATCH /tasks/{id}` with only the changed fields (mDone already does this: #292) `[VERIFIED docs/vikunja-api-inventory.md]`. Clearing a date = `null`. Arrays (`labels`, `reminders`) replace the whole list: when a single reserved label changes, read the labels back so as not to overwrite `[VERIFIED docs/vikunja-api-inventory.md]` (labels go through `/tasks/{id}/labels` rather than PATCH).

## 16. Summary of the reserved conventions

| Marker | Location | Meaning |
|-|-|-|
| `things:evening` | task label | This Evening |
| `things:someday` | task label | Someday |
| `things:cancelled` | task label | cancelled (with done) |
| `things:area` | first line of the project `description` | this element is an Area |
| `things:tags`, `things:deadline`, `things:start`, `things:someday`, `things:completed`, `things:cancelled` | lines at the top of the project `description` | project metadata |
| `things-headings` view | Kanban view of the project | headings = buckets |
| Inbox project | profile `default_project_id`, otherwise a project named Inbox | Inbox |
| `start_date` / `due_date` at 12:00 local | task | full-day dates |

## Summary [UNSURE]

Exact values of `repeat_mode`; filter formats for Today; order of the buckets (`position`); position in saved filters; HTML vs Markdown in `description`; non-standard months/years; noon representation of dates; tag hierarchy; existence and name of the default Inbox project depending on the server version; semantics of an archived heading.
