# 05 - Risks of writing blind and CI checklist

Context: no Swift toolchain on the host. Every compilation error costs a CI round trip (`ios-tests.yml` + `macos-tests.yml`, macOS runners, `xcodegen generate` then `xcodebuild`). This document lists what, in this specific repository, is most likely to fail.

## 1. Project settings that drive the errors

| Observed fact | Consequence |
|:-|:-|
| `SWIFT_VERSION: "5.9"`, no `SWIFT_STRICT_CONCURRENCY` found | Swift 5 language mode: concurrency violations are generally warnings, not errors. The errors mostly come from `@MainActor` isolation called incorrectly and from explicit `Sendable`. Do not enable Swift 6 mode during the redesign |
| `xcodeVersion: "26.0"`, iOS 18 / macOS 15 deployment | Recent APIs are available (`SwiftUI.Tab`, `@Observable`, `ContentUnavailableView` already in use). Do not use an iOS 26 API without `#available` |
| A single `mDone` module for iOS and macOS | Any UIKit or ActivityKit API in an unguarded file breaks the macOS build |
| `mDone-macOS`: `PRODUCT_MODULE_NAME: mDone` | Do not rename this setting |
| macOS tests: hosted target, ad hoc signing, `mDone-macOS-CI.entitlements` entitlements | A new entitlement or app group can break `macos-tests.yml` |

## 2. Risks by category

### Concurrency and isolation

- `AppState` is `@Observable` (not `@MainActor` at class level); the mutating methods carry `@MainActor` one by one. A new method missing the annotation compiles but mutates off the main actor. Copy the existing pattern.
- Actors (`APIClient`, `*Service`, `SyncService`, `CalendarService`): every call is `await`. A method added to an actor and called from a view without `await` is an error.
- `FocusManager`, `FocusOutboxService`, `LiveListRefresh` are `@MainActor`: calling them from a non-isolated `Task { }` requires `await`.
- `SyncService` is an actor but its `queueOperation` / `queueTaskEdit` methods are marked `@MainActor` (access to the main SwiftData context): a fragile mix. Do not "simplify" it without tests (`SyncServiceTests`, `OfflineEditQueueTests`).
- `WidgetDataProvider` is `@unchecked Sendable`; `NetworkMonitor` and `ErrorBanner` use `DispatchQueue`. Keep these patterns as they are.
- Closures stored in `AppState` (`onTaskCompleted`, `onTaskDeleted`) and `FocusManager.taskLookup`: move them with care, they are non-`Sendable`.
- Closure parameters in the extracted stores: plan for an explicit `@MainActor` on the `@Observable` ViewModel types (see the comment in `QuickAddBar`: "Explicit `@MainActor`", otherwise isolation is inferred wrongly inside `Task {}`).

### `@Observable` (Observation framework)

- No `@Published`: any property read by a view and stored must be a property of an `@Observable` type. Computed properties (`todayTasks`) are re-evaluated on every read: recomputation cost on every change of `tasks`.
- `AppState` uses `@ObservationIgnored` for internal fields (`reorderGeneration`, `activeTaskUpdates`, `taskUpdateWaiters`). In an extracted store, every plumbing field must get the same annotation, otherwise spurious view updates appear.
- `didSet` on `tasks` and `isAuthenticated` increments `listRevision`; an extracted store must keep that behaviour, which `LiveListRefresh` and tests (`VisibleListRefreshTests`) can observe.
- Injection: `.environment(appState)` with `@Environment(AppState.self)`. An added `@Observable` type must be injected in `mDoneApp.appContent`, otherwise it crashes at runtime (no compilation error): a known risk for the iOS-only `FocusManager` (absent on macOS).
- `Bindable(appState).activeError` is already used; a local ViewModel uses `@Bindable` or `@State`.

### Platform separation

- The app code is compiled as it stands for iOS and macOS; 14 `#if os` in `AppState`, 15 in `TaskListScreen`, 8 in `ServerSetupView`, 8 in `mDoneApp`. After moving to `Platform/`, the `#if`s must stay balanced (`#if`/`#endif`): a partial copy breaks only one of the two CI jobs.
- `FocusManager` does not exist on macOS: any shared view that references `FocusManager` must be guarded (this is the case in `TaskRow`, `TaskDetailSheet`, `TaskListScreen`, `MainTabView`). The new Things components that show a Focus button must do the same.
- Common iOS-only elements: `UIKit`, `UIImpactFeedbackGenerator`, `.topBarTrailing`, `.fullScreenCover`, `.navigationBarTitleDisplayMode`, `UIApplication`. macOS: `.automatic`, `NSColor`, no `fullScreenCover`.
- Widgets: `LockScreenWidgets` and the Live Activity are compiled for macOS with an internal `#if os(iOS)`; do not break these guards while restyling.

### SwiftData

