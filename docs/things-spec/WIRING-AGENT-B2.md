# Wiring notes, agent B2 (list interactions, undo, popovers, animations)

Code written without a compiler. To be checked by the macOS CI and on a Mac.

## What the other owners must wire

Files owned by other agents were not edited. Two small additions are needed there.

1. `ThingsMacRootView.swift` (or `ThingsMacRootModifiers.swift`): apply the Space key to the whole window, next to `.thingsTypeTravel(model: model)`:

   ```swift
   .thingsMacSpaceKey(model: model)
   ```

   Without it Space works only while the list has the keyboard. With it, Space also works after a click on a project in the sidebar (new to-do at the top of the project).

2. Logout: call `model.clearUndoHistory()` when the session ends. `ThingsMacModel` already clears itself lazily (every `recordUndo`, `performUndo` and `performRedo` checks `appState.isAuthenticated`), so this is optional, but it drops the closures at once.

3. `ThingsMacSidebar.swift` (agent C): nothing is required. If a sidebar row handles Space itself, call `model.addTodoFromSpace()` from it.

4. `ThingsMacRootModifiers.swift`: the delete alert (`pendingDeletion`, `confirmDeletion`) is no longer reached: Delete removes at once and relies on undo. The properties are kept so the file still compiles; the alert and the two checks in `ThingsTypeTravel.swift` can be removed in a later cleanup.

## New and changed API

| Item | File |
|-|-|
| `ThingsUndoStack`, `ThingsUndoCommand` (depth 100, coalescing, tested) | `Features/Things/ThingsUndoStack.swift` |
| `ThingsTaskSnapshot`, `ThingsWhenState` | `Features/Things/ThingsUndoSnapshot.swift` |
| `ThingsMacModel`: `recordUndo`, `performUndo`, `performRedo`, `undoMenuTitle`, `redoMenuTitle`, `canUndo`, `canRedo`, `textEditingActive`, `clearUndoHistory`, `liveID` | `Platform/macOS/ThingsMacModel+Undo.swift` |
| `ThingsMacModel`: `tapCheckbox`, `deleteSelected`, `delete`, `addTodoFromSpace`, `finishAdding(title:siblings:)`, `applyWhen`, `setReminder`, checklist edits | `ThingsMacModel+Actions.swift`, `+Checklist.swift`, `ThingsMacWhenPopover.swift` |
| `ThingsMacModel.insertAfterTaskID`, `rowPopover`, `closeRowPopover` | `ThingsMacModel.swift` |
| `ThingsCalendarGrid`, `ThingsCalendarMonth`, `ThingsWhenInput` | `DesignSystem/Components/Things`, `Domain/Mapping` |
| `ThingsMotion.checkDraw`, `ThingsMetrics.DatePopover`, `ThingsMetrics.Strike`, popover and calendar fonts | `DesignSystem/Tokens` |

Every code path that completes a to-do from the Mac Things UI must go through `ThingsMacModel.tapCheckbox` (not `ThingsListViewModel.tapCheckbox`) so the step is recorded. The Mac list, the card and the menu already do.

## Unverified

See the final report of the task: nothing was compiled or run.
