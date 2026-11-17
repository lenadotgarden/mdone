# 04 - Proposed target structure and migration plan

Constraint: no Swift compiler on the host, the GitHub CI (macOS) is the only compilation loop. The plan therefore favours **mechanical** steps (moving files without modifying code) before any logic change.

## 1. Why the moves are safe (verified in `project.yml`)

- The `mDone` and `mDone-macOS` targets declare `sources: [mDone, mDoneShared]` (whole folders, recursive). A file moved into a subfolder of `mDone/` stays compiled without modifying `project.yml`.
- A Swift file moved **inside the same module** changes no symbol: the tests (`@testable import mDone`) are not affected. Swift has no link between file path and visibility.
- `mDoneTests/` is a flat folder included by glob in `mDoneTests` and `mDoneMacTests`: a new mirror subfolder works with no change (same mechanism as `mDoneTests/Helpers/`, already present).
- `project.yml` has `generateEmptyDirectories: true`: no harmful effect for empty folders.
- **Do not move** (referenced by path): `mDone/Info.plist`, `mDone/*.entitlements` (including `mDone-macOS-CI.entitlements` used by `macos-tests.yml`), `mDone/Localizable.xcstrings`, `mDone/InfoPlist.xcstrings`, `mDone/Resources/` (excluded from SwiftLint/SwiftFormat, holds `Assets.xcassets` and `PrivacyInfo.xcprivacy`), `mDoneWidgets/Info.plist`, `mDoneMacWidgets/`.
- `mDoneShared/` is compiled by **5** targets (iOS app, macOS app, iOS and macOS extensions, `mDoneWidgetRenderTests`). Do not add anything there that imports a type from `mDone/`.
- **File** paths appear in `.swiftlint.yml` (`included: mDone, mDoneTests`): a new root folder outside `mDone/` would not be linted; keep everything under `mDone/`.

## 2. Target structure

Everything stays in the `mDone` module (a single target): no Swift Package and no new target at this stage (see 05, risk of blind configuration). The layers are **folders**, the import rule is checked by a script (§5).

```
mDone/
  App/                       entry point, composition
    mDoneApp.swift, AppDependencies.swift, AppIntents.swift, AddTaskIntent.swift
    AppState.swift           (facade, slimmed down at each step)
    Navigation/              AppRoute, shared iOS/macOS router
  Core/
    Models/                  VTask, Project, VLabel (without SwiftUI), Bucket, User, TaskRelation, ServerInfo, ...
    Networking/              APIClient, Endpoint, *Service (actors), AuthService, JWTHelpers, ServerURL, OIDCLogin, WebAuthenticator
    Persistence/             CacheModels (formerly CacheService), ModelStoreBootstrap
    Sync/                    SyncService, QueuedTaskEdit, NetworkMonitor, LiveListRefresh
    Preferences/             *Preference types, typed keys
  Domain/
    ThingsLists/             Inbox, Today, Upcoming, Anytime, Someday, Logbook: pure functions VTask -> sections
    Scheduling/              VTask date rules, QuickSchedule, TaskOccurrence, calendar
    Repeat/                  TaskRecurrence
    Parser/                  SmartTaskParser, EstimateMarker, EstimateSuggester, DescriptionMarkup, DescriptionChecklist
    Filtering/               AdvancedTaskFilter, TaskSortOrder, TaskPositioning
    Focus/                   FocusRun, FocusHistoryQuery, FocusDurationFormatter
  Features/<Feature>/        View + ViewModel (@Observable, @MainActor)
    Today/ Upcoming/ Inbox/ Anytime/ Someday/ Logbook/
    TaskDetail/ QuickAdd/ Projects/ Board/ Calendar/ Focus/ Settings/ Setup/ Notifications/ Sidebar/
  DesignSystem/
    Tokens/                  colours, typography, spacings
    Components/              round checkbox, task row, chips, priority badge, project dot
    Icons/
  Platform/
    iOS/                     MainTabView/iOS shell, ShakeDetector, FocusManager (iOS only), FocusOutboxService
    macOS/                   NavigationSplitView shell, MacKeyboardShortcuts
  Resources/                 (unchanged: Assets.xcassets, PrivacyInfo.xcprivacy)
  Info.plist, *.entitlements, Localizable.xcstrings   (unchanged)
mDoneShared/                 unchanged (shared with the extensions)
mDoneWidgets/                unchanged (Things skin later)
mDoneTests/
  Core/ Domain/ Features/ App/ Helpers/    (mirror; subfolders added by glob)
```

