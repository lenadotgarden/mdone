# 05 - Risques d'écriture à l'aveugle et checklist CI

Contexte : aucun toolchain Swift sur l'hôte. Chaque erreur de compilation coûte un aller-retour CI (`ios-tests.yml` + `macos-tests.yml`, runners macOS, `xcodegen generate` puis `xcodebuild`). Ce document liste ce qui, dans ce dépôt précis, est le plus susceptible d'échouer.

## 1. Réglages du projet qui conditionnent les erreurs

| Fait observé | Conséquence |
|:-|:-|
| `SWIFT_VERSION: "5.9"`, aucun `SWIFT_STRICT_CONCURRENCY` trouvé | Mode langage Swift 5 : les violations de concurrence sont en général des avertissements, pas des erreurs. Les erreurs viennent surtout d'isolation `@MainActor` mal appelée et de `Sendable` explicite. Ne pas activer le mode Swift 6 pendant la refonte |
| `xcodeVersion: "26.0"`, déploiement iOS 18 / macOS 15 | API récentes disponibles (`SwiftUI.Tab`, `@Observable`, `ContentUnavailableView` déjà utilisés). Ne pas utiliser d'API iOS 26 sans `#available` |
| Un seul module `mDone` pour iOS et macOS | Toute API UIKit ou ActivityKit dans un fichier non gardé casse la compilation macOS |
| `mDone-macOS` : `PRODUCT_MODULE_NAME: mDone` | Ne pas renommer ce réglage |
| Tests macOS : cible hébergée, signature ad hoc, entitlements `mDone-macOS-CI.entitlements` | Un nouvel entitlement ou app group peut casser `macos-tests.yml` |

## 2. Risques par catégorie

### Concurrence et isolation

- `AppState` est `@Observable` (pas `@MainActor` au niveau de la classe) ; les méthodes mutantes portent `@MainActor` une par une. Une nouvelle méthode oubliant l'annotation compile mais mute hors du main actor. À copier : le patron existant.
- Actors (`APIClient`, `*Service`, `SyncService`, `CalendarService`) : tout appel est `await`. Une méthode ajoutée dans un actor appelée depuis une vue sans `await` est une erreur.
- `FocusManager`, `FocusOutboxService`, `LiveListRefresh` sont `@MainActor` : appel depuis un `Task { }` non isolé nécessite `await`.
- `SyncService` est un actor mais ses méthodes `queueOperation` / `queueTaskEdit` sont marquées `@MainActor` (accès au contexte SwiftData principal) : mélange fragile. Ne pas "simplifier" sans tests (`SyncServiceTests`, `OfflineEditQueueTests`).
- `WidgetDataProvider` est `@unchecked Sendable` ; `NetworkMonitor` et `ErrorBanner` utilisent `DispatchQueue`. Garder ces patrons tels quels.
- Closures stockées dans `AppState` (`onTaskCompleted`, `onTaskDeleted`) et `FocusManager.taskLookup` : à déplacer avec précaution, elles sont non-`Sendable`.
- Paramètres de fermeture dans les stores extraits : prévoir `@MainActor` explicite sur les types `@Observable` de ViewModels (cf. commentaire de `QuickAddBar` : "Explicit `@MainActor`" sinon l'isolation est mal inférée dans `Task {}`).

### `@Observable` (Observation framework)

- Pas de `@Published` : toute propriété lue par une vue et stockée doit être une propriété d'un type `@Observable`. Les propriétés calculées (`todayTasks`) sont réévaluées à chaque lecture : coût de recalcul à chaque changement de `tasks`.
- `AppState` utilise `@ObservationIgnored` pour des champs internes (`reorderGeneration`, `activeTaskUpdates`, `taskUpdateWaiters`). Dans un store extrait, tout champ de plomberie doit recevoir la même annotation, sinon des mises à jour de vue parasites apparaissent.
- `didSet` sur `tasks` et `isAuthenticated` incrémente `listRevision` ; un store extrait doit conserver ce comportement, que `LiveListRefresh` et des tests (`VisibleListRefreshTests`) peuvent observer.
- Injection : `.environment(appState)` avec `@Environment(AppState.self)`. Un type `@Observable` ajouté doit être injecté dans `mDoneApp.appContent` sinon crash à l'exécution (pas d'erreur de compilation) : risque connu pour `FocusManager` iOS-only (absent sur macOS).
- `Bindable(appState).activeError` est déjà utilisé ; un ViewModel local utilise `@Bindable` ou `@State`.

