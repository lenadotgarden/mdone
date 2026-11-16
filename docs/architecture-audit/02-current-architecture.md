# 02 - Architecture actuelle

## 1. Couches réelles

```
Targets (project.yml)
  mDone (iOS)  ===\
                    +== mêmes sources : mDone/ + mDoneShared/   (module "mDone")
  mDone-macOS  ===/   (PRODUCT_MODULE_NAME: mDone épinglé)
  mDoneWidgets (iOS ext)    : mDoneWidgets/ + mDoneShared/
  mDoneMacWidgets (macOS ext): mDoneWidgets/ (moins Info.plist, *.entitlements) + mDoneShared/
  mDoneWidgetRenderTests    : mDoneWidgets/ (moins mDoneWidgets.swift) + mDoneShared/ + ses tests, sans hôte
  mDoneTests / mDoneMacTests: MÊMES fichiers mDoneTests/, hôtes mDone / mDone-macOS, @testable import mDone

mDone/
  App/        14 types "préférences" + AppState (2726 l.) + intents + bootstrap SwiftData + tri/filtre/quickschedule (domaine)
  Models/     structs Codable Vikunja + logique de domaine (récurrence, positionnement, hiérarchie, relations)
  Services/   actors réseau (APIClient, TaskService...), SyncService, CacheService (@Model), parsers purs, Focus*, OIDC
  Views/      Tasks, Projects, Calendar, Focus, Settings, Setup, Notifications, Components, Mac
mDoneShared/  constantes de stockage, token keychain partagé, modèles widget, client HTTP widget, attributs Live Activity
```

Il n'y a **pas de couche ViewModel**. Les vues parlent directement à un seul objet, `AppState`, injecté par `.environment(appState)` dans `mDoneApp.swift`.

## 2. Graphe de dépendances (observé)

```
mDoneApp -creates-> AppDependencies (ModelContainer, NetworkMonitor, StoreRecovery)
   │                       │
   ├-creates-> AppState ─┼── TaskService / ProjectService / LabelService / UserService / ServerInfoService (actors, injectés par init)
   │               │       ├── AuthService.shared, NotificationService.shared (singletons, NON injectés)
   │               │       ├── SyncService (injecté après coup par configureSyncService)
   │               │       ├── CalendarService() (créé en dur, ligne 80)
   │               │       ├── WidgetDataProvider.shared (pushWidgetData)
   │               │       └── UserDefaults.standard (8 usages directs)
   │               └──> AppState.shared (weak static) <── AddTaskIntent, QuickAddIntent
   ├-creates-> FocusManager (iOS), FocusOutboxService (iOS)  ──> ModelContainer
   │                 ^ câblé par closures : appState.onTaskCompleted/onTaskDeleted, focusManager.taskLookup (mDoneApp.onAppear)
   └──> Views : 28 fichiers lisent AppState ; TaskListScreen 28 membres distincts, MacTaskListView 20, MacSidebarView 16, MainTabView 13

APIClient.shared (actor singleton) <── tous les *Service, SyncService (défaut), AuthService
SyncService ──> TaskService, ProjectService, ModelContainer, APIClient
Widgets ──> WidgetDataProvider (HTTP direct, décodeur dupliqué) + SharedTokenStore + SharedKeys.sharedDefaults
```

Les services ne référencent jamais `AppState` (seules mentions : commentaires dans `APIClient`, `FocusManager`, `SyncService`, `TaskService`). Le sens de dépendance Services -> AppState est donc propre : le problème est AppState lui-même et les Views.

## 3. Points chauds de taille (hors tests)

| Fichier | Lignes | Remarque |
|:-|:-|:-|
| `App/AppState.swift` | 2726 | ~330 membres, 100+ méthodes |
| `Services/DescriptionMarkup.swift` | 823 | pur, bien testé (`DescriptionMarkupTests`) |
| `Services/SmartTaskParser.swift` | 762 | pur, bien testé |
| `Services/APIClient.swift` | 658 | réseau + refresh JWT |
| `Views/Tasks/TaskListScreen.swift` | 593 | logique de sections + vue |
| `Services/FocusManager.swift` | 589 | iOS, SwiftData + ActivityKit |
| `Views/Tasks/TaskRow.swift` | 510 | 4 `@AppStorage` + swipe + menu |
| `Views/Setup/ServerSetupView.swift` | 484 | login + OIDC + TOTP dans la vue |
| `Services/SyncService.swift` | 472 | file d'attente + cache + sync |
| `Views/Projects/ProjectBoardView.swift` | 452 | |
| `Models/VTask.swift` | 452 | modèle + règles de dates + requêtes |
| `mDoneWidgets/TodayTasksWidget.swift` | 447 | |