`FocusManager` and `FocusOutboxService` (iOS only) go to `Platform/iOS/`: a mechanical move, the file keeps its internal `#if os(iOS)`.

## 3. Table of old path -> new path

| Old | New |
|:-|:-|
| `mDone/Models/VTask.swift`, `Project.swift`, `Bucket.swift`, `User.swift`, `TaskRelation.swift`, `APIModels.swift`, `AuthOptions.swift`, `ServerInfo.swift`, `VikunjaVersion.swift`, `VNotification.swift`, `Label.swift`, `HexColor.swift`, `CalendarEvent.swift`, `ProjectHierarchy.swift` | `mDone/Core/Models/` |
| `mDone/Models/QueuedTaskEdit.swift` | `mDone/Core/Sync/` |
| `mDone/Models/TaskRecurrence.swift` | `mDone/Domain/Repeat/` |
| `mDone/Models/TaskOccurrence.swift` | `mDone/Domain/Scheduling/` |
| `mDone/Models/TaskPositioning.swift` | `mDone/Domain/Filtering/` |
| `mDone/Models/FocusRun.swift` | `mDone/Domain/Focus/` |
| `mDone/Services/APIClient.swift`, `Endpoint.swift`, `TaskService.swift`, `ProjectService.swift`, `LabelService.swift`, `UserService.swift`, `NotificationService.swift`, `ServerInfoService.swift`, `AuthService.swift`, `JWTHelpers.swift`, `ServerURL.swift`, `OIDCLogin.swift`, `WebAuthenticator.swift`, `TaskLink.swift`, `CalendarService.swift` | `mDone/Core/Networking/` (CalendarService: `Core/Calendar/` or `Features/Calendar/`) |
| `mDone/Services/SyncService.swift`, `NetworkMonitor.swift`, `LiveListRefresh.swift` | `mDone/Core/Sync/` |
| `mDone/Services/CacheService.swift` | `mDone/Core/Persistence/CacheService.swift` (file renamed later) |
| `mDone/App/ModelStoreBootstrap.swift` | `mDone/Core/Persistence/` |
| `mDone/Services/SmartTaskParser.swift`, `EstimateMarker.swift`, `EstimateSuggester.swift`, `DescriptionMarkup.swift`, `DescriptionChecklist.swift` | `mDone/Domain/Parser/` |
| `mDone/Services/FocusHistoryQuery.swift`, `FocusDurationFormatter.swift` | `mDone/Domain/Focus/` |
| `mDone/Services/FocusManager.swift`, `FocusOutboxService.swift`, `FocusSyncConfig.swift` | `mDone/Platform/iOS/` (FocusSyncConfig: `Core/Preferences/`) |
| `mDone/App/AdvancedTaskFilter.swift`, `TaskSortOrder.swift` | `mDone/Domain/Filtering/` |
| `mDone/App/QuickSchedule.swift` | `mDone/Domain/Scheduling/` |
| `mDone/App/*Preference*.swift`, `TaskListDensity.swift`, `CalendarPreferences.swift`, `CalendarSelection.swift` | `mDone/Core/Preferences/` |
| `mDone/App/AppState.swift` | stays in `mDone/App/`, emptied by extraction into `Core/` and `Features/` |
| `mDone/Views/Tasks/QuickAddBar.swift` | `mDone/Features/QuickAdd/` |
| `mDone/Views/Tasks/TaskListScreen.swift`, `SmartListSection.swift`, `InlineTaskDetail.swift` | `mDone/Features/Today/` etc. (replaced) |
| `mDone/Views/Tasks/TaskRow.swift` | `mDone/DesignSystem/Components/` (replaced) |
| `mDone/Views/Tasks/TaskDetailSheet.swift`, `TaskRelationsSections.swift`, `TaskLabelsSection.swift`, `TaskAssigneesSection.swift`, `DescriptionChecklistView.swift`, `RichTextRendering.swift`, `DescriptionEditHint.swift` | `mDone/Features/TaskDetail/` |
| `mDone/Views/Projects/*` | `mDone/Features/Projects/` (`ProjectBoardView`: `Features/Board/`) |
| `mDone/Views/Calendar/*` | `mDone/Features/Calendar/` |
| `mDone/Views/Focus/*`, `Views/Components/FocusHistoryRow.swift` | `mDone/Features/Focus/` |
| `mDone/Views/Settings/*` | `mDone/Features/Settings/` |
| `mDone/Views/Setup/ServerSetupView.swift` | `mDone/Features/Setup/` |
| `mDone/Views/Notifications/*` | `mDone/Features/Notifications/` |
| `mDone/Views/Components/ColorExtension.swift`, `LabelChip`, `PriorityBadge`, `ProjectColorDot`, `ColorSwatchPicker`, `EmptyStateView`, `LoadingOverlay`, `ErrorBanner` | `mDone/DesignSystem/Components/` |
| `mDone/Views/Components/EstimatePicker`, `ReminderEditor`, `TaskScheduleEditor`, `TaskDateRangeMetadata`, `TaskShareButtons`, `TaskSortMenu`, `TaskFilterSheet`, `FilterBar` | `mDone/Features/TaskDetail/` or `Features/Filters/` |
| `mDone/Views/Components/ShakeDetector.swift` | `mDone/Platform/iOS/` |
| `mDone/Views/MainTabView.swift` | `mDone/Platform/iOS/` |
| `mDone/Views/Mac/*` | `mDone/Platform/macOS/` (the views to be replaced stay there until they are deleted) |
| `mDoneTests/*Tests.swift` | mirror subfolders (final, optional step) |

