# 02 - Current architecture

## 1. Actual layers

```
Targets (project.yml)
  mDone (iOS)  ===\
                    +== same sources: mDone/ + mDoneShared/   (module "mDone")
  mDone-macOS  ===/   (PRODUCT_MODULE_NAME: mDone pinned)
  mDoneWidgets (iOS ext)     : mDoneWidgets/ + mDoneShared/
  mDoneMacWidgets (macOS ext): mDoneWidgets/ (minus Info.plist, *.entitlements) + mDoneShared/
  mDoneWidgetRenderTests     : mDoneWidgets/ (minus mDoneWidgets.swift) + mDoneShared/ + its tests, without a host
  mDoneTests / mDoneMacTests : SAME mDoneTests/ files, hosts mDone / mDone-macOS, @testable import mDone

mDone/
  App/        14 "preference" types + AppState (2726 lines) + intents + SwiftData bootstrap + sort/filter/quickschedule (domain)
  Models/     Vikunja Codable structs + domain logic (recurrence, positioning, hierarchy, relations)
  Services/   network actors (APIClient, TaskService...), SyncService, CacheService (@Model), pure parsers, Focus*, OIDC
  Views/      Tasks, Projects, Calendar, Focus, Settings, Setup, Notifications, Components, Mac
mDoneShared/  storage constants, shared keychain token, widget models, widget HTTP client, Live Activity attributes
```

There is **no ViewModel layer**. Views talk directly to a single object, `AppState`, injected through `.environment(appState)` in `mDoneApp.swift`.

## 2. Dependency graph (observed)

```
mDoneApp -creates-> AppDependencies (ModelContainer, NetworkMonitor, StoreRecovery)
   │                       │
   ├-creates-> AppState ─┼── TaskService / ProjectService / LabelService / UserService / ServerInfoService (actors, injected by init)
   │               │       ├── AuthService.shared, NotificationService.shared (singletons, NOT injected)
   │               │       ├── SyncService (injected afterwards by configureSyncService)
   │               │       ├── CalendarService() (hard-coded, line 80)
   │               │       ├── WidgetDataProvider.shared (pushWidgetData)
   │               │       └── UserDefaults.standard (8 direct uses)
   │               └──> AppState.shared (weak static) <── AddTaskIntent, QuickAddIntent
   ├-creates-> FocusManager (iOS), FocusOutboxService (iOS)  ──> ModelContainer
   │                 ^ wired by closures: appState.onTaskCompleted/onTaskDeleted, focusManager.taskLookup (mDoneApp.onAppear)
   └──> Views : 28 files read AppState ; TaskListScreen 28 distinct members, MacTaskListView 20, MacSidebarView 16, MainTabView 13

APIClient.shared (actor singleton) <── every *Service, SyncService (default), AuthService
SyncService ──> TaskService, ProjectService, ModelContainer, APIClient
Widgets ──> WidgetDataProvider (direct HTTP, duplicated decoder) + SharedTokenStore + SharedKeys.sharedDefaults
```

Services never reference `AppState` (only mentions: comments in `APIClient`, `FocusManager`, `SyncService`, `TaskService`). The direction of the Services -> AppState dependency is therefore clean: the problem is AppState itself and the Views.

## 3. Size hotspots (outside tests)

| File | Lines | Note |
|:-|:-|:-|
| `App/AppState.swift` | 2726 | ~330 members, 100+ methods |
| `Services/DescriptionMarkup.swift` | 823 | pure, well tested (`DescriptionMarkupTests`) |
| `Services/SmartTaskParser.swift` | 762 | pure, well tested |
| `Services/APIClient.swift` | 658 | network + JWT refresh |
| `Views/Tasks/TaskListScreen.swift` | 593 | section logic + view |
| `Services/FocusManager.swift` | 589 | iOS, SwiftData + ActivityKit |
| `Views/Tasks/TaskRow.swift` | 510 | 4 `@AppStorage` + swipe + menu |
| `Views/Setup/ServerSetupView.swift` | 484 | login + OIDC + TOTP inside the view |
| `Services/SyncService.swift` | 472 | queue + cache + sync |
| `Views/Projects/ProjectBoardView.swift` | 452 | |
| `Models/VTask.swift` | 452 | model + date rules + queries |
| `mDoneWidgets/TodayTasksWidget.swift` | 447 | |

