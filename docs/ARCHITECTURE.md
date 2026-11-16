# Architecture cible (fork Things-like)

Document de référence. Toute PR doit respecter ce document ; s'il est faux, on le corrige dans la même PR.
Détails et justifications : `docs/architecture-audit/`. Spécification visuelle et comportementale : `docs/things-spec/`.

## Objectif produit

Client natif iOS et macOS pour un serveur Vikunja, dont l'interface reproduit Things 3 écran par écran, geste par geste, raccourci par raccourci. Les fonctions d'mDone absentes de Things (langage naturel, focus, calendrier amélioré, kanban, durée estimée, retard, priorités) sont ajoutées ensuite, dans le style Things.

Nom de travail : **Sprout** (affichage uniquement, `MDONE_DISPLAY_NAME` dans `project.yml`). Le module Swift et les cibles gardent le nom `mDone` pour limiter le bruit de fusion avec l'amont.

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

## Structure

```
mDone/
  App/            point d'entrée, composition, AppState (façade amincie), Navigation/
  Core/
    Models/       VTask, Project, VLabel, Bucket... (Foundation seulement)
    Networking/   APIClient, Endpoint, *Service (actors), Auth
    Persistence/  SwiftData, ModelStoreBootstrap
    Sync/         SyncService, file d'opérations, NetworkMonitor
    Preferences/  clés typées, types *Preference
  Domain/
    ThingsLists/  Inbox, Today (+ This Evening), Upcoming, Anytime, Someday, Logbook
    Scheduling/   When, Deadline, QuickSchedule, occurrences
    Repeat/       règles de répétition
    Parser/       SmartTaskParser, estimation, Markdown de description
    Filtering/    filtres, tris, positionnement
    Mapping/      encodage des concepts Things sur Vikunja (voir things-spec/07)
    Focus/
  DesignSystem/
    Tokens/       couleurs, typo, espacements, animations (clair et sombre)
    Components/   case ronde, ligne de to-do, chips, ...
    Icons/        icônes maison (pas d'assets Things)
  Features/<Feature>/   View + ViewModel : Home, Today, Upcoming, Anytime, Someday, Logbook,
                        Inbox, Area, Project, TaskDetail, QuickEntry, QuickFind, Board,
                        Calendar, Focus, Settings, Setup, Notifications, Sidebar
  Platform/
    iOS/          shell (navigation iPhone), Magic Plus, gestes, Live Activity, partage
    macOS/        fenêtre, sidebar, inspecteur, Quick Entry global, menus, raccourcis
  Resources/      inchangé
mDoneShared/      partagé avec les extensions, n'importe rien de mDone/
mDoneWidgets/, mDoneMacWidgets/
mDoneTests/       miroir de mDone/ (Core, Domain, Features, App, Helpers)
docs/             ARCHITECTURE.md, ROADMAP.md, things-spec/, architecture-audit/
scripts/          check-layering.sh
```

## Couches

```
Core/Models, Domain  <  Core/(Networking, Persistence, Sync, Preferences)  <  Features, DesignSystem  <  Platform  <  App
```

Règles détaillées par dossier : `docs/architecture-audit/04-proposed-structure.md` §5.

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
