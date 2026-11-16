# 01 - Inventaire des fonctionnalités

Périmètre : `mDone/` (iOS + macOS, mêmes sources), `mDoneShared/`, `mDoneWidgets/` (iOS et macOS via `mDoneMacWidgets`), tests. Base : ~43 275 lignes Swift dont 23 828 hors tests. Module Swift : `mDone`. Les chemins sont relatifs à la racine du dépôt.

Légende plateforme : **Commun** = compilé iOS + macOS. **iOS** = `#if os(iOS)` ou fichier entièrement gardé. **macOS** = vue sous `Views/Mac/`.

## 1. Authentification et serveur

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Saisie de l'URL serveur, normalisation | `Services/ServerURL.swift` (`ServerURL`), `Views/Setup/ServerSetupView.swift` | Commun |
| Login identifiant + mot de passe, TOTP | `AppState.loginWithCredentials`, `Models/APIModels.swift` (`LoginRequest`, `LoginResponse`), `Services/AuthService.swift` (actor) | Commun |
| Login par token API | `AppState.login(serverURL:token:)` | Commun |
| Login OIDC (callback v1 seule requête hors v2) | `Services/OIDCLogin.swift` (`OIDCLogin`, `OIDCCallbackResult`, `OIDCLoginError`), `Services/WebAuthenticator.swift` (`WebAuthenticating`), `Models/AuthOptions.swift`, `Models/ServerInfo.swift` (`OIDCProvider`), `AppState.loginWithOIDC` | Commun (`WebAuthenticator` a 2 `#if`) |
| Stockage token Keychain + URL | `AuthService`, `Services/JWTHelpers.swift`, `mDoneShared/SharedTokenStore.swift` | Commun (`SharedTokenStore` 5 `#if`, repli keychain locale sur macOS CI) |
| Refresh JWT, session expirée | `Services/APIClient.swift` (`setOnTokensUpdated`, `setOnSessionExpired`), `AppState.registerAPIClientHandlers`, `expireSession` | Commun |
| Détection version serveur, refus < 2.5.0, alerte de mise à jour | `Models/VikunjaVersion.swift` (`minimumSupported` = 2.5.0, `ServerUpdateNotice`), `Services/ServerInfoService.swift`, `AppState.loadServerVersionIfNeeded`, alerte dans `MainTabView` | Commun |
| Auto-login de test (DEBUG) | `mDoneApp.swift` (clés `MDONE_SERVER_URL`, `MDONE_TOKEN`) | Commun |
| Isolation dev/release (bundle, app group, keychain) | `project.yml` (`MDONE_BUNDLE_ID`...), `mDoneShared/SharedConstants.swift` (`StorageScope`) | Commun |

## 2. Tâches (cœur)

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Modèle tâche (dates, priorité, repeat, rappels, assignés, labels, relations, bucket, position) | `Models/VTask.swift` (`VTask`, `TaskReminder`, `PriorityLevel`, `TaskCreateRequest`, `TaskUpdateRequest`) | Commun |
| CRUD tâche, PATCH merge-patch uniquement les champs changés | `Services/TaskService.swift` (actor), `TaskUpdateRequest.onlyChanges(from:)`, `AppState.updateTask/createTask/deleteTask` | Commun |
| Cocher / décocher, annuler la dernière complétion (undo) | `AppState.toggleTaskDone`, `undoLastCompletion`, `recordCompletionForUndo`; shake: `Views/Components/ShakeDetector.swift`; prompt dans `MainTabView` | Commun (shake/prompt iOS) |
| Création rapide | `Views/Tasks/QuickAddBar.swift`, `AppState.createTask`, `quickAddTrigger` | Commun |
| Reporter (+24h, absolu) | `AppState.postponeTask`, `rescheduleTask`, `App/QuickSchedule.swift` (`QuickSchedule`) | Commun |
| Priorités (1-5) | `PriorityLevel`, `Views/Components/PriorityBadge.swift`, `ColorExtension.swift` (`priorityRed`...) | Commun |
| Durée estimée (marqueur HTML dans la description) | `Services/EstimateMarker.swift` (commentaire HTML `mdone:estimate=N`), `Views/Components/EstimatePicker.swift`, `VTask.estimatedSeconds`, `docs/agent-contract-estimated-duration.md` | Commun |
| Suggestion de durée depuis l'historique focus | `Services/EstimateSuggester.swift` (pur, sans DB), `QuickAddBar.scheduleSuggestion` | Commun (historique alimenté côté iOS) |
| Progression (percent done) | `AppState.setProgress`, `TaskRow` | Commun |
| Répétition (repeat_after / repeat_mode), projection d'occurrences | `Models/TaskRecurrence.swift`, `Models/TaskOccurrence.swift`, `VTask.occurs(on:)`, `occurrenceDays`, `AppState.occurrences(on:)`, `projectedOccurrences` | Commun |
| Rappels absolus et relatifs, notifications locales | `VTask.TaskReminder.fireDate(for:)`, `Views/Components/ReminderEditor.swift`, `Services/NotificationService.swift`, réglages `notificationsEnabled`, `reminderOffset`, planification dans `AppState.refreshAll` (~l.770) et `refreshVisibleList` | Commun |
| Sous-tâches et relations (parenttask, duplicateof...) | `Models/TaskRelation.swift` (`RelationKind`, `TaskNesting`, `SubtaskLinkCandidates`, `TaskListRow`), `Views/Tasks/TaskRelationsSections.swift`, `AppState.addSubtaskRelation/createSubtask/removeRelation` | Commun |
| Assignés (Team features) | `Views/Tasks/TaskAssigneesSection.swift`, `Services/UserService.swift`, `Models/User.swift`, `AppState.loadAssignableUsers/setAssignees`, `App/TeamFeaturesPreference.swift` | Commun |
| Description riche (HTML Tiptap <-> markdown léger), checklists | `Services/DescriptionMarkup.swift` (823 l.), `Services/DescriptionChecklist.swift`, `Views/Tasks/DescriptionChecklistView.swift`, `RichTextRendering.swift`, `DescriptionEditHint.swift` | Commun |
| Lien web / partage de tâche | `Services/TaskLink.swift`, `Views/Components/TaskShareButtons.swift` | Commun (2 `#if`) |
| Favori | `VTask.isFavorite`, `CachedTask.isFavorite` | Commun (pas de liste dédiée repérée) |
| Dates début / fin (plage) | `VTask.startDate/endDate`, `effectiveStartDate`, `Views/Components/TaskDateRangeMetadata.swift`, `TaskScheduleEditor.swift` | Commun |

