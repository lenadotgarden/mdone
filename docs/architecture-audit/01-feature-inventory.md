# 01 - Feature inventory

Scope: `mDone/` (iOS + macOS, same sources), `mDoneShared/`, `mDoneWidgets/` (iOS and macOS through `mDoneMacWidgets`), tests. Baseline: ~43,275 lines of Swift, 23,828 of them outside tests. Swift module: `mDone`. Paths are relative to the repository root.

Platform legend: **Shared** = compiled for iOS + macOS. **iOS** = `#if os(iOS)` or a fully guarded file. **macOS** = view under `Views/Mac/`.

## 1. Authentication and server

| Feature | Files / types | Platform |
|:-|:-|:-|
| Server URL entry, normalisation | `Services/ServerURL.swift` (`ServerURL`), `Views/Setup/ServerSetupView.swift` | Shared |
| Login with username + password, TOTP | `AppState.loginWithCredentials`, `Models/APIModels.swift` (`LoginRequest`, `LoginResponse`), `Services/AuthService.swift` (actor) | Shared |
| Login with an API token | `AppState.login(serverURL:token:)` | Shared |
| OIDC login (v1 callback, one request only outside v2) | `Services/OIDCLogin.swift` (`OIDCLogin`, `OIDCCallbackResult`, `OIDCLoginError`), `Services/WebAuthenticator.swift` (`WebAuthenticating`), `Models/AuthOptions.swift`, `Models/ServerInfo.swift` (`OIDCProvider`), `AppState.loginWithOIDC` | Shared (`WebAuthenticator` has 2 `#if`) |
| Keychain token + URL storage | `AuthService`, `Services/JWTHelpers.swift`, `mDoneShared/SharedTokenStore.swift` | Shared (`SharedTokenStore` 5 `#if`, local keychain fallback on the macOS CI) |
| JWT refresh, expired session | `Services/APIClient.swift` (`setOnTokensUpdated`, `setOnSessionExpired`), `AppState.registerAPIClientHandlers`, `expireSession` | Shared |
| Server version detection, refusal below 2.5.0, update alert | `Models/VikunjaVersion.swift` (`minimumSupported` = 2.5.0, `ServerUpdateNotice`), `Services/ServerInfoService.swift`, `AppState.loadServerVersionIfNeeded`, alert in `MainTabView` | Shared |
| Test auto-login (DEBUG) | `mDoneApp.swift` (keys `MDONE_SERVER_URL`, `MDONE_TOKEN`) | Shared |
| Development/release isolation (bundle, app group, keychain) | `project.yml` (`MDONE_BUNDLE_ID`...), `mDoneShared/SharedConstants.swift` (`StorageScope`) | Shared |

## 2. Tasks (core)

| Feature | Files / types | Platform |
|:-|:-|:-|
| Task model (dates, priority, repeat, reminders, assignees, labels, relations, bucket, position) | `Models/VTask.swift` (`VTask`, `TaskReminder`, `PriorityLevel`, `TaskCreateRequest`, `TaskUpdateRequest`) | Shared |
| Task CRUD, PATCH merge-patch of the changed fields only | `Services/TaskService.swift` (actor), `TaskUpdateRequest.onlyChanges(from:)`, `AppState.updateTask/createTask/deleteTask` | Shared |
| Check / uncheck, undo the last completion | `AppState.toggleTaskDone`, `undoLastCompletion`, `recordCompletionForUndo`; shake: `Views/Components/ShakeDetector.swift`; prompt in `MainTabView` | Shared (shake/prompt iOS) |
| Quick creation | `Views/Tasks/QuickAddBar.swift`, `AppState.createTask`, `quickAddTrigger` | Shared |
| Postpone (+24h, absolute) | `AppState.postponeTask`, `rescheduleTask`, `App/QuickSchedule.swift` (`QuickSchedule`) | Shared |
| Priorities (1-5) | `PriorityLevel`, `Views/Components/PriorityBadge.swift`, `ColorExtension.swift` (`priorityRed`...) | Shared |
| Estimated duration (HTML marker in the description) | `Services/EstimateMarker.swift` (HTML comment `mdone:estimate=N`), `Views/Components/EstimatePicker.swift`, `VTask.estimatedSeconds`, `docs/agent-contract-estimated-duration.md` | Shared |
| Duration suggestion from the focus history | `Services/EstimateSuggester.swift` (pure, no DB), `QuickAddBar.scheduleSuggestion` | Shared (history fed on the iOS side) |
| Progress (percent done) | `AppState.setProgress`, `TaskRow` | Shared |
| Repetition (repeat_after / repeat_mode), occurrence projection | `Models/TaskRecurrence.swift`, `Models/TaskOccurrence.swift`, `VTask.occurs(on:)`, `occurrenceDays`, `AppState.occurrences(on:)`, `projectedOccurrences` | Shared |
| Absolute and relative reminders, local notifications | `VTask.TaskReminder.fireDate(for:)`, `Views/Components/ReminderEditor.swift`, `Services/NotificationService.swift`, settings `notificationsEnabled`, `reminderOffset`, scheduling in `AppState.refreshAll` (~l.770) and `refreshVisibleList` | Shared |
| Subtasks and relations (parenttask, duplicateof...) | `Models/TaskRelation.swift` (`RelationKind`, `TaskNesting`, `SubtaskLinkCandidates`, `TaskListRow`), `Views/Tasks/TaskRelationsSections.swift`, `AppState.addSubtaskRelation/createSubtask/removeRelation` | Shared |
| Assignees (Team features) | `Views/Tasks/TaskAssigneesSection.swift`, `Services/UserService.swift`, `Models/User.swift`, `AppState.loadAssignableUsers/setAssignees`, `App/TeamFeaturesPreference.swift` | Shared |
| Rich description (Tiptap HTML <-> light markdown), checklists | `Services/DescriptionMarkup.swift` (823 lines), `Services/DescriptionChecklist.swift`, `Views/Tasks/DescriptionChecklistView.swift`, `RichTextRendering.swift`, `DescriptionEditHint.swift` | Shared |
| Web link / task sharing | `Services/TaskLink.swift`, `Views/Components/TaskShareButtons.swift` | Shared (2 `#if`) |
| Favourite | `VTask.isFavorite`, `CachedTask.isFavorite` | Shared (no dedicated list found) |
| Start / end dates (range) | `VTask.startDate/endDate`, `effectiveStartDate`, `Views/Components/TaskDateRangeMetadata.swift`, `TaskScheduleEditor.swift` | Shared |