## 4. AppState: responsibilities to extract

Line numbers from `mDone/App/AppState.swift` (approximate, based on the `MARK`s and signatures).

| # | Responsibility | Lines | Key members | Proposed destination |
|:-|:-|:-|:-|:-|
| 1 | Session / auth / bootstrap | 401-640 | `checkAuth`, `login*`, `completeLogin`, `requireSupportedServer`, `logout`, `expireSession`, `tearDownSession`, `registerAPIClientHandlers` | `SessionStore` (`@Observable`) |
| 2 | Connectivity and retry | 187-270 | `isOffline`, `handleConnectivityChange`, `onNetworkRestored`, `updateRetryState`, `isRetrying` | `ConnectivityStore` or inside Sync |
| 3 | Global loading / refresh + cache hydration | 643-850, 2036-2110 | `hydrateFromCache`, `persistToCache`, `refreshAll`, `refreshCachedProjectOrders`, `refreshVisibleList`, `applyQuietRefresh`, `isShowingCachedData` | `TaskRepository` (Core/Sync) |
| 4 | Task repository (canonical list in memory) | 20-24, 849-960, 1952-2035 | `tasks`, `projectTaskCache`, `merging`, `uniquedById`, `preservingRelations`, `preservingSchedule`, lock `acquireTaskUpdateSlot` | `TaskRepository` |
| 5 | Task mutations | 1049-1250, 1473-1625, 1887-1950 | `toggleTaskDone`, `undoLastCompletion`, `createTask`, `postponeTask`, `rescheduleTask`, `updateTask`, `setProgress`, `deleteTask` | `TaskActions` (use cases) |
| 6 | Smart lists / date derivatives | 273-325, 2410-2470, 2618-2660 | `overdueTasks`, `todayTasks`, `tomorrowTasks`, `thisWeekTasks`, `upcomingTasks`, `noDateTasks`, `occurrences`, `occurrencesByDay` | `Domain/Lists` (pure functions) |
| 7 | Search / filters / sorting | 64-68, 320-355, 2603-2616 | `searchQuery`, `activeFilter`, `advancedFilter`, `applyingFilters`, `sortPreference` | `Domain/Filtering`, view state in a ViewModel |
| 8 | Offline queue | 959-1050 | `queueOfflineEdit`, `rejectOffline`, `refreshPendingState`, `collectFailedOperations`, `failedSyncMessages`, `storeRecoveryMessage` | `OfflineQueueFacade` (Core/Sync) |
| 9 | Projects | 24-63, 2166-2366 | `createProject`, `updateProject`, `moveProject`, `archive*`, `deleteProject`, `descendantProjectIds`, `collapsedProjectIDs` | `ProjectStore` |
| 10 | Labels + "Current" label | 28, 356-400, 1751-1886 | `toggleLabel`, `createLabel`, `currentLabel`, `toggleCurrent`, `ensureCurrentLabel` | `LabelStore` + `CurrentTasks` |
| 11 | Subtasks and relations | 1629-1745 | `addSubtaskRelation`, `createSubtask`, `removeRelation`, `syncEmbeddedRelations` | `RelationActions` |
| 12 | Kanban | 2111-2165, 2585-2602 | `fetchBuckets`, `moveTask(toBucket:)`, `placeTask` | `BoardStore` |
| 13 | Reordering | 2523-2600 | `moveTask(toPosition:)`, `listViewId`, `reorderGeneration` | `TaskActions` |
| 14 | Calendar | 78-80, 2367-2470 | `calendarEvents`, `calendarAccessGranted`, `requestCalendarAccess`, `calendarEventsForDate/Month` | `CalendarStore` |
| 15 | Vikunja notifications | 2471-2522 | `fetchNotifications`, `markNotificationRead`, `unreadNotificationCount` | `InboxNotificationsStore` |
| 16 | Team / assignees / user | 126-135, 1244-1348 | `currentUser`, `assignableUsers`, `setAssignees` | `TeamStore` |
| 17 | Server version | 166-182, 1261-1300 | `serverVersion`, `showServerUpdateNotice`, `serverNeedsUpdate` | `SessionStore` |
| 18 | Siri / Intents | 1349-1470 | `defaultProject`, `createTaskFromIntent`, `queueIntentCreate`, `IntentTaskOutcome` | `IntentTaskCreator` (without AppState.shared) |
| 19 | Local reminders | ~770, ~2099 | `NotificationService` scheduling inside `refreshAll` and `applyQuietRefresh` (reads `UserDefaults.standard` directly) | `ReminderScheduler` |
| 20 | Completion undo | 89-105, 1115-1180 | `onTaskCompleted`, `canUndoLastCompletion`, `recordCompletionForUndo` | `TaskActions` |
| 21 | Widget export | 2671-2726 | `pushWidgetData`: rebuilds Today/Upcoming/Overdue by hand | `WidgetSnapshotPublisher`, reuse `Domain/Lists` |
| 22 | Persisted preferences | 35-62, 120, 360-380 | `collapsedProjectIDs`, `currentLabelId`, `sortPreferences` through `UserDefaults.standard` | `Preferences` |
| 23 | Errors | 2662-2670 | `handleError`, `activeError`, `errorMessage` | `ErrorReporter` |

