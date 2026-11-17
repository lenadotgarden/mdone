# 08 Drag and drop (Mac)

A single system, the macOS one (`onDrag` and `DropDelegate`), for two uses: **ordering** to-dos within a list, and **dropping** a to-do or a project onto a sidebar row. Complements `04-macos-screens.md` section 10 (table of Things sources and targets).

Code written without a compiler, to be validated by the macOS CI then on a Mac.

## 1. Model

```
Source                         Payload                      Targets
to-do row (list)         ->    ThingsDragPayload.todo(id)   -> the list itself (order, section)
                                                            -> sidebar row (project, Area, Inbox, Today, Someday)
project/Area row         ->    ThingsDragPayload.project(id)-> sidebar row (project, Area)
(sidebar)
```

The payload is a string (`mdone-todo:42`, `mdone-project:7`) written into the drag pasteboard as plain text: no UTType to declare. Both sources go through `ThingsDragItem.provider(for:)`, all targets accept `ThingsDragItem.contentTypes`. That is what guarantees the type is the same everywhere.

### Modules (`Features/Things/`, pure unless mentioned)

| File | Content |
|-|-|
| `Domain/Mapping/ThingsDragPayload.swift` | `ThingsDragPayload` (`todo`, `project`, `todoID`, `projectID`, encoding). |
| `ThingsDragDrop.swift` | `ThingsDropTarget` (list or sidebar project), `ThingsDropAction`, `ThingsDropFacts`, `ThingsDropResolver` (what a drop on a sidebar row does), `ThingsSectionID`, `ThingsDropRules` (which section changes make sense). |
| `ThingsDropGeometry.swift` | `ThingsDropSlot` (insertion point), `ThingsDropGeometry.slot` (Y pointer and row frames to slot), `shift` (how far each row slides). No layout value: the number of points comes from the frames. |
| `ThingsDropPlan.swift` | `ThingsDropPlan` (`reorder` or `changeSection`), `make(slot:movingID:sections:)`, `overrides`, `ThingsDropArrangement` (optimistic order, from one section to another). |
| `ThingsDragItem.swift` | `NSItemProvider` and asynchronous reading of the payload (Foundation and UniformTypeIdentifiers only). |
| `ThingsListViewModel+Reorder.swift` | `ThingsReorder` (unchanged), `commitReorder`, `commitDrop`. |
| `Platform/macOS/ThingsMacDragDrop.swift` | `ThingsDragSession`, `ThingsListDropDelegate`, `ThingsSidebarDropDelegate`, `ThingsSidebarDragSource`. |
| `Platform/macOS/ThingsMacTodoList.swift` | Drag source on each row, a single `DropDelegate` for the whole list, animation of the gap. |
| `Platform/macOS/ThingsMacSidebar.swift` | One target per row, highlight, drag source for projects and Areas. |
| `Platform/macOS/ThingsMacModel+Actions.swift` | `dropAction(for:on:)` (reads the state, calls the resolver) and `handleDrop(_:on:)` (executes). |

Tokens: `ThingsMotion.reorder` (spring of the gap opening and closing, of the row sliding and of the return), `ThingsMotion.reorderSwap` (keyboard), `ThingsMotion.dropTargetHighlight` (sidebar row highlight), `ThingsMetrics.Reorder.*` (drag image shadow, fallback gap height), `ThingsMetrics.Card.cornerRadius`, `ThingsColorOpacity.liftShadow`.

## 2. Ordering within the list

1. The drag starts on mouse movement (system threshold). The row is selected, haptic feedback is given, and the drag image is the row on a card with the lift shadow.
2. The whole list is a target. On each `dropEntered` and `dropUpdated`, `ThingsDropGeometry.slot` computes the slot: above the first row whose middle is below the pointer, or below the last one. Between two sections (header area), the nearest side wins.
3. While the pointer is in the list, the source row is hidden, the rows between the old and the new place slide by one row height (`reorder` spring): the gap opens where the to-do will land and closes where it was. `dropExited` sets the slot back to nil, everything returns, the source row reappears (so a cancelled drag leaves nothing hidden).
4. `performDrop` builds a `ThingsDropPlan` and validates it, applies the optimistic order (`orderOverride`, with animation), then `ThingsListViewModel.commitDrop` sends `AppState.moveTask(_:toPosition:)`. The position comes from `TaskPositioning` (same rules as the Vikunja web). When the server answers, the optimistic order is removed. If the send failed, the rows go back to their place (rollback).
5. A drop that changes nothing returns `false`: the system brings the image back to the row.

### Drop without a second animation

`performDrop` does not clear the slot before committing. `ThingsMacTodoList.apply(_:animation:landing:)` sets the optimistic order, clears the slot and flags `isLanding` in one transaction with animation disabled. The source row (`opacity` has `.animation(nil, value: isSource)`) and the sliding rows (`.animation(nil)` while `isLanding`) change at once, so the dragged row appears exactly where the gap was and no row moves a second time. When the save succeeds the optimistic order is removed without animation (it equals the server order); a failed save slides back with `ThingsMotion.reorder`. A drop that changes nothing closes the gap with the normal animation. Each saved move records an undo step (`ThingsMacModel.recordReorder`).

## 3. Between sections of the same screen

Rules (`ThingsDropRules.when(from:to:)`), everything else is refused:

