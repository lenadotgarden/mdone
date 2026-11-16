# Roadmap

Statut : `[ ]` à faire, `[~]` en cours, `[x]` fait. Chaque jalon est validé par la CI macOS avant le suivant.

## Phase 0 - Fondations
- [x] Fork, spec Things (`docs/things-spec/`), audit (`docs/architecture-audit/`)
- [x] ARCHITECTURE.md, CI de compilation rapide (ci-build.yml), script de couches
- [x] Étapes 1 à 4 du plan de déplacement (CI iOS + macOS verte sur f858e26)
- [ ] Étapes 5 à 9 (Domain extrait, AppState éclaté, préférences typées)

## Phase 1 - Domain Things (testé en CI, sans UI)
- [x] Mapping Vikunja (Domain/Mapping, tests verts en CI)
- [x] Listes Inbox, Today, Upcoming, Anytime, Someday, Logbook (tests verts en CI)
- [ ] Répétition (fixe / après complétion), rappels

## Phase 2 - DesignSystem
- [~] Tokens (valeurs à calibrer sur captures réelles)
- [~] Composants écrits, previews à valider, Magic Plus à faire

## Phase 3 - iPhone
- [ ] Home, Today, Upcoming, Anytime, Someday, Logbook, Area, Project
- [ ] To-do déployé, pickers When/Deadline/Tags, Move, Quick Find
- [ ] Gestes (swipe, drag, Magic Plus, secousse), multi-sélection

## Phase 4 - Mac
- [ ] Fenêtre, sidebar, listes, éditeur déployé
- [ ] Quick Entry (global), Quick Find, Type Travel
- [ ] Tous les raccourcis (`docs/things-spec/05-macos-shortcuts.md`)

## Phase 5 - Fonctions mDone dans le style Things
- [ ] Langage naturel, focus, retard, durée estimée, calendrier amélioré, kanban, widgets, Siri

## Phase 6 - iPad