## 3. Natural language parsing (smart quick add)

| Feature | Files / types | Platform |
|:-|:-|:-|
| Pure parser: `+project`/`#project`, `!1` to `!5`, `*label`, natural dates (keywords, absolute forms, `NSDataDetector` as a fallback), times, Chinese | `Services/SmartTaskParser.swift` (`SmartTaskParser`, `SmartTaskParse`, `SmartTaskParse.Field/Match`) | Shared |
| Accept / reject chips, `rejecting(_:)` | `Views/Tasks/QuickAddBar.swift` (`ParseChip`, `rejectedFields`) | Shared |
| Default time, default day | `App/DefaultDueTimePreference.swift`, `App/NewTaskDueDatePreference.swift`, `App/SmartParsingPreference.swift` (`QuickAddSubmission`) | Shared |
| Tests | `SmartTaskParserTests` (460 lines), `SmartQuickAddTests` (437 lines), `QuickAddIntentTests` | Shared |

## 4. Lists, sorting, filters, views

| Feature | Files / types | Platform |
|:-|:-|:-|
| "Inbox" screen = overview by dates (Current, Overdue, Today, Tomorrow, This Week, Upcoming, No Date). Note: this is NOT the Things Inbox | `Views/Tasks/TaskListScreen.swift` (`InboxSection`, `inboxSections`), `AppState.overdueTasks/todayTasks/tomorrowTasks/thisWeekTasks/upcomingTasks/noDateTasks`, `Views/Tasks/SmartListSection.swift` | iOS (list), Mac: `Views/Mac/MacTaskListView.swift` |
| Overdue | `VTask.isOverdue`, `AppState.overdueTasks`, Calm mode | Shared |
| Calm mode (overdue merged into Today) | `@AppStorage("calmMode")` read in 5 view files, `AppState.calmModeTodayTasks` | Shared |
| "Current" tasks (special "Current" label, stagnation) | `AppState.currentLabel/currentTasks/toggleCurrent/ensureCurrentLabel`, key `currentLabelId`, `currentStallDays` | Shared |
| Sort per list, persistence | `App/TaskSortOrder.swift` (`TaskSortOrder`, `TaskSortScope`, `TaskSortPreference`), `Views/Components/TaskSortMenu.swift` | Shared |
| Manual reordering (drag, floating position) | `Models/TaskPositioning.swift`, `AppState.moveTask(_:toPosition:)`, `listViewId(for:)`, `reorderGeneration` | Shared |
| Local search | `AppState.searchQuery`, `task(_:matchesSearch:)` | Shared |
| Chip filter + advanced filter (local) | `AppState.activeFilter` (`TaskFilter`), `App/AdvancedTaskFilter.swift`, `Views/Components/FilterBar.swift`, `TaskFilterSheet.swift` | Shared |
| Row density | `App/TaskListDensity.swift`, `TaskRow` | Shared |
| Live refresh of a visible list | `Services/LiveListRefresh.swift` (`@MainActor`), `AppState.refreshVisibleList` | Shared |
| Inline detail on iPad | `Views/Tasks/InlineTaskDetail.swift` (`InlineTaskSelection`) | iOS (size class) |
| Task row (swipe, context menu, progress) | `Views/Tasks/TaskRow.swift` (510 lines) | Shared |
| Detail / edit sheet | `Views/Tasks/TaskDetailSheet.swift` (445 lines), `Views/Mac/MacTaskDetailView.swift` (340 lines, duplicate) | Shared / macOS |