- Five `@Model`s: `CachedTask`, `CachedProject`, `CachedLabel`, `FocusRecord`, `PendingOperation`. **Do not modify their properties** during the redesign: a schema change without a migration goes through the store recovery of `ModelStoreBootstrap`, which can delete the cache and the offline queue (reported in #146, #155). Additions of optional fields are migrated automatically (comment in `CachedTask`); everything else needs validation on a real device.
- `@Attribute(.unique)` on `CachedTask.id`: inserting a duplicate performs an upsert, not an error.
- The tests create in-memory containers (`ModelStoreBootstrap.makeInMemoryContainer`); the test host (`isHostingUnitTests`) does not open the real store.
- `@Query` is not used in `Views/` (only `modelContext` appears in `QuickAddBar`, `FocusHistoryRow`, `FocusSyncSettingsSection`). Do not introduce `@Query` in the new views: it bypasses the Sync layer.

### Things -> Vikunja mapping (product decisions, not code)

Without a specification (`docs/things-spec/` is empty), these mappings are assumptions to validate before writing code:
- **Inbox** (Things): tasks without a project or a date. In mDone, `projectId` is always non-nil (`TaskCreateRequest`): choose the default project (`DefaultProjectPreference`) as "Inbox".
- **When / Deadline**: Vikunja only has `dueDate`, `startDate`, `endDate`. mDone uses `dueDate` as the deadline; `startDate` could carry the "When". Decision to document, because `occurs(on:)`, the widgets and `Calendar` read `effectiveDueDate`.
- **Someday, This Evening, Headings, Areas, Logbook**: no native equivalent. Candidates: reserved labels (like the "Current" label through `ensureCurrentLabel`), parent projects (`ProjectHierarchy`), buckets (`Bucket`), completed tasks (`done`, `doneAt`).
- Agents and web clients see the same tasks: a reserved label is visible on the web side.

### API and contract

- Task updates are `PATCH` merge-patch: every new write must go through `TaskUpdateRequest.onlyChanges(from:)`. A `PUT` erases the omitted fields.
- The existing `PendingOperation` rows are replayed as they are; do not change the `QueuedTaskEdit` format.
- New endpoints are declared in `Endpoint.swift`; check `docs/vikunja-api-inventory.md` first.

### Localisation, accessibility

- The strings are in `mDone/Localizable.xcstrings` (source `en`). A new string must exist in English; without a translation it is displayed in English. Do not use `String(localized:)` with dynamic keys.
- The widgets have their own catalog (`mDoneWidgets/Localizable.xcstrings`).
- No em-dash and no double hyphen in user text, comments or documentation (rule from `CLAUDE.md`). There is a check in the checklist.

## 3. Checklist to minimise CI iterations

Before every push:

1. **One topic per PR** (move OR change OR add).
2. **Balanced braces and `#if`/`#endif`**: count per modified file (`grep -c '^\s*#if' f` vs `grep -c '^\s*#endif' f`).
3. **Imports**: every file that uses `View`/`Color` imports `SwiftUI`; one that uses `@Model` imports `SwiftData` (the current code imports `Foundation` + `SwiftData` for `CacheService.swift`).
4. **Platform**: every UIKit/ActivityKit/`FocusManager` symbol is inside a `#if os(iOS)`; re-read every shared view asking "does this compile on macOS?".
5. **Isolation**: every new method of an `@Observable` type that mutates state carries `@MainActor`; every actor call carries `await`.
6. **Visibility**: everything is `internal` by default; tests use `@testable`. Do not add `private` to a member called by a test or by another extension in a different file (`private` is limited to the file).
7. **`private` and multi-file extensions**: splitting `AppState` into extensions in other files breaks the `private` members in use (`taskService`, `syncService`, `handleError`, `pushWidgetData`): make them `internal` or `fileprivate` deliberately, before the split.
8. **Names**: do not create a type homonymous with a SwiftUI/Foundation type (`Tab`, `Section`, `Label`, `Task`). The current code already writes `SwiftUI.Tab` to lift a collision, and `VLabel`, `VTask`, `VNotification` avoid `Label`/`Task`/`Notification`.
9. **`switch` exhaustiveness** on `MacContentView.SidebarSection` and `RelationKind`: an added `case` breaks every `switch` without a `default`. Search with `grep -rn 'SidebarSection'`.
10. **Initialisers**: `VTask` and `TaskUpdateRequest` are `Codable` structs with an implicit memberwise init; adding a field changes the init's order/parameters everywhere (tests included). Add fields with a default value.
11. **`project.yml`**: do not touch it; if a new root folder is needed, that is a separate PR with `xcodegen generate` verified in CI.
12. **Text**: search for the em-dash with `grep -rn` on the Unicode character U+2014 in the modified files, and re-read the new files for any double hyphen (apart from CLI options in the scripts).
13. **Previews**: a `#Preview` that references an iOS-only type breaks macOS; wrap them.
14. **Tests**: after a move, `find mDoneTests -name '*.swift' | wc -l` must stay at 74 + `Helpers` (2).
15. **Push as a draft**: open the PR as a draft, read the `xcodebuild` output of both jobs, fix in batches rather than push by push.

## 4. Organisational risks

| Risk | Mitigation |
|:-|:-|
| `AppState` is the call point for 22 test files and 28 views | Delegating facade; delete a method only after migrating its callers |
| Silent regression on the offline behaviour (no compilation catches it) | Do not touch `SyncService`/`QueuedTaskEdit`; run `OfflineEditQueueTests`, `SyncServiceTests` on every PR (already in the job) |
| Two UIs to maintain during the switch | Flag, limited duration (step 11 of plan 04) |
| Things specification missing | Write `docs/things-spec/` first (empty folder) with the rules of each list, then the `Domain/ThingsLists` tests before the views |
| The calendar "to improve" | The occurrence logic (`TaskOccurrence`, `TaskRecurrence`, `AppState.occurrences`) is tested: improve the grid without touching the logic |
| Widgets compiled by 5 targets | Do not add anything to `mDoneShared/` that depends on the app; check that `mDoneWidgetRenderTests` compiles (target without a host) |