## 3. Parsing en langage naturel (Smart quick add)

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Parser pur : `+projet`/`#projet`, `!1`-`!5`, `*label`, dates naturelles (mots-clés, formes absolues, `NSDataDetector` en repli), heures, chinois | `Services/SmartTaskParser.swift` (`SmartTaskParser`, `SmartTaskParse`, `SmartTaskParse.Field/Match`) | Commun |
| Chips d'acceptation / rejet, `rejecting(_:)` | `Views/Tasks/QuickAddBar.swift` (`ParseChip`, `rejectedFields`) | Commun |
| Heure par défaut, jour par défaut | `App/DefaultDueTimePreference.swift`, `App/NewTaskDueDatePreference.swift`, `App/SmartParsingPreference.swift` (`QuickAddSubmission`) | Commun |
| Tests | `SmartTaskParserTests` (460 l.), `SmartQuickAddTests` (437 l.), `QuickAddIntentTests` | Commun |

## 4. Listes, tri, filtres, vues

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Écran "Inbox" = vue d'ensemble par dates (Current, Overdue, Today, Tomorrow, This Week, Upcoming, No Date). Attention : ce n'est PAS l'Inbox de Things | `Views/Tasks/TaskListScreen.swift` (`InboxSection`, `inboxSections`), `AppState.overdueTasks/todayTasks/tomorrowTasks/thisWeekTasks/upcomingTasks/noDateTasks`, `Views/Tasks/SmartListSection.swift` | iOS (liste), Mac : `Views/Mac/MacTaskListView.swift` |
| Overdue | `VTask.isOverdue`, `AppState.overdueTasks`, mode Calm | Commun |
| Mode Calm (overdue fusionné dans Today) | `@AppStorage("calmMode")` lu dans 5 fichiers de vues, `AppState.calmModeTodayTasks` | Commun |
| Tâches "Current" (label spécial "Current", stagnation) | `AppState.currentLabel/currentTasks/toggleCurrent/ensureCurrentLabel`, clé `currentLabelId`, `currentStallDays` | Commun |
| Tri par liste, persistance | `App/TaskSortOrder.swift` (`TaskSortOrder`, `TaskSortScope`, `TaskSortPreference`), `Views/Components/TaskSortMenu.swift` | Commun |
| Réordonnancement manuel (drag, position flottante) | `Models/TaskPositioning.swift`, `AppState.moveTask(_:toPosition:)`, `listViewId(for:)`, `reorderGeneration` | Commun |
| Recherche locale | `AppState.searchQuery`, `task(_:matchesSearch:)` | Commun |
| Filtre chips + filtre avancé (local) | `AppState.activeFilter` (`TaskFilter`), `App/AdvancedTaskFilter.swift`, `Views/Components/FilterBar.swift`, `TaskFilterSheet.swift` | Commun |
| Densité des lignes | `App/TaskListDensity.swift`, `TaskRow` | Commun |
| Rafraîchissement live d'une liste visible | `Services/LiveListRefresh.swift` (`@MainActor`), `AppState.refreshVisibleList` | Commun |
| Détail inline iPad | `Views/Tasks/InlineTaskDetail.swift` (`InlineTaskSelection`) | iOS (size class) |
| Ligne de tâche (swipe, menu contextuel, progression) | `Views/Tasks/TaskRow.swift` (510 l.) | Commun |
| Fiche de détail / édition | `Views/Tasks/TaskDetailSheet.swift` (445 l.), `Views/Mac/MacTaskDetailView.swift` (340 l., doublon) | Commun / macOS |

