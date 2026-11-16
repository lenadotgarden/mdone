# 04 - Structure cible proposée et plan de migration

Contrainte : aucun compilateur Swift sur l'hôte, la CI GitHub (macOS) est la seule boucle de compilation. Le plan privilégie donc des étapes **mécaniques** (déplacement de fichiers sans modification de code) avant toute modification de logique.

## 1. Pourquoi les déplacements sont sûrs (vérifié dans `project.yml`)

- Les cibles `mDone` et `mDone-macOS` déclarent `sources: [mDone, mDoneShared]` (dossiers entiers, récursifs). Un fichier déplacé dans un sous-dossier de `mDone/` reste compilé sans modifier `project.yml`.
- Un fichier Swift déplacé **dans le même module** ne change aucun symbole : les tests (`@testable import mDone`) ne sont pas affectés. Swift n'a pas de lien entre chemin de fichier et visibilité.
- `mDoneTests/` est un dossier plat inclus par glob dans `mDoneTests` et `mDoneMacTests` : un nouveau sous-dossier miroir fonctionne sans changement (même mécanisme que `mDoneTests/Helpers/`, déjà présent).
- `project.yml` a `generateEmptyDirectories: true` : sans effet gênant pour des dossiers vides.
- **À ne pas déplacer** (références par chemin) : `mDone/Info.plist`, `mDone/*.entitlements` (dont `mDone-macOS-CI.entitlements` utilisé par `macos-tests.yml`), `mDone/Localizable.xcstrings`, `mDone/InfoPlist.xcstrings`, `mDone/Resources/` (exclu de SwiftLint/SwiftFormat, contient `Assets.xcassets` et `PrivacyInfo.xcprivacy`), `mDoneWidgets/Info.plist`, `mDoneMacWidgets/`.
- `mDoneShared/` est compilé par **5** cibles (app iOS, app macOS, extensions iOS et macOS, `mDoneWidgetRenderTests`). Ne rien y ajouter qui importe un type de `mDone/`.
- Les chemins de **fichiers** apparaissent dans `.swiftlint.yml` (`included: mDone, mDoneTests`) : un nouveau dossier racine hors `mDone/` ne serait pas linté ; garder tout sous `mDone/`.

## 2. Structure cible