## 5. Projects, labels, board

| Feature | Files / types | Platform |
|:-|:-|:-|
| Hierarchical projects, persisted collapse, archiving, moving | `Models/Project.swift`, `Models/ProjectHierarchy.swift` (`ProjectNode`, `ProjectTreeRow`), `Services/ProjectService.swift`, `AppState.createProject/updateProject/moveProject/archiveProject/unarchiveProject/deleteProject/fetchArchivedProjects`, `collapsedProjectIDs`, `Views/Projects/*`, `Views/Mac/MacArchivedProjectsView.swift` | Shared |
| Project views (list / kanban), preference | `App/ProjectViewPreference.swift` (`ProjectViewMode`), `Views/Projects/ProjectBoardView.swift` | Shared (5 `#if`) |
| Kanban: buckets, moving between buckets, position within a bucket | `Models/Bucket.swift`, `ProjectService.fetchBuckets`, `AppState.fetchBuckets/moveTask(toBucket:)/placeTask(inBucket:)` | Shared |
| Default project | `App/DefaultProjectPreference.swift`, `AppState.defaultProject` | Shared |
| Label CRUD, assignment, colour | `Models/Label.swift` (`VLabel`), `Services/LabelService.swift`, `AppState.toggleLabel/createLabel/hasLabel`, `Views/Components/LabelChip.swift`, `ColorSwatchPicker.swift`, `Views/Tasks/TaskLabelsSection.swift`, `Models/HexColor.swift` | Shared |

## 6. Calendar

| Feature | Files / types | Platform |
|:-|:-|:-|
| Monthly grid + day list | `Views/Calendar/CalendarScreen.swift`, `CalendarGrid.swift`, `DayTaskList.swift`, `CalendarEventRow.swift` | Shared |
| Occurrences per day, including repeat projections | `AppState.occurrences(on:)`, `occurrencesByDay(in:)` | Shared |
| EventKit overlay, calendar selection, all-day events | `Services/CalendarService.swift` (actor), `App/CalendarSelection.swift` (`CalendarInfo`, `HiddenCalendarStore`), `App/CalendarPreferences.swift` (`WeekStartPreference`, `AllDayEventPreference`), `Models/CalendarEvent.swift`, `Views/Settings/CalendarSelectionView.swift`, `AppState.requestCalendarAccess/refreshCalendarEvents/todayCalendarEvents` | Shared |
| Week start (extends `Calendar.app`) | `CalendarPreferences.swift` l.31 | Shared |

## 7. Focus, Live Activity

| Feature | Files / types | Platform |
|:-|:-|:-|
| Focus session (start/pause/stop), task link | `Services/FocusManager.swift` (589 lines, `@MainActor @Observable`), `mDoneShared/FocusSession.swift` | **iOS only** (whole file under `#if os(iOS)`) |
| Focus Run (queue of chained tasks) | `Models/FocusRun.swift` (`FocusRun`, `FocusRunSummary`), `Views/Focus/FocusRunOrder.swift` | Shared (model) / iOS (use) |
| Live Activity / Dynamic Island | `mDoneShared/FocusTaskAttributes.swift`, `mDoneWidgets/FocusTaskLiveActivity.swift`, `NSSupportsLiveActivities` in `mDone/Info.plist` | iOS |
| Focus UI | `Views/Focus/FocusSessionView.swift`, `FocusBanner.swift`, `Views/Components/FocusHistoryRow.swift` | iOS |
| Focus history (SwiftData `FocusRecord`) | `Services/CacheService.swift` (`FocusRecord`), `Services/FocusHistoryQuery.swift`, `FocusDurationFormatter.swift` | Shared |
| Delivery to an external service (outbox) | `Services/FocusOutboxService.swift`, `Services/FocusSyncConfig.swift` (URL in UserDefaults, separate Keychain token), `Views/Settings/FocusSyncSettingsSection.swift` | iOS (outbox), shared setting |

## 8. Offline and synchronisation

