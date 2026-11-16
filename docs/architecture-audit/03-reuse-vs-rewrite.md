# 03 - Réutiliser ou réécrire

Décisions : **KEEP** (inchangé, éventuellement déplacé), **REFACTOR** (logique conservée, structure ou dépendances modifiées), **REPLACE-UI** (la vue est remplacée par une vue Things), **DELETE** (supprimer après remplacement).

Règle appliquée : les couches modèle, réseau, sync, parsing et focus sont conservées ; les vues sont remplacées ; `AppState` est découpé derrière une façade.

## App/

| Fichier | Décision | Raison |
|:-|:-|:-|
| `App/AppState.swift` (2726 l.) | REFACTOR | Découper en stores/use cases (voir 02 §4) ; garder une façade `AppState` tant que les 22 fichiers de tests l'utilisent |
| `App/mDoneApp.swift` | REFACTOR | Garder le câblage (auto-login DEBUG, `isHostingUnitTests`, `onOpenURL`) ; racine de scène à brancher sur le nouveau shell ; sortir le câblage Focus de `onAppear` |
| `App/AppDependencies.swift` | KEEP | Conteneur SwiftData + `NetworkMonitor` + garde pour l'hôte de tests |
| `App/ModelStoreBootstrap.swift` | KEEP | Récupération de store corrompu, testée (`ModelStoreRecoveryTests`) |
| `App/AppIntents.swift` | KEEP | `QuickAddIntent`, `MDoneAppShortcuts` ; doivent rester dans la cible app (#121) |
| `App/AddTaskIntent.swift` | REFACTOR | Garder tout ; remplacer l'accès `AppState.shared` par un protocole étroit |
| `App/AdvancedTaskFilter.swift` | KEEP | Filtre local pur, testé ; le déplacer en `Domain/Filtering` |
| `App/TaskSortOrder.swift` | KEEP | Tri + persistance par scope, testé ; vérifier la persistance (`UserDefaults.standard`) |
| `App/QuickSchedule.swift` | KEEP | Presets de report, pur ; à compléter par les presets Things (This Evening, Someday) |
| `App/CalendarPreferences.swift`, `CalendarSelection.swift` | KEEP | `WeekStartPreference`, `Calendar.app`, `HiddenCalendarStore` ; indispensables au calendrier |
| `App/DefaultDueTimePreference.swift`, `NewTaskDueDatePreference.swift`, `DefaultProjectPreference.swift`, `SmartParsingPreference.swift`, `TeamFeaturesPreference.swift`, `ProjectViewPreference.swift`, `TaskListDensity.swift` | REFACTOR | Garder les types et leurs tests ; les regrouper dans `Preferences` avec clés typées ; `TaskListDensity` / `ProjectViewPreference` peuvent devenir sans objet selon l'UI Things |

## Models/

| Fichier | Décision | Raison |
|:-|:-|:-|
| `Models/VTask.swift` | REFACTOR | Garder le modèle et `TaskUpdateRequest` ; extraire `isOverdue/isDueToday/isDueTomorrow/isDueThisWeek/occurs/occurrenceDays` en `Domain/Scheduling` à terme |
| `Models/Label.swift`, `VNotification.swift` | REFACTOR | Retirer `import SwiftUI` (`VLabel.color`) vers une extension en DesignSystem |
| `Models/Project.swift`, `ProjectHierarchy.swift`, `Bucket.swift`, `User.swift`, `TaskRelation.swift`, `TaskPositioning.swift` | KEEP | Modèle Vikunja et règles de position identiques à la web app |
| `Models/TaskRecurrence.swift`, `TaskOccurrence.swift` | KEEP | Projection de répétitions, testée (`TaskRecurrenceTests`, `CalendarOccurrenceTests`) ; base du calendrier amélioré |
| `Models/QueuedTaskEdit.swift` | KEEP | Intention d'édition hors ligne ; format persisté, ne pas modifier |
| `Models/APIModels.swift` | KEEP | `NetworkError`, `ListPage`, requêtes de login |
| `Models/AuthOptions.swift`, `ServerInfo.swift`, `VikunjaVersion.swift` | KEEP | Auth/serveur |
| `Models/FocusRun.swift` | KEEP | Modèle pur |
| `Models/CalendarEvent.swift`, `HexColor.swift` | KEEP | |

## Services/

| Fichier | Décision | Raison |
|:-|:-|:-|
| `APIClient.swift`, `Endpoint.swift` | KEEP | Cœur réseau v2, refresh JWT, pagination ; très testé (APIClientTests 900 l., Refresh 793 l.) |
| `TaskService`, `ProjectService`, `LabelService`, `UserService`, `NotificationService`, `ServerInfoService` | KEEP | Actors minces |
| `AuthService.swift`, `JWTHelpers.swift`, `ServerURL.swift` | KEEP | |
| `OIDCLogin.swift`, `WebAuthenticator.swift` | KEEP | Testés (OIDCCallbackTests, WebAuthenticatorTests) |
| `SyncService.swift` | REFACTOR | Garder le comportement ; séparer en `PendingOperationQueue`, `LocalCache`, `Syncer` si le temps le permet, sinon KEEP |
| `CacheService.swift` | REFACTOR | Garder les `@Model` **sans changer le schéma** ; renommer en `Persistence/CacheModels.swift` |
| `SmartTaskParser.swift` | KEEP | Parser pur, 460 l. de tests ; seule action : injecter `DefaultDueTimePreference` et `Calendar` sans dépendre de `App/` (déjà paramétrés par `init`) |
| `DescriptionMarkup.swift`, `DescriptionChecklist.swift` | KEEP | Pur, testé ; devient le modèle des checklists Things si on les exploite |
| `EstimateMarker.swift`, `EstimateSuggester.swift` | KEEP | Contrat documenté (`docs/agent-contract-estimated-duration.md`) |
| `FocusManager.swift` | KEEP | iOS seulement ; ne pas réécrire (589 l., Live Activity) ; seules les vues sont remplacées |
| `FocusOutboxService.swift`, `FocusSyncConfig.swift`, `FocusHistoryQuery.swift`, `FocusDurationFormatter.swift` | KEEP | |
| `NetworkMonitor.swift`, `LiveListRefresh.swift`, `CalendarService.swift`, `TaskLink.swift` | KEEP | |

## mDoneShared/ et widgets

| Fichier | Décision | Raison |
|:-|:-|:-|
| `SharedConstants.swift`, `SharedTokenStore.swift`, `FocusSession.swift`, `FocusTaskAttributes.swift`, `WidgetModels.swift` | KEEP | Doivent rester dans `mDoneShared/` (compilés par les extensions) |
| `WidgetDataProvider.swift` | KEEP | Client autonome ; ne pas toucher le décodeur sans test (`WidgetDataTests`) |
| `mDoneWidgets/*` (Today, Upcoming, QuickAdd, LockScreen, Live Activity, intents) | KEEP puis REPLACE-UI | Fonction conservée ; habillage Things (couleurs, polices) dans un second temps, après l'app |
| `mDoneMacWidgets/` | KEEP | Plist et entitlements uniquement |

## Views/

| Fichier / dossier | Décision | Raison |
|:-|:-|:-|
| `Views/MainTabView.swift` | REPLACE-UI | Shell iOS Things ; garder les alertes (sync échouée, version serveur, undo) comme modificateurs réutilisables |
| `Views/Mac/MacContentView`, `MacSidebarView`, `MacTaskListView`, `MacTaskDetailView` | REPLACE-UI | Remplacés par le shell commun Things ; supprimer les doublons iOS/Mac |
| `Views/Mac/MacKeyboardShortcuts.swift` | REFACTOR | Garder les raccourcis, les rebrancher sur le nouveau shell |
| `Views/Mac/MacArchivedProjectsView.swift`, `Views/Projects/ArchivedProjectsScreen.swift` | REPLACE-UI | Équivalent Logbook / projets archivés |
| `Views/Tasks/TaskListScreen.swift` | REPLACE-UI | Contient la logique de sections : l'extraire d'abord en `Domain` |
| `Views/Tasks/TaskRow.swift` | REPLACE-UI | Case ronde Things ; reprendre swipe/menu (QuickSchedule, +24h, Current, Focus) |
| `Views/Tasks/TaskDetailSheet.swift` | REPLACE-UI | Éditeur Things ; garder les sections métier (Repeat, Reminders, Priority, Focus, Current, Labels, Assignees) comme composants |
| `Views/Tasks/QuickAddBar.swift` | REPLACE-UI | Garder tel quel la logique parse/chips/suggestion (extraire en ViewModel) |
| `Views/Tasks/TaskRelationsSections`, `TaskLabelsSection`, `TaskAssigneesSection`, `DescriptionChecklistView`, `RichTextRendering`, `DescriptionEditHint`, `InlineTaskDetail`, `SmartListSection` | REFACTOR | Composants de fonction réutilisables ; restyler. `SmartListSection` DELETE une fois les sections Things en place |
| `Views/Projects/ProjectBoardView.swift` | REFACTOR | Kanban à conserver (feature mDone) ; restyler |
| `Views/Projects/ProjectListScreen`, `ProjectRow`, `ProjectEditSheet` | REPLACE-UI | Sidebar / Areas / projets Things |
| `Views/Calendar/*` | REFACTOR | Calendrier à améliorer : garder `AppState.occurrences` (logique), refaire la grille |
| `Views/Focus/*` | REFACTOR | `FocusSessionView` / `FocusBanner` restylés ; `FocusRunOrder` à rebrancher sur le domaine |
| `Views/Settings/*` | REFACTOR | Beaucoup de réglages métier (14 clés) ; garder, restyler. `CalendarSelectionView` et `FocusSyncSettingsSection` KEEP |
| `Views/Setup/ServerSetupView.swift` | REFACTOR | Extraire l'orchestration de login dans un ViewModel, garder l'écran fonctionnel |
| `Views/Notifications/NotificationListView.swift` | REPLACE-UI | |
| `Views/Components/*` | voir ci-dessous | |

Composants :

| Fichier | Décision | Raison |
|:-|:-|:-|
| `ColorExtension`, `HexColor`-liés, `LabelChip`, `PriorityBadge`, `ProjectColorDot`, `ColorSwatchPicker`, `EmptyStateView`, `LoadingOverlay` | REFACTOR | Déplacer vers `DesignSystem/` et retokéniser |
| `ErrorBanner` | KEEP | Bannière d'erreur + retry |
| `EstimatePicker`, `ReminderEditor`, `TaskScheduleEditor`, `TaskDateRangeMetadata`, `TaskShareButtons`, `TaskSortMenu`, `TaskFilterSheet`, `FilterBar`, `FocusHistoryRow` | REFACTOR | Garder les fonctions, restyler |
| `ShakeDetector` | KEEP | Undo par secousse (iOS) |

## Tests, CI, outillage

| Élément | Décision | Raison |
|:-|:-|:-|
| `mDoneTests/*` (74 fichiers) | KEEP | Un déplacement de source dans le module ne casse aucun test (`@testable import mDone`) tant que les symboles gardent leur nom |
| `AppStateTests.swift` | REFACTOR | À éclater au fil de l'extraction ; ne pas toucher avant la façade |
| `mDoneUITests`, `mDoneMacUITests` | REFACTOR | Captures d'écran à refaire avec la nouvelle UI |
| `mDoneIntegrationTests` | KEEP | Contrat serveur |
| `mDoneWidgetRenderTests` | KEEP | |
| `project.yml`, workflows, `.swiftlint.yml`, `.swiftformat` | KEEP | Ne pas les modifier pendant les déplacements |
| `website/`, `screenshots/`, `scripts/`, `localization/` | KEEP | Hors périmètre du code app |

## Synthèse

- **KEEP ou presque** : tout `Services/`, `Models/`, `mDoneShared/`, `mDoneWidgets/` (fonction), `mDoneTests/`.
- **REFACTOR** : `AppState`, `mDoneApp`, préférences, `SyncService`/`CacheService` (rangement), composants fonctionnels de `Views/`.
- **REPLACE-UI** : shells (`MainTabView`, `Mac*`), listes, ligne de tâche, détail, quick add (habillage), projets, notifications.
- **DELETE** : doublons Mac des listes/détails, `SmartListSection`, anciennes vues d'accueil, une fois la couche Things en production.