## 4. Migration steps (each one keeps the CI green)

Principle: one step = one PR, verifiable by the existing iOS and macOS CI. Steps 1 to 4 only change paths.

| # | Step | Nature | Risk | Verification |
|:-|:-|:-|:-|:-|
| 0 | Land `docs/architecture-audit/` and a `scripts/check-layering.sh` script (grep of the imports, see §5) in warning mode | Addition | None | The script passes on the current repository with the list of known violations |
| 1 | Move `Models/` to `Core/Models`, `Domain/*` (see table). No content modified | Mechanical | Low | iOS + macOS CI compile; `mDoneTests` + `mDoneMacTests` green |
| 2 | Move `Services/` to `Core/Networking`, `Core/Sync`, `Core/Persistence`, `Domain/Parser`, `Platform/iOS` | Mechanical | Low | Same. `FocusManager` is in a file entirely under `#if os(iOS)`: macOS never sees it, no change |
| 3 | Move the preferences and filters of `App/` to `Core/Preferences`, `Domain/Filtering` | Mechanical | Low | Same |
| 4 | Move `Views/` to `Features/`, `DesignSystem/`, `Platform/` (without rewriting) | Mechanical | Low | Same; watch `mDoneUITests`, compiled by the iOS scheme |
| 5 | Remove `import SwiftUI` from `Models/Label.swift` and `VNotification.swift` (`Color` extensions moved to DesignSystem) | Minimal change | Medium (`color` properties) | CI; `ProjectColorTests`, `VTaskColorTests` |
| 6 | Extract `Domain/ThingsLists`: pure functions `(tasks, now, calendar) -> ThingsListContent`, with new tests; `AppState.todayTasks` etc. delegate | Addition + delegation | Medium | The existing tests (`CurrentTasksTests`, `AppStateTests`) stay green; new Domain tests |
| 7 | `pushWidgetData` uses `Domain/ThingsLists` (removes the duplication, mind the `endOfDay` vs `+7 days` difference) | Change | Medium | `WidgetDataTests` |
| 8 | Extract one domain at a time from `AppState` (order: Notifications, Calendar, Kanban, Projects, Labels/Current, Relations, then Tasks); `AppState` keeps delegating properties/methods | Refactor | Medium to high | `AppStateTests` unchanged and green on every PR |
| 9 | Central `Preferences`: replace the strings `"calmMode"`, `"currentStallDays"`, `"notificationsEnabled"`, `"reminderOffset"` with typed keys | Change | Low | Same key values: no user migration |
| 10 | `DesignSystem/Tokens` + isolated Things components, with previews | Addition | Low | Compilation only |
| 11 | New Things `Features/*` behind a flag (`AppDependencies` or `@AppStorage`); the old UI still reachable | Addition | Medium | UI screenshots |
| 12 | Switch over, then delete the old UI (DELETE in 03) and the Mac duplicates | Deletion | Medium | Deletion in a PR separate from the switch |
| 13 | Mirror `mDoneTests/` by subfolders | Mechanical | Low | Compilation of both test targets |