| Feature | Files / types | Platform |
|:-|:-|:-|
| SwiftData cache | `Services/CacheService.swift`: `CachedTask`, `CachedProject`, `CachedLabel`, `FocusRecord`, `PendingOperation` (5 `@Model`) | Shared |
| Container creation, recovery when the store is corrupted | `App/ModelStoreBootstrap.swift` (`ModelStoreBootstrap`, `StoreRecovery`), `App/AppDependencies.swift` | Shared |
| Pending operation queue, offline edit by intention, replay | `Services/SyncService.swift` (actor, 472 lines), `Models/QueuedTaskEdit.swift`, `AppState.queueOfflineEdit/refreshPendingState/collectFailedOperations` | Shared |
| Network detection | `Services/NetworkMonitor.swift` (`NWPathMonitor`, `@Observable`) | Shared |
| Error banner, retry, "cached data" state | `Views/Components/ErrorBanner.swift`, `AppState.isShowingCachedData`, `isRetrying`, `failedSyncMessages` | Shared |
| Creating a task offline **only through Siri** (the UI does not queue creations, #146) | `AppState.createTaskFromIntent/queueIntentCreate` | Shared |

## 9. Widgets, intents, URL scheme

| Feature | Files / types | Platform |
|:-|:-|:-|
| Today / Upcoming widgets (configurable) | `mDoneWidgets/TodayTasksWidget.swift` (447 lines), `UpcomingWidget.swift`, `AppIntents.swift` (`TodayWidgetSettingsIntent`, `CompleteTaskIntent`) | iOS + macOS |
| Quick Add widget | `mDoneWidgets/QuickAddWidget.swift` | iOS + macOS |
| Lock screen widgets | `mDoneWidgets/LockScreenWidgets.swift` | iOS (compiled out of macOS) |
| Widget data | `mDoneShared/WidgetDataProvider.swift` (standalone HTTP client, `@unchecked Sendable`), `WidgetModels.swift`, `AppState.pushWidgetData` (app group UserDefaults) | Shared |
| PNG rendering of the widgets (marketing) | `mDoneWidgetRenderTests/WidgetShotRenderTests.swift` | iOS |
| Siri / Shortcuts: add a task in the background | `App/AddTaskIntent.swift` (`AddTaskIntent`, `ProjectEntity`, `ProjectEntityQuery`, `IntentTaskOutcome`) | Shared |
| "Quick Add" intent (opens the app) + `AppShortcutsProvider` | `App/AppIntents.swift` (`QuickAddIntent`, `MDoneAppShortcuts`) | Shared |
| URL scheme `mdone://focus`, `mdone://create` | `mDoneApp.swift` (`onOpenURL`) | iOS (focus+create), macOS (create) |

## 10. Vikunja notifications, settings, misc

| Feature | Files / types | Platform |
|:-|:-|:-|
| Server notification list, read / read all, badge | `Models/VNotification.swift`, `Services/NotificationService.swift`, `Views/Notifications/NotificationListView.swift`, `AppState.fetchNotifications/markNotificationRead/markAllNotificationsRead` | Shared |
| Settings (server, week, density, default view, default project, due time, Siri, smart parsing, team, calm, events, notifications, data, focus sync) | `Views/Settings/SettingsScreen.swift` (14 `@AppStorage`), `AboutScreen.swift` | Shared |
| Mac keyboard shortcuts, single window | `Views/Mac/MacKeyboardShortcuts.swift`, `mDoneApp.swift` (`handlesExternalEvents`) | macOS |
| Mac sidebar (smart lists, projects, archived, notifications, calendar, settings) | `Views/Mac/MacSidebarView.swift`, `MacContentView.swift` (`SidebarSection`) | macOS |
| iOS navigation: 4 tabs Inbox / Projects / Calendar / Settings, `.sidebarAdaptable` | `Views/MainTabView.swift` | iOS |
| Localisation (xcstrings) | `mDone/Localizable.xcstrings`, `InfoPlist.xcstrings`, `mDoneWidgets/Localizable.xcstrings`, `docs/localization.md` | Shared |

## 11. Test coverage

74 files in `mDoneTests/` (compiled for iOS **and** macOS), 22 of them reference `AppState`. Targets: `mDoneTests`, `mDoneMacTests`, `mDoneUITests` (`ScreenshotTests`), `mDoneMacUITests`, `mDoneIntegrationTests` (real server, nightly), `mDoneWidgetRenderTests`. Largest files: `AppStateTests` 1269 lines, `APIClientTests` 900 lines, `TaskServiceTests` 854 lines, `APIClientRefreshTests` 793 lines, `OfflineEditQueueTests` 578 lines.

## 12. Gaps against the request context

- The `docs/things-spec/` folder exists but is **empty**: no Things specification is available in the repository.
- `docs/` also contains: `vikunja-api-inventory.md`, `oidc-callback-decision.md`, `dev-setup.md`, `localization.md`, `appstore-metadata.md`.
- No Swift and no Python on the host: nothing could be compiled, the inventory comes from reading the code and from `grep`.