## 5. Projets, labels, board

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Projets hiérarchiques, repli persisté, archivage, déplacement | `Models/Project.swift`, `Models/ProjectHierarchy.swift` (`ProjectNode`, `ProjectTreeRow`), `Services/ProjectService.swift`, `AppState.createProject/updateProject/moveProject/archiveProject/unarchiveProject/deleteProject/fetchArchivedProjects`, `collapsedProjectIDs`, `Views/Projects/*`, `Views/Mac/MacArchivedProjectsView.swift` | Commun |
| Vues projet (list / kanban), préférence | `App/ProjectViewPreference.swift` (`ProjectViewMode`), `Views/Projects/ProjectBoardView.swift` | Commun (5 `#if`) |
| Kanban : buckets, déplacement entre buckets, position dans bucket | `Models/Bucket.swift`, `ProjectService.fetchBuckets`, `AppState.fetchBuckets/moveTask(toBucket:)/placeTask(inBucket:)` | Commun |
| Projet par défaut | `App/DefaultProjectPreference.swift`, `AppState.defaultProject` | Commun |
| Labels CRUD, assignation, couleur | `Models/Label.swift` (`VLabel`), `Services/LabelService.swift`, `AppState.toggleLabel/createLabel/hasLabel`, `Views/Components/LabelChip.swift`, `ColorSwatchPicker.swift`, `Views/Tasks/TaskLabelsSection.swift`, `Models/HexColor.swift` | Commun |

## 6. Calendrier

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Grille mensuelle + liste du jour | `Views/Calendar/CalendarScreen.swift`, `CalendarGrid.swift`, `DayTaskList.swift`, `CalendarEventRow.swift` | Commun |
| Occurrences par jour dont projections de répétitions | `AppState.occurrences(on:)`, `occurrencesByDay(in:)` | Commun |
| Overlay EventKit, choix des calendriers, événements journée entière | `Services/CalendarService.swift` (actor), `App/CalendarSelection.swift` (`CalendarInfo`, `HiddenCalendarStore`), `App/CalendarPreferences.swift` (`WeekStartPreference`, `AllDayEventPreference`), `Models/CalendarEvent.swift`, `Views/Settings/CalendarSelectionView.swift`, `AppState.requestCalendarAccess/refreshCalendarEvents/todayCalendarEvents` | Commun |
| Début de semaine (étend `Calendar.app`) | `CalendarPreferences.swift` l.31 | Commun |

## 7. Focus, Live Activity

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Session focus (start/pause/stop), lien tâche | `Services/FocusManager.swift` (589 l., `@MainActor @Observable`), `mDoneShared/FocusSession.swift` | **iOS seulement** (fichier entier sous `#if os(iOS)`) |
| Focus Run (file de tâches enchaînées) | `Models/FocusRun.swift` (`FocusRun`, `FocusRunSummary`), `Views/Focus/FocusRunOrder.swift` | Commun (modèle) / iOS (usage) |
| Live Activity / Dynamic Island | `mDoneShared/FocusTaskAttributes.swift`, `mDoneWidgets/FocusTaskLiveActivity.swift`, `NSSupportsLiveActivities` dans `mDone/Info.plist` | iOS |
| UI focus | `Views/Focus/FocusSessionView.swift`, `FocusBanner.swift`, `Views/Components/FocusHistoryRow.swift` | iOS |
| Historique focus (SwiftData `FocusRecord`) | `Services/CacheService.swift` (`FocusRecord`), `Services/FocusHistoryQuery.swift`, `FocusDurationFormatter.swift` | Commun |
| Livraison vers un service externe (outbox) | `Services/FocusOutboxService.swift`, `Services/FocusSyncConfig.swift` (URL UserDefaults, token Keychain séparé), `Views/Settings/FocusSyncSettingsSection.swift` | iOS (outbox), réglage commun |

