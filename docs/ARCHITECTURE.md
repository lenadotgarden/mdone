# Architecture cible (fork Things-like)

Document de référence. Toute PR doit respecter ce document ; s'il est faux, on le corrige dans la même PR.
Détails et justifications : `docs/architecture-audit/`. Spécification visuelle et comportementale : `docs/things-spec/`.

## Objectif produit

Client natif iOS et macOS pour un serveur Vikunja, dont l'interface reproduit Things 3 écran par écran, geste par geste, raccourci par raccourci. Les fonctions d'mDone absentes de Things (langage naturel, focus, calendrier amélioré, kanban, durée estimée, retard, priorités) sont ajoutées ensuite, dans le style Things.

Nom affiché : **Fern** (`MDONE_DISPLAY_NAME` dans `project.yml`). Le module Swift, les cibles et les identifiants (`com.mdone.app`) gardent `mDone` pour limiter le bruit de fusion avec l amont. Côté données, on reprend les noms de Vikunja et les labels réservés restent minimaux.

## Règles non négociables

1. Un seul module Swift `mDone` pour les deux plateformes. Les couches sont des dossiers.
2. Les dépendances vont uniquement vers le bas (voir « Couches »). `scripts/check-layering.sh` le vérifie en CI.
3. Aucune logique de produit dans une vue. Les vues lisent un ViewModel `@Observable @MainActor` ou un état Domain pur.
4. Le Domain est pur : Foundation seulement, fonctions déterministes `(entrées, now, calendar) -> sortie`, testables sans simulateur.
5. Toute valeur visuelle vient de `DesignSystem/Tokens`. Pas de couleur, taille ou durée d'animation en dur dans une vue.
6. Tout comportement Things est référencé par son numéro de section de `docs/things-spec/`. Les écarts sont notés dans `docs/things-spec/DEVIATIONS.md`.
7. Les modèles SwiftData (`CachedTask`, `CachedProject`, `CachedLabel`, `FocusRecord`, `PendingOperation`) ne changent pas de schéma sans migration (risque de perte de la file hors ligne).
8. Pas de `—` ni `--` dans le texte, le code et les docs.
9. Le code n'est pas compilable sur le serveur de dev : tout passe par la CI macOS. Une PR = un sujet, petite, compilée par la CI avant d'enchaîner.
10. Tout texte visible est dans un String Catalog (`mDone/Localizable.xcstrings`) avec l'anglais comme clé et le français (`docs/localization.md`). Une phrase est une clé entière : pas de concaténation, pas de `count == 1 ?`. `scripts/check-things-localization.py` le vérifie pour le code Things.
11. Le module reste en Swift 5.9. Le code neuf évite ce qui deviendra une erreur en Swift 6 : propriétés statiques de type non `Sendable`, captures non `Sendable` dans une fermeture `@Sendable`, moniteurs `NSEvent` ou `NotificationCenter` qui touchent un état isolé sans repasser par `@MainActor`.

## Structure

État réel. Les écrans d'avant le fork (`MainTabView`, `MacContentView`, `Features/TaskList`, ...) restent et servent de repli quand le réglage `thingsUIEnabled` est faux.