## 4. AppState : responsabilités à extraire

Numéros de ligne de `mDone/App/AppState.swift` (approximatifs, d'après les `MARK` et signatures).

| # | Responsabilité | Lignes | Membres clés | Destination proposée |
|:-|:-|:-|:-|:-|
| 1 | Session / auth / bootstrap | 401-640 | `checkAuth`, `login*`, `completeLogin`, `requireSupportedServer`, `logout`, `expireSession`, `tearDownSession`, `registerAPIClientHandlers` | `SessionStore` (`@Observable`) |
| 2 | Connectivité et retry | 187-270 | `isOffline`, `handleConnectivityChange`, `onNetworkRestored`, `updateRetryState`, `isRetrying` | `ConnectivityStore` ou dans Sync |
| 3 | Chargement / rafraîchissement global + hydratation cache | 643-850, 2036-2110 | `hydrateFromCache`, `persistToCache`, `refreshAll`, `refreshCachedProjectOrders`, `refreshVisibleList`, `applyQuietRefresh`, `isShowingCachedData` | `TaskRepository` (Core/Sync) |
| 4 | Dépôt de tâches (liste canonique en mémoire) | 20-24, 849-960, 1952-2035 | `tasks`, `projectTaskCache`, `merging`, `uniquedById`, `preservingRelations`, `preservingSchedule`, verrou `acquireTaskUpdateSlot` | `TaskRepository` |
| 5 | Mutations de tâches | 1049-1250, 1473-1625, 1887-1950 | `toggleTaskDone`, `undoLastCompletion`, `createTask`, `postponeTask`, `rescheduleTask`, `updateTask`, `setProgress`, `deleteTask` | `TaskActions` (use cases) |
| 6 | Smart lists / dérivés de dates | 273-325, 2410-2470, 2618-2660 | `overdueTasks`, `todayTasks`, `tomorrowTasks`, `thisWeekTasks`, `upcomingTasks`, `noDateTasks`, `occurrences`, `occurrencesByDay` | `Domain/Lists` (fonctions pures) |
| 7 | Recherche / filtres / tri | 64-68, 320-355, 2603-2616 | `searchQuery`, `activeFilter`, `advancedFilter`, `applyingFilters`, `sortPreference` | `Domain/Filtering`, état de vue dans ViewModel |
| 8 | File hors ligne | 959-1050 | `queueOfflineEdit`, `rejectOffline`, `refreshPendingState`, `collectFailedOperations`, `failedSyncMessages`, `storeRecoveryMessage` | `OfflineQueueFacade` (Core/Sync) |
| 9 | Projets | 24-63, 2166-2366 | `createProject`, `updateProject`, `moveProject`, `archive*`, `deleteProject`, `descendantProjectIds`, `collapsedProjectIDs` | `ProjectStore` |
| 10 | Labels + label "Current" | 28, 356-400, 1751-1886 | `toggleLabel`, `createLabel`, `currentLabel`, `toggleCurrent`, `ensureCurrentLabel` | `LabelStore` + `CurrentTasks` |
| 11 | Sous-tâches et relations | 1629-1745 | `addSubtaskRelation`, `createSubtask`, `removeRelation`, `syncEmbeddedRelations` | `RelationActions` |
| 12 | Kanban | 2111-2165, 2585-2602 | `fetchBuckets`, `moveTask(toBucket:)`, `placeTask` | `BoardStore` |
| 13 | Réordonnancement | 2523-2600 | `moveTask(toPosition:)`, `listViewId`, `reorderGeneration` | `TaskActions` |
| 14 | Calendrier | 78-80, 2367-2470 | `calendarEvents`, `calendarAccessGranted`, `requestCalendarAccess`, `calendarEventsForDate/Month` | `CalendarStore` |
| 15 | Notifications Vikunja | 2471-2522 | `fetchNotifications`, `markNotificationRead`, `unreadNotificationCount` | `InboxNotificationsStore` |
| 16 | Équipe / assignés / utilisateur | 126-135, 1244-1348 | `currentUser`, `assignableUsers`, `setAssignees` | `TeamStore` |
| 17 | Version serveur | 166-182, 1261-1300 | `serverVersion`, `showServerUpdateNotice`, `serverNeedsUpdate` | `SessionStore` |
| 18 | Siri / Intents | 1349-1470 | `defaultProject`, `createTaskFromIntent`, `queueIntentCreate`, `IntentTaskOutcome` | `IntentTaskCreator` (sans AppState.shared) |
| 19 | Rappels locaux | ~770, ~2099 | planification `NotificationService` dans `refreshAll` et `applyQuietRefresh` (lit `UserDefaults.standard` directement) | `ReminderScheduler` |
| 20 | Undo d'achèvement | 89-105, 1115-1180 | `onTaskCompleted`, `canUndoLastCompletion`, `recordCompletionForUndo` | `TaskActions` |
| 21 | Export widgets | 2671-2726 | `pushWidgetData` : redéfinit Today/Upcoming/Overdue à la main | `WidgetSnapshotPublisher`, réutiliser `Domain/Lists` |
| 22 | Préférences persistées | 35-62, 120, 360-380 | `collapsedProjectIDs`, `currentLabelId`, `sortPreferences` via `UserDefaults.standard` | `Preferences` |
| 23 | Erreurs | 2662-2670 | `handleError`, `activeError`, `errorMessage` | `ErrorReporter` |

`AppStateTests.swift` (1269 l.) et 21 autres fichiers de test appellent `AppState` directement : toute extraction doit garder une façade `AppState` délégante jusqu'à la fin.

## 5. Problèmes de couplage

1. **Dérivés calculés dans AppState, dupliqués ailleurs.** `todayTasks` / `overdueTasks` / `upcomingTasks` (`AppState` 273-310) et `pushWidgetData` (2675-2726) expriment les mêmes règles avec des filtres légèrement différents (le widget "upcoming" utilise `> endOfDay`, l'app utilise `> début + 7 jours`). Risque de divergence.
2. **Logique de présentation dans les vues.** `TaskListScreen.inboxSections` construit les sections (titres localisés, couleurs, ordre) ; `MacTaskListView` et `MacSidebarView` redéfinissent leur propre version. Le Focus Run dépend de l'ordre des sections via `Views/Focus/FocusRunOrder.swift`.
3. **Deux arbres de vues parallèles** : iOS (`MainTabView`, `TaskListScreen`, `TaskDetailSheet`) et macOS (`MacContentView`, `MacTaskListView`, `MacTaskDetailView`) avec la même logique en double. La sélection Mac est un enum `MacContentView.SidebarSection` référencé par `MacSidebarView`.
4. **Préférences par chaînes littérales.** `"calmMode"` est lu par `@AppStorage` dans `TaskListScreen`, `TaskRow`, `SettingsScreen`, `MacTaskListView`, `MacSidebarView` ; `"currentStallDays"` dans `SettingsScreen` et `TaskRow` ; `"notificationsEnabled"` / `"reminderOffset"` dans `SettingsScreen` et `AppState`. 14 types `*Preference` dans `App/` ont chacun leur clé, mais pas les 4 ci-dessus.
5. **Singletons implicites** : `APIClient.shared`, `AuthService.shared`, `NotificationService.shared`, `WidgetDataProvider.shared`, `AppState.shared` (weak). Les tests passent par `StorageScope` pour ne pas polluer l'app dev.
6. **Modèles qui importent SwiftUI** : `Models/Label.swift` (`VLabel.color: Color`), `Models/VNotification.swift`. Empêche de mettre `Models` dans un module sans UI et de les partager avec les widgets.
7. **Domaine pur rangé dans `Services/` et `App/`** : `SmartTaskParser`, `DescriptionMarkup`, `DescriptionChecklist`, `EstimateSuggester`, `EstimateMarker` (Services) ; `TaskSortOrder`, `AdvancedTaskFilter`, `QuickSchedule` (App). `SmartTaskParser.init` dépend de `DefaultDueTimePreference` et de `Calendar.app` (définis dans `App/`), donc le parser n'est pas isolable tel quel.
8. **`CacheService.swift` n'est pas un service** : ce sont les 5 `@Model`. Les conversions `CachedTask.toVTask()` y vivent aussi ; l'accès (`cacheTasks`, `loadCachedTasks`...) est dans `SyncService`, qui mélange donc file d'attente, cache et sync.
9. **Vues qui touchent SwiftData** : `QuickAddBar` (`modelContext` pour l'historique d'estimation), `FocusHistoryRow`, `FocusSyncSettingsSection`.
10. **Câblage Focus par closures dans `mDoneApp.onAppear`** (`onTaskCompleted`, `onTaskDeleted`, `taskLookup`), seulement iOS : l'ordre d'initialisation dépend de `onAppear`.
11. **Client HTTP dupliqué pour les widgets** : `WidgetDataProvider` réimplémente décodeur dates (zero-date Vikunja), pagination et auth, car les extensions ne compilent pas `mDone/`. Les modèles `WidgetTask` / `WidgetData` sont distincts de `VTask`.
12. **`ServerSetupView` (484 l.)** porte la logique d'orchestration du login (OIDC, TOTP, options) dans la vue.
13. **Nommage** : l'onglet "Inbox" iOS (`MainTabView.Tab.inbox`) et `SidebarSection.inbox` sont une vue d'ensemble datée, pas une boîte de réception : collision sémantique avec l'Inbox de Things (tâches sans projet ni date).

## 6. Ce qui bloque le remplacement complet de la couche vue

Bloquants (à lever avant d'écrire la nouvelle UI) :

| Bloquant | Détail | Remède |
|:-|:-|:-|
| Aucune surface "ViewModel" | Les vues lisent 20-30 membres d'`AppState` et reconstruisent les listes | Introduire des projections pures (`ThingsList`) et des ViewModels fins par feature |
| Règles de listes inexistantes pour Things | Pas de notion d'Inbox Things (sans projet/date), Anytime, Someday, Logbook, This Evening, Headings, Areas, When vs Deadline | Domaine nouveau à écrire dans `Domain/ThingsLists` avec tests ; mapping Vikunja à décider (voir 03 et 05) |
| Navigation à enum Mac partagé | `MacContentView.SidebarSection` référencé par `MacSidebarView`, `MacKeyboardShortcuts` | Routeur de navigation commun dans `App/` |
| `AppState.shared` | Les intents l'utilisent (`AddTaskIntent`, `QuickAddIntent`) | Garder un point d'accès, mais derrière un protocole |
| Préférences non centralisées | Voir §5.4 | `Preferences` unique avec clés typées |
| Éléments de design dispersés | `ColorExtension`, `PriorityBadge`, `LabelChip`, `ProjectColorDot` ; pas de tokens (espacements, polices, couleurs Things) | `DesignSystem/` |

Non bloquants (déjà propres, à réutiliser tel quel) : tous les `*Service` actors, `APIClient`, `Endpoint`, `SyncService` (API), parsers, `FocusManager`/`FocusRecord`, `WidgetDataProvider`, intents, `ModelStoreBootstrap`.

## 7. Contraintes techniques observées dans `project.yml` et le dépôt

- `sources:` des targets app = **répertoires entiers** (`mDone`, `mDoneShared`), donc XcodeGen les parcourt récursivement : déplacer ou créer un `.swift` dans ces dossiers ne demande aucune modification de `project.yml`.
- `mDoneTests/` est plat (74 fichiers + `Helpers/`), même ensemble pour iOS et macOS.
- Fichiers pinnés par chemin : `mDone/Info.plist`, `mDone/mDone.entitlements`, `mDone/mDone-macOS.entitlements`, `mDone/mDone-macOS-CI.entitlements` (référencé par `.github/workflows/macos-tests.yml`), `mDoneWidgets/Info.plist`, `mDoneMacWidgets/Info.plist`, `mDone/Localizable.xcstrings`.
- `SWIFT_VERSION: "5.9"` (mode de langage Swift 5) ; pas de réglage `SWIFT_STRICT_CONCURRENCY` trouvé dans `project.yml` ni les workflows.
- `.swiftlint.yml` : `included: mDone, mDoneTests`, `excluded: mDone/Resources` ; `.swiftformat` exclut aussi `mDone/Resources`. `SwiftLint` tourne en script post-build non bloquant si absent.
- CI : `ios-tests.yml` (iPhone 17, `-only-testing:mDoneTests`) et `macos-tests.yml` (`-only-testing:mDoneMacTests`, signature ad hoc). `mDoneWidgetRenderTests` et `mDoneUITests` sont compilés par le schéma iOS (`testTargets`).