### Séparation plateforme

- Le code app est compilé tel quel pour iOS et macOS ; 14 `#if os` dans `AppState`, 15 dans `TaskListScreen`, 8 dans `ServerSetupView`, 8 dans `mDoneApp`. Après déplacement vers `Platform/`, les `#if` doivent rester équilibrés (`#if`/`#endif`) : une copie partielle casse un seul des deux jobs CI.
- `FocusManager` n'existe pas sur macOS : toute vue partagée qui référence `FocusManager` doit être gardée (c'est le cas dans `TaskRow`, `TaskDetailSheet`, `TaskListScreen`, `MainTabView`). Les nouveaux composants Things qui affichent un bouton Focus doivent faire de même.
- Éléments iOS-seuls courants : `UIKit`, `UIImpactFeedbackGenerator`, `.topBarTrailing`, `.fullScreenCover`, `.navigationBarTitleDisplayMode`, `UIApplication`. macOS : `.automatic`, `NSColor`, pas de `fullScreenCover`.
- Les widgets : `LockScreenWidgets` et le Live Activity sont compilés pour macOS avec `#if os(iOS)` interne ; ne pas casser ces gardes en restylant.

### SwiftData

- Cinq `@Model` : `CachedTask`, `CachedProject`, `CachedLabel`, `FocusRecord`, `PendingOperation`. **Ne pas modifier leurs propriétés** pendant la refonte : un changement de schéma sans migration passe par la récupération de store de `ModelStoreBootstrap`, qui peut supprimer le cache et la file hors ligne (rapport de #146, #155). Les ajouts de champs optionnels sont migrés automatiquement (commentaire dans `CachedTask`) ; tout le reste demande une validation sur un vrai appareil.
- `@Attribute(.unique)` sur `CachedTask.id` : un `insert` d'un doublon fait un upsert, pas une erreur.
- Les tests créent des conteneurs en mémoire (`ModelStoreBootstrap.makeInMemoryContainer`) ; l'hôte de test (`isHostingUnitTests`) n'ouvre pas le vrai store.
- `@Query` n'est pas utilisé dans `Views/` (seul `modelContext` apparaît dans `QuickAddBar`, `FocusHistoryRow`, `FocusSyncSettingsSection`). Ne pas introduire `@Query` dans les nouvelles vues : cela contourne la couche Sync.

### Mapping Things -> Vikunja (décisions produit, pas du code)

Sans spécification (`docs/things-spec/` est vide), ces mappings sont des hypothèses à valider avant d'écrire du code :
- **Inbox** (Things) : tâches sans projet ni date. Dans mDone, `projectId` est toujours non nul (`TaskCreateRequest`) : choisir le projet par défaut (`DefaultProjectPreference`) comme "Inbox".
- **When / Deadline** : Vikunja n'a que `dueDate`, `startDate`, `endDate`. mDone utilise `dueDate` comme échéance ; `startDate` pourrait porter le "When". Décision à documenter, car `occurs(on:)`, les widgets et `Calendar` lisent `effectiveDueDate`.
- **Someday, This Evening, Headings, Areas, Logbook** : aucun équivalent natif. Candidats : labels réservés (comme le label "Current" via `ensureCurrentLabel`), projets parents (`ProjectHierarchy`), buckets (`Bucket`), tâches terminées (`done`, `doneAt`).
- Les agents et clients web voient les mêmes tâches : un label réservé est visible côté web.

### API et contrat

- Les mises à jour de tâches sont `PATCH` merge-patch : toute nouvelle écriture doit passer par `TaskUpdateRequest.onlyChanges(from:)`. Un `PUT` efface les champs omis.
- Les lignes `PendingOperation` existantes sont rejouées telles quelles ; ne rien changer au format de `QueuedTaskEdit`.
- Les endpoints nouveaux se déclarent dans `Endpoint.swift` ; vérifier `docs/vikunja-api-inventory.md` avant.

### Localisation, accessibilité

- Les textes sont dans `mDone/Localizable.xcstrings` (source `en`). Une nouvelle chaîne doit exister en anglais ; sans traduction elle s'affiche en anglais. Ne pas utiliser de `String(localized:)` avec des clés dynamiques.
- Les widgets ont leur propre catalogue (`mDoneWidgets/Localizable.xcstrings`).
- Aucun tiret cadratin ni double tiret dans le texte utilisateur, les commentaires, la documentation (règle de `CLAUDE.md`). Un contrôle est dans la checklist.

## 3. Checklist pour minimiser les itérations CI

Avant chaque push :

1. **Un seul sujet par PR** (déplacer OU modifier OU ajouter).
2. **Équilibre des accolades et des `#if`/`#endif`** : compter par fichier modifié (`grep -c '^\s*#if' f` vs `grep -c '^\s*#endif' f`).
3. **Imports** : tout fichier qui utilise `View`/`Color` importe `SwiftUI` ; qui utilise `@Model` importe `SwiftData` (le code actuel importe `Foundation` + `SwiftData` pour `CacheService.swift`).
4. **Plateforme** : tout symbole UIKit/ActivityKit/`FocusManager` est dans un `#if os(iOS)` ; relire chaque vue partagée avec "est-ce que ça compile sur macOS ?".
5. **Isolation** : chaque nouvelle méthode d'un type `@Observable` qui mute l'état porte `@MainActor` ; chaque appel d'actor porte `await`.
6. **Visibilité** : tout est `internal` par défaut ; les tests utilisent `@testable`. Ne pas ajouter `private` sur un membre appelé par un test ou une autre extension d'un fichier différent (`private` est limité au fichier).
7. **`private` et extensions multi-fichiers** : découper `AppState` en extensions dans d'autres fichiers casse les membres `private` utilisés (`taskService`, `syncService`, `handleError`, `pushWidgetData`) : les passer en `internal` ou `fileprivate` consciemment, avant le découpage.
8. **Noms** : ne pas créer de type homonyme d'un type SwiftUI/Foundation (`Tab`, `Section`, `Label`, `Task`). Le code actuel écrit déjà `SwiftUI.Tab` pour lever une collision et `VLabel`, `VTask`, `VNotification` évitent `Label`/`Task`/`Notification`.
9. **Exhaustivité des `switch`** sur `MacContentView.SidebarSection` et `RelationKind` : un `case` ajouté casse chaque `switch` sans `default`. Chercher avec `grep -rn 'SidebarSection'`.
10. **Initialiseurs** : `VTask` et `TaskUpdateRequest` sont des structs `Codable` avec init memberwise implicite ; ajouter un champ modifie l'ordre/les paramètres de l'init partout (tests inclus). Ajouter les champs avec valeur par défaut.
11. **`project.yml`** : ne pas toucher ; si un nouveau dossier racine est nécessaire, c'est une PR à part avec `xcodegen generate` vérifié en CI.
12. **Textes** : chercher le tiret cadratin avec `grep -rn` sur le caractère Unicode U+2014 dans les fichiers modifiés, et relire les nouveaux fichiers pour tout double tiret (hors options de CLI dans les scripts).
13. **Previews** : `#Preview` qui référence un type iOS-seul casse macOS ; les envelopper.
14. **Tests** : après un déplacement, `find mDoneTests -name '*.swift' | wc -l` doit rester 74 + `Helpers` (2).
15. **Pousser en brouillon** : ouvrir la PR en draft, lire la sortie `xcodebuild` des deux jobs, corriger en lot plutôt que push par push.

## 4. Risques organisationnels

| Risque | Mitigation |
|:-|:-|
| `AppState` est le point d'appel de 22 fichiers de tests et de 28 vues | Façade déléguante ; ne supprimer une méthode qu'après migration de ses appelants |
| Régression silencieuse sur le comportement hors ligne (pas de compilation qui l'attrape) | Ne pas toucher `SyncService`/`QueuedTaskEdit` ; lancer `OfflineEditQueueTests`, `SyncServiceTests` à chaque PR (déjà dans le job) |
| Deux UI à maintenir pendant la bascule | Drapeau, durée limitée (étape 11 du plan 04) |
| Spécification Things absente | Écrire d'abord `docs/things-spec/` (dossier vide) avec les règles de chaque liste, puis les tests de `Domain/ThingsLists` avant les vues |
| Le calendrier "à améliorer" | La logique d'occurrences (`TaskOccurrence`, `TaskRecurrence`, `AppState.occurrences`) est testée : améliorer la grille sans toucher la logique |
| Widgets compilés par 5 cibles | Ne rien ajouter à `mDoneShared/` qui dépende de l'app ; vérifier que `mDoneWidgetRenderTests` compile (cible sans hôte) |
