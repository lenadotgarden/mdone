# Roadmap

Statut : `[ ]` à faire, `[~]` en cours, `[x]` fait. Chaque jalon est validé par la CI macOS avant le suivant. Tout le code Things a été écrit sans compilateur : `[x]` ne veut dire "fait" que pour ce qui est vert en CI.

## Phase 0 - Fondations
- [x] Fork, spec Things (`docs/things-spec/`), audit (`docs/architecture-audit/`)
- [x] ARCHITECTURE.md, CI de compilation rapide (ci-build.yml), script de couches (`scripts/check-layering.sh`, avertissements seulement tant que les violations d'avant le fork ne sont pas résolues)
- [x] Étapes 1 à 4 du plan de déplacement (CI iOS + macOS verte sur f858e26)
- [ ] Étapes 5 à 9 (Domain extrait, AppState éclaté, préférences typées)

## Phase 1 - Domain Things (testé en CI, sans UI)
- [x] Mapping Vikunja (Domain/Mapping, tests verts en CI)
- [x] Listes Inbox, Today, Upcoming, Anytime, Someday, Logbook (tests verts en CI)
- [~] Arbre de projets et Areas, cibles de déplacement, charge utile de glisser-déposer (`ThingsProjectTree`, `ThingsMoveTargets`, `ThingsDragPayload`), langage naturel (`ThingsNaturalLanguage`) : écrits avec tests, non validés par la CI
- [ ] Répétition (fixe / après complétion), rappels

## Phase 2 - DesignSystem
- [~] Tokens (valeurs à calibrer sur captures réelles ; palette sombre chaude, `ThingsMetrics.Sidebar`)
- [~] Composants écrits, previews à valider, Magic Plus (tap seulement)

## Phase 3 - iPhone
- [~] Home, Today, Upcoming, Anytime, Someday, Logbook, Area, Project (écrits, non validés par la CI : projet/area à plat sans headings)
- [ ] To-do déployé, pickers When/Deadline/Tags, Move, Quick Find
- [~] Gestes : swipe droit When, tap Magic Plus, secousse (undo) faits ; drag, Magic Plus glissé, multi-sélection restent à faire

## Phase 4 - Mac
- [~] Fenêtre, sidebar en arbre, listes, éditeur déployé, popovers When, Deadline, Tags, Move (écrits, non validés par la CI ni sur un Mac)
- [~] Quick Entry (panneau, moniteur global sous réserve d'accès Accessibilité), Quick Find (carte en surimpression), Type Travel : écrits, non validés
- [~] Raccourcis : table testée (`ThingsShortcutTable`), commandes de menu écrites ; reste listé dans DEVIATIONS.md
- [~] Réordonnancement et glisser-déposer (liste, sidebar) : voir DEVIATIONS.md, lot en cours

## Phase 5 - Fonctions mDone dans le style Things
- [~] Langage naturel (anglais et français, actif par défaut) fait côté Things
- [ ] Focus, retard, durée estimée, calendrier amélioré, kanban, widgets, Siri dans le style Things

## Transverse
- [x] Français pour tous les textes Things (`localization/fr.json`, `scripts/check-things-localization.py`) ; le reste de l'app reste en anglais et en chinois simplifié
- [ ] Swift 6 : le projet reste en Swift 5.9 ; les fichiers Things ont été relus (WIRING-AGENT-B.md), un avertissement de `mDoneApp.swift` reste

## Phase 6 - iPad