`AppStateTests.swift` (1269 lines) and 21 other test files call `AppState` directly: any extraction must keep a delegating `AppState` facade until the end.

## 5. Coupling problems

1. **Derivatives computed in AppState, duplicated elsewhere.** `todayTasks` / `overdueTasks` / `upcomingTasks` (`AppState` 273-310) and `pushWidgetData` (2675-2726) express the same rules with slightly different filters (the "upcoming" widget uses `> endOfDay`, the app uses `> start + 7 days`). Risk of divergence.
2. **Presentation logic in the views.** `TaskListScreen.inboxSections` builds the sections (localised titles, colours, order); `MacTaskListView` and `MacSidebarView` redefine their own version. Focus Run depends on the section order through `Views/Focus/FocusRunOrder.swift`.
3. **Two parallel view trees**: iOS (`MainTabView`, `TaskListScreen`, `TaskDetailSheet`) and macOS (`MacContentView`, `MacTaskListView`, `MacTaskDetailView`) with the same logic duplicated. Mac selection is a `MacContentView.SidebarSection` enum referenced by `MacSidebarView`.
4. **Preferences through literal strings.** `"calmMode"` is read by `@AppStorage` in `TaskListScreen`, `TaskRow`, `SettingsScreen`, `MacTaskListView`, `MacSidebarView`; `"currentStallDays"` in `SettingsScreen` and `TaskRow`; `"notificationsEnabled"` / `"reminderOffset"` in `SettingsScreen` and `AppState`. 14 `*Preference` types in `App/` each have their key, but not the 4 above.
5. **Implicit singletons**: `APIClient.shared`, `AuthService.shared`, `NotificationService.shared`, `WidgetDataProvider.shared`, `AppState.shared` (weak). Tests go through `StorageScope` so they do not pollute the development app.
6. **Models that import SwiftUI**: `Models/Label.swift` (`VLabel.color: Color`), `Models/VNotification.swift`. This prevents putting `Models` in a module without UI and sharing them with the widgets.
7. **Pure domain kept in `Services/` and `App/`**: `SmartTaskParser`, `DescriptionMarkup`, `DescriptionChecklist`, `EstimateSuggester`, `EstimateMarker` (Services); `TaskSortOrder`, `AdvancedTaskFilter`, `QuickSchedule` (App). `SmartTaskParser.init` depends on `DefaultDueTimePreference` and on `Calendar.app` (defined in `App/`), so the parser cannot be isolated as it stands.
8. **`CacheService.swift` is not a service**: it holds the 5 `@Model`s. The `CachedTask.toVTask()` conversions live there too; access (`cacheTasks`, `loadCachedTasks`...) is in `SyncService`, which therefore mixes queue, cache and sync.
9. **Views that touch SwiftData**: `QuickAddBar` (`modelContext` for the estimate history), `FocusHistoryRow`, `FocusSyncSettingsSection`.
10. **Focus wiring by closures in `mDoneApp.onAppear`** (`onTaskCompleted`, `onTaskDeleted`, `taskLookup`), iOS only: the initialisation order depends on `onAppear`.
11. **Duplicated HTTP client for the widgets**: `WidgetDataProvider` reimplements the date decoder (Vikunja zero-date), pagination and auth, because the extensions do not compile `mDone/`. The `WidgetTask` / `WidgetData` models are distinct from `VTask`.
12. **`ServerSetupView` (484 lines)** carries the login orchestration logic (OIDC, TOTP, options) inside the view.
13. **Naming**: the iOS "Inbox" tab (`MainTabView.Tab.inbox`) and `SidebarSection.inbox` are a dated overview, not an inbox: semantic collision with the Things Inbox (tasks without a project or a date).

