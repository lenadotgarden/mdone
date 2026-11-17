# 03 - Reuse or rewrite

Decisions: **KEEP** (unchanged, possibly moved), **REFACTOR** (logic kept, structure or dependencies changed), **REPLACE-UI** (the view is replaced by a Things view), **DELETE** (remove after replacement).

Rule applied: the model, network, sync, parsing and focus layers are kept; the views are replaced; `AppState` is split behind a facade.

## App/

| File | Decision | Reason |
|:-|:-|:-|
| `App/AppState.swift` (2726 lines) | REFACTOR | Split into stores/use cases (see 02 §4); keep an `AppState` facade as long as the 22 test files use it |
| `App/mDoneApp.swift` | REFACTOR | Keep the wiring (DEBUG auto-login, `isHostingUnitTests`, `onOpenURL`); scene root to connect to the new shell; move the Focus wiring out of `onAppear` |
| `App/AppDependencies.swift` | KEEP | SwiftData container + `NetworkMonitor` + guard for the test host |
| `App/ModelStoreBootstrap.swift` | KEEP | Recovery from a corrupted store, tested (`ModelStoreRecoveryTests`) |
| `App/AppIntents.swift` | KEEP | `QuickAddIntent`, `MDoneAppShortcuts`; must stay in the app target (#121) |
| `App/AddTaskIntent.swift` | REFACTOR | Keep everything; replace the `AppState.shared` access with a narrow protocol |
| `App/AdvancedTaskFilter.swift` | KEEP | Pure local filter, tested; move it to `Domain/Filtering` |
| `App/TaskSortOrder.swift` | KEEP | Sorting + persistence per scope, tested; check the persistence (`UserDefaults.standard`) |
| `App/QuickSchedule.swift` | KEEP | Postpone presets, pure; complete it with the Things presets (This Evening, Someday) |
| `App/CalendarPreferences.swift`, `CalendarSelection.swift` | KEEP | `WeekStartPreference`, `Calendar.app`, `HiddenCalendarStore`; essential to the calendar |
| `App/DefaultDueTimePreference.swift`, `NewTaskDueDatePreference.swift`, `DefaultProjectPreference.swift`, `SmartParsingPreference.swift`, `TeamFeaturesPreference.swift`, `ProjectViewPreference.swift`, `TaskListDensity.swift` | REFACTOR | Keep the types and their tests; group them in `Preferences` with typed keys; `TaskListDensity` / `ProjectViewPreference` may become moot depending on the Things UI |

## Models/

| File | Decision | Reason |
|:-|:-|:-|
| `Models/VTask.swift` | REFACTOR | Keep the model and `TaskUpdateRequest`; eventually extract `isOverdue/isDueToday/isDueTomorrow/isDueThisWeek/occurs/occurrenceDays` into `Domain/Scheduling` |
| `Models/Label.swift`, `VNotification.swift` | REFACTOR | Remove `import SwiftUI` (`VLabel.color`) into an extension in DesignSystem |
| `Models/Project.swift`, `ProjectHierarchy.swift`, `Bucket.swift`, `User.swift`, `TaskRelation.swift`, `TaskPositioning.swift` | KEEP | Vikunja model and position rules identical to the web app |
| `Models/TaskRecurrence.swift`, `TaskOccurrence.swift` | KEEP | Repeat projection, tested (`TaskRecurrenceTests`, `CalendarOccurrenceTests`); the basis of the improved calendar |
| `Models/QueuedTaskEdit.swift` | KEEP | Offline edit intention; persisted format, do not change |
| `Models/APIModels.swift` | KEEP | `NetworkError`, `ListPage`, login requests |
| `Models/AuthOptions.swift`, `ServerInfo.swift`, `VikunjaVersion.swift` | KEEP | Auth/server |
| `Models/FocusRun.swift` | KEEP | Pure model |
| `Models/CalendarEvent.swift`, `HexColor.swift` | KEEP | |

## Services/

| File | Decision | Reason |
|:-|:-|:-|
| `APIClient.swift`, `Endpoint.swift` | KEEP | v2 network core, JWT refresh, pagination; heavily tested (APIClientTests 900 lines, Refresh 793 lines) |
| `TaskService`, `ProjectService`, `LabelService`, `UserService`, `NotificationService`, `ServerInfoService` | KEEP | Thin actors |
| `AuthService.swift`, `JWTHelpers.swift`, `ServerURL.swift` | KEEP | |
| `OIDCLogin.swift`, `WebAuthenticator.swift` | KEEP | Tested (OIDCCallbackTests, WebAuthenticatorTests) |
| `SyncService.swift` | REFACTOR | Keep the behaviour; split into `PendingOperationQueue`, `LocalCache`, `Syncer` if time allows, otherwise KEEP |
| `CacheService.swift` | REFACTOR | Keep the `@Model`s **without changing the schema**; rename to `Persistence/CacheModels.swift` |
| `SmartTaskParser.swift` | KEEP | Pure parser, 460 lines of tests; the only action is to inject `DefaultDueTimePreference` and `Calendar` without depending on `App/` (already parameters of `init`) |
| `DescriptionMarkup.swift`, `DescriptionChecklist.swift` | KEEP | Pure, tested; becomes the model for the Things checklists if we use them |
| `EstimateMarker.swift`, `EstimateSuggester.swift` | KEEP | Documented contract (`docs/agent-contract-estimated-duration.md`) |
| `FocusManager.swift` | KEEP | iOS only; do not rewrite (589 lines, Live Activity); only the views are replaced |
| `FocusOutboxService.swift`, `FocusSyncConfig.swift`, `FocusHistoryQuery.swift`, `FocusDurationFormatter.swift` | KEEP | |
| `NetworkMonitor.swift`, `LiveListRefresh.swift`, `CalendarService.swift`, `TaskLink.swift` | KEEP | |

## mDoneShared/ and widgets

| File | Decision | Reason |
|:-|:-|:-|
| `SharedConstants.swift`, `SharedTokenStore.swift`, `FocusSession.swift`, `FocusTaskAttributes.swift`, `WidgetModels.swift` | KEEP | Must stay in `mDoneShared/` (compiled by the extensions) |
| `WidgetDataProvider.swift` | KEEP | Standalone client; do not touch the decoder without a test (`WidgetDataTests`) |
| `mDoneWidgets/*` (Today, Upcoming, QuickAdd, LockScreen, Live Activity, intents) | KEEP then REPLACE-UI | Function kept; Things skin (colours, fonts) in a second pass, after the app |
| `mDoneMacWidgets/` | KEEP | Plist and entitlements only |

## Views/

| File / folder | Decision | Reason |
|:-|:-|:-|
| `Views/MainTabView.swift` | REPLACE-UI | Things iOS shell; keep the alerts (failed sync, server version, undo) as reusable modifiers |
| `Views/Mac/MacContentView`, `MacSidebarView`, `MacTaskListView`, `MacTaskDetailView` | REPLACE-UI | Replaced by the shared Things shell; delete the iOS/Mac duplicates |
| `Views/Mac/MacKeyboardShortcuts.swift` | REFACTOR | Keep the shortcuts, rewire them to the new shell |
| `Views/Mac/MacArchivedProjectsView.swift`, `Views/Projects/ArchivedProjectsScreen.swift` | REPLACE-UI | Logbook / archived projects equivalent |
| `Views/Tasks/TaskListScreen.swift` | REPLACE-UI | Holds the section logic: extract it into `Domain` first |
| `Views/Tasks/TaskRow.swift` | REPLACE-UI | Things round checkbox; reuse swipe/menu (QuickSchedule, +24h, Current, Focus) |
| `Views/Tasks/TaskDetailSheet.swift` | REPLACE-UI | Things editor; keep the business sections (Repeat, Reminders, Priority, Focus, Current, Labels, Assignees) as components |
| `Views/Tasks/QuickAddBar.swift` | REPLACE-UI | Keep the parse/chips/suggestion logic as it is (extract into a ViewModel) |
| `Views/Tasks/TaskRelationsSections`, `TaskLabelsSection`, `TaskAssigneesSection`, `DescriptionChecklistView`, `RichTextRendering`, `DescriptionEditHint`, `InlineTaskDetail`, `SmartListSection` | REFACTOR | Reusable feature components; restyle. `SmartListSection` DELETE once the Things sections are in place |
| `Views/Projects/ProjectBoardView.swift` | REFACTOR | Kanban to keep (mDone feature); restyle |
| `Views/Projects/ProjectListScreen`, `ProjectRow`, `ProjectEditSheet` | REPLACE-UI | Things sidebar / Areas / projects |
| `Views/Calendar/*` | REFACTOR | Calendar to improve: keep `AppState.occurrences` (logic), redo the grid |
| `Views/Focus/*` | REFACTOR | `FocusSessionView` / `FocusBanner` restyled; `FocusRunOrder` to rewire onto the domain |
| `Views/Settings/*` | REFACTOR | Many business settings (14 keys); keep, restyle. `CalendarSelectionView` and `FocusSyncSettingsSection` KEEP |
| `Views/Setup/ServerSetupView.swift` | REFACTOR | Extract the login orchestration into a ViewModel, keep the screen working |
| `Views/Notifications/NotificationListView.swift` | REPLACE-UI | |
| `Views/Components/*` | see below | |

Components:

| File | Decision | Reason |
|:-|:-|:-|
| `ColorExtension`, `HexColor`-related, `LabelChip`, `PriorityBadge`, `ProjectColorDot`, `ColorSwatchPicker`, `EmptyStateView`, `LoadingOverlay` | REFACTOR | Move to `DesignSystem/` and re-tokenise |
| `ErrorBanner` | KEEP | Error banner + retry |
| `EstimatePicker`, `ReminderEditor`, `TaskScheduleEditor`, `TaskDateRangeMetadata`, `TaskShareButtons`, `TaskSortMenu`, `TaskFilterSheet`, `FilterBar`, `FocusHistoryRow` | REFACTOR | Keep the features, restyle |
| `ShakeDetector` | KEEP | Shake undo (iOS) |

## Tests, CI, tooling

| Element | Decision | Reason |
|:-|:-|:-|
| `mDoneTests/*` (74 files) | KEEP | Moving a source inside the module breaks no test (`@testable import mDone`) as long as the symbols keep their name |
| `AppStateTests.swift` | REFACTOR | Split as the extraction progresses; do not touch before the facade |
| `mDoneUITests`, `mDoneMacUITests` | REFACTOR | Screenshots to redo with the new UI |
| `mDoneIntegrationTests` | KEEP | Server contract |
| `mDoneWidgetRenderTests` | KEEP | |
| `project.yml`, workflows, `.swiftlint.yml`, `.swiftformat` | KEEP | Do not modify them during the moves |
| `website/`, `screenshots/`, `scripts/`, `localization/` | KEEP | Outside the scope of the app code |

## Summary

- **KEEP or almost**: all of `Services/`, `Models/`, `mDoneShared/`, `mDoneWidgets/` (function), `mDoneTests/`.
- **REFACTOR**: `AppState`, `mDoneApp`, preferences, `SyncService`/`CacheService` (tidying up), the functional components of `Views/`.
- **REPLACE-UI**: shells (`MainTabView`, `Mac*`), lists, task row, detail, quick add (skin), projects, notifications.
- **DELETE**: Mac duplicates of the lists/details, `SmartListSection`, old home views, once the Things layer is in production.
