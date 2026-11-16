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
- [~] Composants écrits, previews à valider, Magic Plus (tap seulement, écrit, non validé par la CI)

## Phase 3 - iPhone
- [~] Home, Today, Upcoming, Anytime, Someday, Logbook, Area, Project (première tranche écrite sans compilateur, non validée par la CI : écran de liste générique, Home, projet/area à plat sans headings)
- [ ] To-do déployé, pickers When/Deadline/Tags, Move, Quick Find
- [~] Gestes : swipe droit When, tap Magic Plus, secousse (undo) faits ; drag, Magic Plus glissé, multi-sélection restent à faire

## Phase 4 - Mac
- [~] Fenêtre, sidebar, listes, éditeur déployé (première tranche écrite sans compilateur, non validée par la CI ni sur un Mac : `ThingsMacRootView`, sidebar, listes, projet/area plat, éditeur en place, popovers When, Deadline, Tags, Move)
- [~] Quick Entry (panneau et moniteur global sous réserve d accès Accessibilité), Quick Find (feuille) écrits, non validés ; Type Travel à faire
- [~] Raccourcis : table testée (`ThingsShortcutTable`), commandes de menu écrites, non validées sur un Mac ; reste listé dans DEVIATIONS.md

## Phase 5 - Fonctions mDone dans le style Things
- [ ] Langage naturel, focus, retard, durée estimée, calendrier amélioré, kanban, widgets, Siri

## Phase 6 - iPad