## 8. Offline et synchronisation

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Cache SwiftData | `Services/CacheService.swift` : `CachedTask`, `CachedProject`, `CachedLabel`, `FocusRecord`, `PendingOperation` (5 `@Model`) | Commun |
| Création du conteneur, récupération si store corrompu | `App/ModelStoreBootstrap.swift` (`ModelStoreBootstrap`, `StoreRecovery`), `App/AppDependencies.swift` | Commun |
| File d'opérations en attente, édition hors ligne par intention, rejeu | `Services/SyncService.swift` (actor, 472 l.), `Models/QueuedTaskEdit.swift`, `AppState.queueOfflineEdit/refreshPendingState/collectFailedOperations` | Commun |
| Détection réseau | `Services/NetworkMonitor.swift` (`NWPathMonitor`, `@Observable`) | Commun |
| Bannière d'erreur, retry, état "données en cache" | `Views/Components/ErrorBanner.swift`, `AppState.isShowingCachedData`, `isRetrying`, `failedSyncMessages` | Commun |
| Création de tâche hors ligne **uniquement via Siri** (l'UI ne met pas en file les créations, #146) | `AppState.createTaskFromIntent/queueIntentCreate` | Commun |

## 9. Widgets, intents, URL scheme

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Widgets Today / Upcoming (configurables) | `mDoneWidgets/TodayTasksWidget.swift` (447 l.), `UpcomingWidget.swift`, `AppIntents.swift` (`TodayWidgetSettingsIntent`, `CompleteTaskIntent`) | iOS + macOS |
| Widget Quick Add | `mDoneWidgets/QuickAddWidget.swift` | iOS + macOS |
| Widgets écran verrouillé | `mDoneWidgets/LockScreenWidgets.swift` | iOS (compilés hors macOS) |
| Données widget | `mDoneShared/WidgetDataProvider.swift` (client HTTP autonome, `@unchecked Sendable`), `WidgetModels.swift`, `AppState.pushWidgetData` (app group UserDefaults) | Commun |
| Rendu PNG des widgets (marketing) | `mDoneWidgetRenderTests/WidgetShotRenderTests.swift` | iOS |
| Siri / Raccourcis : ajouter une tâche en arrière-plan | `App/AddTaskIntent.swift` (`AddTaskIntent`, `ProjectEntity`, `ProjectEntityQuery`, `IntentTaskOutcome`) | Commun |
| Intent "Quick Add" (ouvre l'app) + `AppShortcutsProvider` | `App/AppIntents.swift` (`QuickAddIntent`, `MDoneAppShortcuts`) | Commun |
| URL scheme `mdone://focus`, `mdone://create` | `mDoneApp.swift` (`onOpenURL`) | iOS (focus+create), macOS (create) |

## 10. Notifications Vikunja, réglages, divers

| Fonctionnalité | Fichiers / types | Plateforme |
|:-|:-|:-|
| Liste des notifications serveur, lu / tout lu, badge | `Models/VNotification.swift`, `Services/NotificationService.swift`, `Views/Notifications/NotificationListView.swift`, `AppState.fetchNotifications/markNotificationRead/markAllNotificationsRead` | Commun |
| Réglages (serveur, semaine, densité, vue par défaut, projet par défaut, due time, Siri, smart parsing, team, calm, événements, notifications, données, focus sync) | `Views/Settings/SettingsScreen.swift` (14 `@AppStorage`), `AboutScreen.swift` | Commun |
| Raccourcis clavier Mac, fenêtre unique | `Views/Mac/MacKeyboardShortcuts.swift`, `mDoneApp.swift` (`handlesExternalEvents`) | macOS |
| Sidebar Mac (listes intelligentes, projets, archivés, notifications, calendrier, réglages) | `Views/Mac/MacSidebarView.swift`, `MacContentView.swift` (`SidebarSection`) | macOS |
| Navigation iOS : 4 onglets Inbox / Projects / Calendar / Settings, `.sidebarAdaptable` | `Views/MainTabView.swift` | iOS |
| Localisation (xcstrings) | `mDone/Localizable.xcstrings`, `InfoPlist.xcstrings`, `mDoneWidgets/Localizable.xcstrings`, `docs/localization.md` | Commun |

## 11. Couverture de tests

74 fichiers dans `mDoneTests/` (compilés pour iOS **et** macOS), 22 référencent `AppState`. Cibles : `mDoneTests`, `mDoneMacTests`, `mDoneUITests` (`ScreenshotTests`), `mDoneMacUITests`, `mDoneIntegrationTests` (serveur réel, nightly), `mDoneWidgetRenderTests`. Gros fichiers : `AppStateTests` 1269 l., `APIClientTests` 900 l., `TaskServiceTests` 854 l., `APIClientRefreshTests` 793 l., `OfflineEditQueueTests` 578 l.

## 12. Écarts avec le contexte de la demande

- Le dossier `docs/things-spec/` existe mais est **vide** : aucune spécification Things n'est disponible dans le dépôt.
- `docs/` contient en plus : `vikunja-api-inventory.md`, `oidc-callback-decision.md`, `dev-setup.md`, `localization.md`, `appstore-metadata.md`.
- Pas de Swift ni Python sur l'hôte : rien n'a pu être compilé, l'inventaire vient de la lecture de code et de `grep`.