Rules for the mechanical steps: one kind of move per PR; no type renaming in the same PR; do not touch file contents; use `find` to check that the number of `.swift` files before and after is identical (apart from added files).

## 5. Layer rules (allowed imports)

Folders under `mDone/`, from the lowest to the highest:

```
Core/Models, Domain  <  Core/(Networking, Persistence, Sync, Preferences)  <  Features, DesignSystem  <  Platform  <  App
```

| Folder | May import / reference | Forbidden |
|:-|:-|:-|
| `Core/Models`, `Domain/*` | Foundation only | SwiftUI, UIKit, AppKit, SwiftData, EventKit, `AppState`, `Core/Networking`, direct UserDefaults |
| `Core/Networking` | Foundation, Security, AuthenticationServices, `Core/Models`, `mDoneShared` | SwiftUI, `Features`, `AppState` |
| `Core/Persistence`, `Core/Sync` | Foundation, SwiftData, Network, `Core/Models`, `Core/Networking`, `Domain` | SwiftUI, `Features` |
| `Core/Preferences` | Foundation (UserDefaults through `SharedKeys` / `StorageScope`) | Raw `UserDefaults.standard`, SwiftUI |
| `DesignSystem` | SwiftUI, `Core/Models` read-only | `AppState`, services, SwiftData |
| `Features/<X>` | SwiftUI, `Core`, `Domain`, `DesignSystem` | Another `Features/<Y>` (go through `App/Navigation`); direct network; `#if os` outside `Platform/` except small modifiers |
| `Platform/iOS`, `Platform/macOS` | everything except the other platform | Being referenced from `Core`/`Domain` |
| `App` | everything | |
| `mDoneShared` | Foundation, Security, ActivityKit, SwiftUI if strictly necessary | **Anything that is in `mDone/`** |
| `mDoneWidgets` | `mDoneShared`, WidgetKit, SwiftUI, AppIntents | `mDone/` |

Enforcement: `scripts/check-layering.sh` (grep of `^import` per folder + `AppState` outside `App`/`Features`) run in CI as a warning step, then blocking once the repository is clean. It works blind, without a compiler: it is a plain `grep`.

## 6. Particular guard rails

- Symbols keep their name during the moves; renaming a file (`CacheService.swift` -> `CacheModels.swift`) is a separate PR.
- Do not create two files with the same name in two folders: Xcode accepts it, but test files and error messages become ambiguous.
- Keep `FocusManager.swift` entirely under `#if os(iOS)`: its imports (`ActivityKit`, `UIKit`) do not compile on macOS.
- Do not move the `.xcstrings` files: their location is described in `docs/localization.md`, to be re-read before any change.