Tout reste dans le module `mDone` (un seul target) : pas de Swift Package ni de nouvelle cible à ce stade (voir 05, risque de configuration à l'aveugle). Les couches sont des **dossiers**, la règle d'imports est vérifiée par script (§5).

```
mDone/
  App/                       point d'entrée, composition
    mDoneApp.swift, AppDependencies.swift, AppIntents.swift, AddTaskIntent.swift
    AppState.swift           (façade, amincie à chaque étape)
    Navigation/              AppRoute, routeur commun iOS/macOS
  Core/
    Models/                  VTask, Project, VLabel (sans SwiftUI), Bucket, User, TaskRelation, ServerInfo, ...
    Networking/              APIClient, Endpoint, *Service (actors), AuthService, JWTHelpers, ServerURL, OIDCLogin, WebAuthenticator
    Persistence/             CacheModels (ex CacheService), ModelStoreBootstrap
    Sync/                    SyncService, QueuedTaskEdit, NetworkMonitor, LiveListRefresh
    Preferences/             types *Preference, clés typées
  Domain/
    ThingsLists/             Inbox, Today, Upcoming, Anytime, Someday, Logbook : fonctions pures VTask -> sections
    Scheduling/              règles de dates de VTask, QuickSchedule, TaskOccurrence, calendrier
    Repeat/                  TaskRecurrence
    Parser/                  SmartTaskParser, EstimateMarker, EstimateSuggester, DescriptionMarkup, DescriptionChecklist
    Filtering/               AdvancedTaskFilter, TaskSortOrder, TaskPositioning
    Focus/                   FocusRun, FocusHistoryQuery, FocusDurationFormatter
  Features/<Feature>/        View + ViewModel (@Observable, @MainActor)
    Today/ Upcoming/ Inbox/ Anytime/ Someday/ Logbook/
    TaskDetail/ QuickAdd/ Projects/ Board/ Calendar/ Focus/ Settings/ Setup/ Notifications/ Sidebar/
  DesignSystem/
    Tokens/                  couleurs, typographie, espacements
    Components/              case ronde, ligne de tâche, chips, badge priorité, point projet
    Icons/
  Platform/
    iOS/                     MainTabView/shell iOS, ShakeDetector, FocusManager (iOS seul), FocusOutboxService
    macOS/                   shell NavigationSplitView, MacKeyboardShortcuts
  Resources/                 (inchangé : Assets.xcassets, PrivacyInfo.xcprivacy)
  Info.plist, *.entitlements, Localizable.xcstrings   (inchangés)
mDoneShared/                 inchangé (partagé avec les extensions)
mDoneWidgets/                inchangé (habillage Things plus tard)
mDoneTests/
  Core/ Domain/ Features/ App/ Helpers/    (miroir ; sous-dossiers ajoutés par glob)
```

`FocusManager` et `FocusOutboxService` (iOS seulement) vont dans `Platform/iOS/` : déplacement mécanique, le fichier garde son `#if os(iOS)` interne.

## 3. Table ancien chemin -> nouveau chemin

| Ancien | Nouveau |
|:-|:-|
| `mDone/Models/VTask.swift`, `Project.swift`, `Bucket.swift`, `User.swift`, `TaskRelation.swift`, `APIModels.swift`, `AuthOptions.swift`, `ServerInfo.swift`, `VikunjaVersion.swift`, `VNotification.swift`, `Label.swift`, `HexColor.swift`, `CalendarEvent.swift`, `ProjectHierarchy.swift` | `mDone/Core/Models/` |
| `mDone/Models/QueuedTaskEdit.swift` | `mDone/Core/Sync/` |
| `mDone/Models/TaskRecurrence.swift` | `mDone/Domain/Repeat/` |
| `mDone/Models/TaskOccurrence.swift` | `mDone/Domain/Scheduling/` |
| `mDone/Models/TaskPositioning.swift` | `mDone/Domain/Filtering/` |
| `mDone/Models/FocusRun.swift` | `mDone/Domain/Focus/` |
| `mDone/Services/APIClient.swift`, `Endpoint.swift`, `TaskService.swift`, `ProjectService.swift`, `LabelService.swift`, `UserService.swift`, `NotificationService.swift`, `ServerInfoService.swift`, `AuthService.swift`, `JWTHelpers.swift`, `ServerURL.swift`, `OIDCLogin.swift`, `WebAuthenticator.swift`, `TaskLink.swift`, `CalendarService.swift` | `mDone/Core/Networking/` (CalendarService : `Core/Calendar/` ou `Features/Calendar/`) |
| `mDone/Services/SyncService.swift`, `NetworkMonitor.swift`, `LiveListRefresh.swift` | `mDone/Core/Sync/` |
| `mDone/Services/CacheService.swift` | `mDone/Core/Persistence/CacheService.swift` (renommage du fichier plus tard) |
| `mDone/App/ModelStoreBootstrap.swift` | `mDone/Core/Persistence/` |
| `mDone/Services/SmartTaskParser.swift`, `EstimateMarker.swift`, `EstimateSuggester.swift`, `DescriptionMarkup.swift`, `DescriptionChecklist.swift` | `mDone/Domain/Parser/` |
| `mDone/Services/FocusHistoryQuery.swift`, `FocusDurationFormatter.swift` | `mDone/Domain/Focus/` |
| `mDone/Services/FocusManager.swift`, `FocusOutboxService.swift`, `FocusSyncConfig.swift` | `mDone/Platform/iOS/` (FocusSyncConfig : `Core/Preferences/`) |
| `mDone/App/AdvancedTaskFilter.swift`, `TaskSortOrder.swift` | `mDone/Domain/Filtering/` |
| `mDone/App/QuickSchedule.swift` | `mDone/Domain/Scheduling/` |
| `mDone/App/*Preference*.swift`, `TaskListDensity.swift`, `CalendarPreferences.swift`, `CalendarSelection.swift` | `mDone/Core/Preferences/` |
| `mDone/App/AppState.swift` | reste `mDone/App/`, vidé par extraction vers `Core/` et `Features/` |
| `mDone/Views/Tasks/QuickAddBar.swift` | `mDone/Features/QuickAdd/` |
| `mDone/Views/Tasks/TaskListScreen.swift`, `SmartListSection.swift`, `InlineTaskDetail.swift` | `mDone/Features/Today/` etc. (remplacés) |
| `mDone/Views/Tasks/TaskRow.swift` | `mDone/DesignSystem/Components/` (remplacé) |
| `mDone/Views/Tasks/TaskDetailSheet.swift`, `TaskRelationsSections.swift`, `TaskLabelsSection.swift`, `TaskAssigneesSection.swift`, `DescriptionChecklistView.swift`, `RichTextRendering.swift`, `DescriptionEditHint.swift` | `mDone/Features/TaskDetail/` |
| `mDone/Views/Projects/*` | `mDone/Features/Projects/` (`ProjectBoardView` : `Features/Board/`) |
| `mDone/Views/Calendar/*` | `mDone/Features/Calendar/` |
| `mDone/Views/Focus/*`, `Views/Components/FocusHistoryRow.swift` | `mDone/Features/Focus/` |
| `mDone/Views/Settings/*` | `mDone/Features/Settings/` |
| `mDone/Views/Setup/ServerSetupView.swift` | `mDone/Features/Setup/` |
| `mDone/Views/Notifications/*` | `mDone/Features/Notifications/` |
| `mDone/Views/Components/ColorExtension.swift`, `LabelChip`, `PriorityBadge`, `ProjectColorDot`, `ColorSwatchPicker`, `EmptyStateView`, `LoadingOverlay`, `ErrorBanner` | `mDone/DesignSystem/Components/` |
| `mDone/Views/Components/EstimatePicker`, `ReminderEditor`, `TaskScheduleEditor`, `TaskDateRangeMetadata`, `TaskShareButtons`, `TaskSortMenu`, `TaskFilterSheet`, `FilterBar` | `mDone/Features/TaskDetail/` ou `Features/Filters/` |
| `mDone/Views/Components/ShakeDetector.swift` | `mDone/Platform/iOS/` |
| `mDone/Views/MainTabView.swift` | `mDone/Platform/iOS/` |
| `mDone/Views/Mac/*` | `mDone/Platform/macOS/` (les vues à remplacer y restent jusqu'à leur suppression) |
| `mDoneTests/*Tests.swift` | sous-dossiers miroirs (étape finale, facultative) |

## 4. Étapes de migration (chacune garde la CI verte)

Principe : une étape = une PR, vérifiable par la CI iOS et macOS existantes. Étapes 1 à 4 ne modifient que des chemins.

| # | Étape | Nature | Risque | Vérification |
|:-|:-|:-|:-|:-|
| 0 | Poser `docs/architecture-audit/` et un script `scripts/check-layering.sh` (grep des imports, voir §5) en mode avertissement | Ajout | Nul | Le script passe sur le dépôt actuel avec la liste des violations connues |
| 1 | Déplacer `Models/` vers `Core/Models`, `Domain/*` (voir table). Aucun contenu modifié | Mécanique | Faible | CI iOS + macOS compilent ; `mDoneTests` + `mDoneMacTests` verts |
| 2 | Déplacer `Services/` vers `Core/Networking`, `Core/Sync`, `Core/Persistence`, `Domain/Parser`, `Platform/iOS` | Mécanique | Faible | Idem. `FocusManager` est dans un fichier entièrement `#if os(iOS)` : la macOS ne le voit pas, aucun changement |
| 3 | Déplacer préférences et filtres de `App/` vers `Core/Preferences`, `Domain/Filtering` | Mécanique | Faible | Idem |
| 4 | Déplacer `Views/` vers `Features/`, `DesignSystem/`, `Platform/` (sans réécriture) | Mécanique | Faible | Idem ; surveiller `mDoneUITests` compilés dans le schéma iOS |
| 5 | Retirer `import SwiftUI` de `Models/Label.swift` et `VNotification.swift` (extensions `Color` vers DesignSystem) | Modification minime | Moyen (propriétés `color`) | CI ; `ProjectColorTests`, `VTaskColorTests` |
| 6 | Extraire `Domain/ThingsLists` : fonctions pures `(tasks, now, calendar) -> ThingsListContent`, avec tests nouveaux ; `AppState.todayTasks` etc. délèguent | Ajout + délégation | Moyen | Les tests existants (`CurrentTasksTests`, `AppStateTests`) restent verts ; nouveaux tests Domain |
| 7 | `pushWidgetData` utilise `Domain/ThingsLists` (supprime la duplication, attention à la différence `endOfDay` vs `+7 jours`) | Modification | Moyen | `WidgetDataTests` |
| 8 | Extraire de `AppState` un domaine à la fois (ordre : Notifications, Calendrier, Kanban, Projets, Labels/Current, Relations, puis Tâches) ; `AppState` garde des propriétés/méthodes qui délèguent | Refactor | Moyen à élevé | `AppStateTests` inchangés et verts à chaque PR |
| 9 | `Preferences` central : remplacer les chaînes `"calmMode"`, `"currentStallDays"`, `"notificationsEnabled"`, `"reminderOffset"` par des clés typées | Modification | Faible | Mêmes valeurs de clé : migration utilisateur nulle |
| 10 | `DesignSystem/Tokens` + composants Things isolés, avec previews | Ajout | Faible | Compilation seule |
| 11 | Nouveaux `Features/*` Things derrière un drapeau (`AppDependencies` ou `@AppStorage`) ; ancienne UI toujours accessible | Ajout | Moyen | Captures UI |
| 12 | Bascule, puis suppression de l'ancienne UI (DELETE de 03) et des doublons Mac | Suppression | Moyen | Suppression par PR séparée de la bascule |
| 13 | Miroir de `mDoneTests/` par sous-dossiers | Mécanique | Faible | Compilation des deux cibles de tests |

Règles pour les étapes mécaniques : un seul type de déplacement par PR ; aucun renommage de type dans la même PR ; ne pas toucher le contenu des fichiers ; vérifier avec `find` que le nombre de fichiers `.swift` avant et après est identique (hors fichiers ajoutés).

## 5. Règles de couches (imports autorisés)

Dossiers sous `mDone/`, du plus bas au plus haut :

```
Core/Models, Domain  <  Core/(Networking, Persistence, Sync, Preferences)  <  Features, DesignSystem  <  Platform  <  App
```

| Dossier | Peut importer / référencer | Interdit |
|:-|:-|:-|
| `Core/Models`, `Domain/*` | Foundation uniquement | SwiftUI, UIKit, AppKit, SwiftData, EventKit, `AppState`, `Core/Networking`, UserDefaults direct |
| `Core/Networking` | Foundation, Security, AuthenticationServices, `Core/Models`, `mDoneShared` | SwiftUI, `Features`, `AppState` |
| `Core/Persistence`, `Core/Sync` | Foundation, SwiftData, Network, `Core/Models`, `Core/Networking`, `Domain` | SwiftUI, `Features` |
| `Core/Preferences` | Foundation (UserDefaults via `SharedKeys` / `StorageScope`) | `UserDefaults.standard` brut, SwiftUI |
| `DesignSystem` | SwiftUI, `Core/Models` en lecture seule | `AppState`, services, SwiftData |
| `Features/<X>` | SwiftUI, `Core`, `Domain`, `DesignSystem` | Un autre `Features/<Y>` (passer par `App/Navigation`) ; réseau direct ; `#if os` hors `Platform/` sauf petits modificateurs |
| `Platform/iOS`, `Platform/macOS` | tout sauf l'autre plateforme | Être référencé depuis `Core`/`Domain` |
| `App` | tout | |
| `mDoneShared` | Foundation, Security, ActivityKit, SwiftUI si strictement nécessaire | **Tout ce qui est dans `mDone/`** |
| `mDoneWidgets` | `mDoneShared`, WidgetKit, SwiftUI, AppIntents | `mDone/` |

Application : `scripts/check-layering.sh` (grep des `^import` par dossier + `AppState` hors `App`/`Features`) exécuté en CI en étape d'avertissement, puis bloquant quand le dépôt est propre. Il se fait à l'aveugle sans compilateur : c'est un simple `grep`.

## 6. Garde-fous particuliers

- Les symboles gardent leur nom pendant les déplacements ; un renommage de fichier (`CacheService.swift` -> `CacheModels.swift`) est une PR distincte.
- Ne pas créer deux fichiers de même nom dans deux dossiers : Xcode accepte, mais les fichiers de test et les messages d'erreur deviennent ambigus.
- Garder `FocusManager.swift` entièrement sous `#if os(iOS)` : ses importations (`ActivityKit`, `UIKit`) ne compilent pas sur macOS.
- Ne pas déplacer les fichiers `.xcstrings` : leur emplacement est décrit dans `docs/localization.md`, à relire avant tout changement.
