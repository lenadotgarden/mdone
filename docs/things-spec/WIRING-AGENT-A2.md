# Wiring notes, agent A2 (stability, performance, completeness, session)

Changes in files that agent A2 does not own. Nothing here is required for the app to build: everything
already compiles against the new code. These are the follow-ups that make the Mac window fully benefit.

## 1. ThingsMacTodoList.swift: keep the keyboard focus (problem: arrows stop after switching apps)

Root cause: `listFocused` (a `@FocusState`) is reset by AppKit when the app resigns and regains the
key window, and nothing sets it again. The arrow keys are only delivered to a focused list.

`ThingsTypeTravel` (A2 owned) now bumps `model.listFocusToken` on `NSApplication.didBecomeActiveNotification`,
on `NSWindow.didBecomeKeyNotification` of a main-capable window, on `scenePhase == .active`, and when
`model.selectedTaskID` becomes non nil, unless a text field, the open card, Quick Find, a sheet or an
alert holds the keyboard. The list already reacts with `.onChange(of: model.listFocusToken) { listFocused = true }`.

Optional hardening inside the list (single focus owner, no token needed):

```swift
// next to .focused($listFocused)
.onChange(of: listFocused) { _, focused in
    // Lost without anything else taking it: ask again once.
    if !focused, NSApp.isActive, !model.isAddingTodo, model.expandedTaskID == nil, !model.showQuickFind {
        DispatchQueue.main.async { listFocused = true }
    }
}
```

Do not add a second `@FocusState` for the same list, and do not call `listFocused = true` from several
places per event: use the token.

## 2. ThingsMacSidebar.swift and ThingsMacModel.swift: cheaper redraws

- `ThingsMacModel.projectTree` rebuilds a tree on each read. `ThingsProjectTree.build` is now memoized
  (`ThingsProjectTreeMemo`), so it is cheap, but `ThingsProjectTree.allNodes` and `node(id:)` still rebuild
  an array on each read. If the tree owner adds a stored `allNodes` and an id index, `visibleSubtree` and
  `node(id:)` become O(1).
- `ThingsMacSidebar.nodeRow` calls `model.viewModel(for: .anytime).progress(ofProject:)` per node. That is now
  a dictionary lookup (`ThingsListsCache.progressByProject`), no change needed.
- `ThingsMacSidebar.listRow` calls `listModel.count(for:)`: now a lookup in the memoized snapshot.
- `ThingsMacListScreen.body` calls `ThingsRowMapper.applyingProjectLine(to:projects:...)` for every section on
  every body evaluation: it builds a title dictionary and copies every row. Cheap enough for hundreds of
  rows, but for thousands, compute the project titles once per `appState.projects` change (for example a
  `@State` keyed on `model.appState.projects.count` plus the max `updated`).
- `ThingsTodayEvents.load()` is already `async` in `.task(id: list)`. It must stay off the render path.

## 3. Reorder and session (problem: Cmd-Opt-Up signed the user out)

Nothing to change in `ThingsMacTodoList` or `ThingsMacCommands`. The fix is in `APIClient` and `AppState`:
`commitReorder` and `commitDrop` call `AppState.moveTask`, which calls `TaskService.updatePosition`; an error
is only shown through `handleError` (a banner). The session now ends only when the refresh token itself is
rejected. See `SessionStabilityTests` and `APIClientRefreshTests`.

A refused position update shows the generic banner "Something went wrong with that request. Please try
again." and never the "Your session has expired" one.