## 6. What blocks a complete replacement of the view layer

Blockers (to clear before writing the new UI):

| Blocker | Detail | Remedy |
|:-|:-|:-|
| No "ViewModel" surface | Views read 20-30 `AppState` members and rebuild the lists | Introduce pure projections (`ThingsList`) and thin ViewModels per feature |
| List rules that do not exist for Things | No notion of Things Inbox (without project/date), Anytime, Someday, Logbook, This Evening, Headings, Areas, When vs Deadline | New domain to write in `Domain/ThingsLists` with tests; Vikunja mapping to decide (see 03 and 05) |
| Mac navigation through a shared enum | `MacContentView.SidebarSection` referenced by `MacSidebarView`, `MacKeyboardShortcuts` | Common navigation router in `App/` |
| `AppState.shared` | The intents use it (`AddTaskIntent`, `QuickAddIntent`) | Keep one access point, but behind a protocol |
| Preferences not centralised | See §5.4 | Single `Preferences` with typed keys |
| Scattered design elements | `ColorExtension`, `PriorityBadge`, `LabelChip`, `ProjectColorDot`; no tokens (spacings, fonts, Things colours) | `DesignSystem/` |

Non-blockers (already clean, to reuse as they are): all the `*Service` actors, `APIClient`, `Endpoint`, `SyncService` (API), the parsers, `FocusManager`/`FocusRecord`, `WidgetDataProvider`, the intents, `ModelStoreBootstrap`.

## 7. Technical constraints observed in `project.yml` and the repository

- The app targets' `sources:` are **whole directories** (`mDone`, `mDoneShared`), so XcodeGen walks them recursively: moving or creating a `.swift` in those folders requires no change to `project.yml`.
- `mDoneTests/` is flat (74 files + `Helpers/`), the same set for iOS and macOS.
- Files pinned by path: `mDone/Info.plist`, `mDone/mDone.entitlements`, `mDone/mDone-macOS.entitlements`, `mDone/mDone-macOS-CI.entitlements` (referenced by `.github/workflows/macos-tests.yml`), `mDoneWidgets/Info.plist`, `mDoneMacWidgets/Info.plist`, `mDone/Localizable.xcstrings`.
- `SWIFT_VERSION: "5.9"` (Swift 5 language mode); no `SWIFT_STRICT_CONCURRENCY` setting found in `project.yml` or in the workflows.
- `.swiftlint.yml`: `included: mDone, mDoneTests`, `excluded: mDone/Resources`; `.swiftformat` also excludes `mDone/Resources`. `SwiftLint` runs as a non-blocking post-build script if it is absent.
- CI: `ios-tests.yml` (iPhone 17, `-only-testing:mDoneTests`) and `macos-tests.yml` (`-only-testing:mDoneMacTests`, ad hoc signing). `mDoneWidgetRenderTests` and `mDoneUITests` are compiled by the iOS scheme (`testTargets`).