| From | To | Effect |
|-|-|-|
| Today | This Evening | When = This Evening (label `things:evening`, via `ThingsListViewModel.schedule`) |
| This Evening | Today | When = Today (removes the label) |
| Project (open to-dos) | Someday group of the same project | When = Someday |
| Someday group | open to-dos of the same project | When removed (Anytime) |

Never a source or a target: Overdue (comes from a deadline), Upcoming (requires a date), Logged (comes from the finished state). The to-do takes a position between its neighbours in the target section (`TaskPositioning.position(forInserting:at:into:)`), sent after the When change. During the send, it is displayed in the target section (`ThingsDropArrangement`), the old section loses the row; a section with a title that becomes empty disappears.

A target section must contain at least one to-do to appear: you cannot drop into an absent section (empty This Evening).

## 4. On the sidebar

- A sidebar row is highlighted on hover only if `ThingsMacModel.dropAction` returns an action (so never for a drop with no effect: same project, cycle, meaningless list). The highlight is animated (`dropTargetHighlight`).
- Targets and effects (`ThingsDropResolver`): to-do on a project or Area = move; on Inbox = Inbox project; on Today or Someday = schedule (unless already there); project on a project or Area = re-parent (without a cycle). Upcoming, Anytime, Logbook refuse.
- The to-do leaves the list through the data change: `ThingsMacTodoList` animates id insertions and removals (`rowRemoval`), so the row closes like a completed to-do.
- The sidebar drop reads the payload from the pasteboard again (asynchronous) before acting; hover uses `ThingsDragSession`.

### ThingsDragSession

A target cannot read the pasteboard during hover, but must know what is being dragged. The source records the payload at the start of the drag (`ThingsDragSession.shared.begin`). No end-of-drag callback exists for `onDrag`: the session is cleared on drop and on the next click. It only serves the visual feedback and the hover validation.

## 5. Without a pointer

- Cmd-Opt-Up and Cmd-Opt-Down (and Cmd-Up and Cmd-Down): one notch, within the section (`ThingsReorder.plan(by:)`).
- Accessibility actions and the context menu: Move Up, Move Down, and Move to This Evening, Today, Someday or Anytime when the section 3 rule allows it (`ThingsDropRules.moves`). These are the same plans as a drag.
- Move... (Shift-Cmd-M) remains the keyboard way for a project or an Area.

## 6. Tests

`mDoneTests/Features/ThingsDropPlanTests.swift`: slot from the pointer (top and bottom of a row, header area, rows without a frame, filtered sections), row sliding, plans (same section, other section, refusal), section rules, optimistic order across sections, sidebar drop resolution, payload. `ThingsReorderTests` still covers `ThingsReorder` and `TaskPositioning`.

## 7. Known limits and leads

- No guaranteed auto-scroll during a drag near the edge (left to the system `ScrollView`, to verify on a Mac).
- No automatic unfolding of a folded Area on hover, nor opening a list on a prolonged hover.
- No drop of a to-do onto an Upcoming day or onto a tag (04 section 10), no multi-selection, no headings.
- Rows that change section cross-fade (removal and insertion) instead of sliding from one section to another.
- Off-screen rows have no frame (lazy list): the slot is computed on the visible rows, which is enough because the pointer is always on a visible row.
- A drag cancelled outside the window leaves the payload in `ThingsDragSession` until the next click; only the visual feedback of a target can depend on it.
- The labels `Move to This Evening`, `Move to Today`, `Move to Someday`, `Move to Anytime`, `Move` are to be added to `Localizable.xcstrings` (file from another batch).

## 8. Projects: nesting and sibling order (Mac)

Added with the project hierarchy work. A project row is a drag source (`ThingsDragPayload.project`) in two places: the sidebar and the sub-project list at the top of an Area or project screen (`ThingsMacSubprojectList`). Both use the same drop delegate, `ThingsProjectRowDropDelegate`, and the same pure decision, `ThingsProjectDropResolver`.

| Pointer on the row | Zone | Effect | Feedback |
|-|-|-|-|
| middle | `.into` | the project becomes a child of the row (`AppState.moveProject`) | row highlight |
| top edge | `.before` | the project lands before the row, under the row's parent | insertion line above |
| bottom edge | `.after` | the project lands after the row, under the row's parent | insertion line below |

- Edge height: `min(28% of the row, 8 pt)` (`ThingsRowDropZone.zone`). A to-do only uses the middle.
- An edge drop that is not legal falls back to the middle when that is legal (a loose project dropped on the edge of an Area nests into it). Nothing is highlighted when no zone is legal (self, a descendant, no change).
- `ThingsProjectOrdering.placement` computes the new parent and the Vikunja `position`: halfway between the two neighbours, `+ 65536` after the last one, half of the first one at the start (`TaskPositioning` rules). When the neighbours share a position (a fresh account has all zeros) the siblings are renumbered in steps of 65536 so the saved order is exact.
- Written by `AppState.placeProject` (`Features/Things/ThingsProjectActions.swift`): `PUT /projects/{id}` with the full field set plus `position`. `ProjectUpdateRequest` (Core) has no position, hence `ThingsProjectPlacementRequest`. The local list changes first and rolls back on failure.
- At the top level the sidebar shows loose projects first, then Areas, so an edge drop between a loose project and an Area is refused (`placement` returns nil).
- A row that shows its children right under it does not accept "after" (the line would be ambiguous); it nests instead.
- Limits: no auto-unfold of a folded row on hover, no drop on empty sidebar space to move to the top level (use Move Project...), the local cache of projects is not rewritten by `placeProject` (the next refresh is the source of truth).
