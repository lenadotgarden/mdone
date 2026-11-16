# Wiring notes, agent 1 (sidebar, project tree, move)

Changes other owners must apply (files not touched by agent 1).

## 1. ThingsMacTodoList.swift: make to-do rows draggable

Drop targets exist on every sidebar row (project, Area, Inbox, Today, Someday). A to-do row must offer the payload:

```swift
.draggable(ThingsDragPayload.todo(task.id).encoded)
```

Put it on the row view (same level as the tap and selection modifiers). Without it, only projects can be dragged.

## 2. Area screen: use the tree for the projects under an Area

`ThingsHomeViewModel.areas` and `.looseProjects` still use the old rule (marker only, two levels). In `ThingsMacListScreen` (and the iPhone Home/Area screens), read the children from the new tree instead:

```swift
let node = model.projectTree.node(id: areaID)   // ThingsProjectNode?
let rows = node?.children ?? []                  // [ThingsProjectNode], nested via .children
```

`ThingsProjectTree.build(projects:inboxProjectID:)` is pure and can be used from `ThingsHomeViewModel` too.

## 3. DesignSystem tokens wanted

`ThingsMacSidebar.swift` keeps these local (`ThingsSidebarStyle`) until tokens exist:
- selected row fill: `textPrimary` at 0.12 (about #3b3e42 on the dark sidebar), radius 6;
- group gap 16 (Spacing.l), indent per nested level 16, chevron width 10.
Suggested: `ThingsColorToken.sidebarSelection` (dark 0x3B3E42, light 0xE0E2E6) and `ThingsMetrics.Sidebar`.

## 4. DEVIATIONS.md rows to replace

Row "04 section 1 (sidebar)": "Counters for Inbox and Today only, hidden at zero. The full tree is shown: loose projects, then each Area with all its descendants (any depth, foldable chevron on hover, Cmd-click folds all). A root project with children is an Area even without the `things:area` marker (Domain/Mapping/ThingsProjectTree). Trash absent. The filter button at the bottom right is a fold/unfold menu, not the tag filter. Drag a to-do onto a project, Area, Inbox, Today or Someday; drag a project onto an Area or project to re-parent it (statut: stopgap, needs to-do row `.draggable`, see 1)."

Row "04 section 4 (Move)": "Move : filtre, Inbox, arbre complet des projets ; pour un projet ou une Area : No Area (racine) ou n'importe quel projet hors lui-meme et ses descendants. Pas de headings ni de projets inactifs."

Side effect of the rule: moving the last child out of an unmarked Area turns it back into a loose project.

## 5. Behaviour of Shift Cmd M

`ThingsMacModel.requestMove()` (menu item Items > Move...): a selected to-do opens its card and the Move popover (existing path); with no selected to-do and a project or Area on screen, the popover opens in the sidebar, anchored on that row (`projectMoveRequest`). It needs the sidebar visible.

> Obsolete (voir `08-drag-and-drop.md`) : le point 1 est fait, mais par `onDrag` et `ThingsDragItem.provider(for:)` au lieu de `.draggable`, pour que toutes les sources et cibles partagent le meme payload et la meme session.