```
mDone/
  App/            point d'entrée, composition, AppState (façade, pas encore amincie), intents
  Core/
    Models/       VTask, Project, VLabel, Bucket...
    Networking/   APIClient, Endpoint, *Service (actors), Auth
    Persistence/  SwiftData, ModelStoreBootstrap
    Sync/         SyncService, file d'opérations, NetworkMonitor
    Preferences/  clés typées et types *Preference (SmartParsingPreference : actif par défaut)
  Domain/
    ThingsLists/  ThingsListBuilder : Inbox, Today (+ This Evening), Upcoming, Anytime, Someday, Logbook
    Mapping/      encodage Things sur Vikunja (things-spec/07) : When, Deadline, checklist, headings,
                  arbre de projets et Areas, cibles de déplacement, langage naturel (ThingsNaturalLanguage)
    Scheduling/ Repeat/ Parser/ Filtering/ Focus/
  DesignSystem/
    Tokens/       ThingsColors, ThingsMetrics (dont Sidebar), ThingsTypography, ThingsMotion, ThingsIcons
    Components/   composants génériques d'avant le fork, et Things/ (case, ligne de to-do, en-têtes,
                  boîte d'événements, Magic Plus)
  Features/
    Things/       écrans iPhone (Home, liste, projet), ViewModels (ThingsListViewModel et ses extensions
                  NaturalLanguage et Reorder, ThingsHomeViewModel), ThingsRowMapper, ThingsQuickFindEngine,
                  ThingsShortcutTable, ThingsRoute, plans de glisser-déposer (purs)
    Board/ Calendar/ Focus/ Notifications/ Projects/ QuickAdd/ Settings/ Setup/ TaskDetail/ TaskList/
  Platform/
    iOS/          ThingsRootView (shell iPhone), FocusManager, MainTabView, ShakeDetector
    macOS/        Things* : fenêtre (ThingsMacRootView, ThingsMacModel), sidebar, liste, éditeur, popovers,
                  commandes de menu, Quick Entry (NSPanel), Quick Find (carte), Type Travel ; et l'ancienne
                  fenêtre (MacContentView, ...)
  Resources/
mDoneShared/      partagé avec les extensions, n'importe rien de mDone/
mDoneWidgets/, mDoneMacWidgets/
mDoneTests/       Domain/ et Features/ pour les tests Things, le reste à plat (AppState, services, intents)
localization/     fichiers plats par langue (fr.json, zh-Hans.json), voir docs/localization.md
docs/             ARCHITECTURE.md, ROADMAP.md, localization.md, things-spec/ (spec, DEVIATIONS.md, WIRING-*.md),
                  architecture-audit/
scripts/          check-layering.sh, check-things-localization.py, localization.py, update-string-catalogs.sh
```

## Couches

```
Core/Models, Domain  <  Core/(Networking, Persistence, Sync, Preferences)  <  Features, DesignSystem  <  Platform  <  App
```

Règles détaillées par dossier : `docs/architecture-audit/04-proposed-structure.md` §5.

### Vérification : `scripts/check-layering.sh`

Lancée par `ci-build.yml` (job `layering`, Ubuntu). Elle cherche par grep, hors lignes de commentaire :

- Core/Models et Domain : pas d'import SwiftUI, UIKit, AppKit, SwiftData, EventKit, pas de `AppState` ni `UserDefaults.standard` ;
- Core/Networking : pas d'import UIKit, AppKit, SwiftUI ;
- DesignSystem : pas de `AppState` ni `SwiftData` ;
- Features et DesignSystem : pas de type Platform de Things (`ThingsMac*`, Quick Entry, Type Travel, `ThingsRootView`), DesignSystem sans ViewModel Things ;
- Core et Domain : pas de ViewModel, mapper, moteur ou table de raccourcis Things ;
- mDoneShared : pas d'import de `mDone` ni `@testable`.

Sans l'option strict, le script avertit et rend 0. Les violations connues viennent d'avant le fork (`Core/Models/Label.swift`, `CalendarEvent.swift`, `VNotification.swift`, `Domain/Focus/FocusHistoryQuery.swift`, `Core/Networking/WebAuthenticator.swift`, `DesignSystem/Components/TaskRow.swift`). Le code Things n'en ajoute aucune ; activer l'option strict demande de les traiter d'abord.

### Glisser-déposer et réordonnancement

Documentés par le lot qui les porte (`docs/things-spec/WIRING-AGENT1.md`, `WIRING-AGENT2.md`, et la spec de glisser-déposer qui l'accompagne). Rien n'est décrit ici pour éviter deux sources.

## Conventions

- Nommage des fichiers : un type principal par fichier, nom du type. Vue : `XxxView`, ViewModel : `XxxViewModel`, fonction pure Domain : `XxxRules`/`XxxBuilder`.
- Plateforme : `#if os()` seulement dans `Platform/` ou pour de petits modificateurs. Sinon, deux vues, une par plateforme, qui partagent le ViewModel.
- Tests : chaque règle Domain a des tests unitaires. Chaque écran a une preview par état (vide, rempli, sombre).
- Changelog : `CHANGELOG.md` sous `[Unreleased]`.
- Commits : conventional commits, branches `things/<sujet>`, PR vers `things-redesign`.

## Environnements de test

- Compilation et tests : GitHub Actions (`macos-latest`), workflows `ci-build.yml` (rapide, à chaque push), `ios-tests.yml`, `macos-tests.yml`.
- Serveur Vikunja jetable : `docker-compose.dev.yml` + `scripts/seed-dev-vikunja.sh`.
- Appareil : compte Apple gratuit, signature 7 jours (AltStore ou Xcode). Les widgets et Live Activities demandent des entitlements à valider sur appareil.
