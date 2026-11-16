# Cablage du lot "liste Mac" (agent 2)

Ce qui a change, et ce que les autres lots doivent savoir. Aucune modification des fichiers hors de mon perimetre.

## Fichiers
- Tokens : `DesignSystem/Tokens/ThingsColors.swift` (palette sombre chaude, nouveaux tokens), `ThingsMetrics.swift`, `ThingsTypography.swift`, `ThingsMotion.swift`, `ThingsIcons.swift` (`notesDocument`, `moreDots`).
- Composants : `ThingsTodoRow` (ligne Mac a deux lignes), `ThingsTodoRowModel` (`projectLine`, `datePill`, `isSomeday`), `ThingsSectionHeader` (nouveau style `.icon`), `ThingsListHeader` (parametres `trailing`, `bottomPadding`, `ThingsMoreMenu`), `ThingsTagChip` (contour sur Mac), `ThingsCheckbox` (`isDashed`), nouveau `ThingsCalendarEventsBox.swift` (`ThingsCalendarEventsBox`, `ThingsFilterBar`, `ThingsFooterLink`).
- Mac : `ThingsMacTodoList`, `ThingsMacListScreen` (contient `ThingsMacProjectScreen`), `ThingsMacTodoEditor`.
- Features : `ThingsRowMapper` (`applyingProjectLine`, `applyingDatePills`, `weekdayPill`, `projectLine`), nouveau `ThingsListViewModel+Reorder.swift` (`ThingsReorder`, `ThingsReorderPlan`, `ThingsListViewModel.commitReorder`).
- Test : `mDoneTests/Features/ThingsReorderTests.swift`.

## Pour les proprietaires des autres fichiers
1. `ThingsListViewModel+Reorder.swift` n'utilise pas `appState` du view model (il est `private`) : `commitReorder(_:appState:)` recoit `model.appState`. Rien a changer dans `ThingsListViewModel.swift`.
2. Raccourcis : Cmd Opt Haut/Bas (et Cmd Haut/Bas) sont geres par le gestionnaire de touches de `ThingsMacTodoList`, pas par le menu. `ThingsShortcutTable` marque encore `moveItemUp/Down/ToTop/ToBottom` comme `todo` : a mettre a jour (Cmd Opt = un cran, c'est la demande de Lena, ce qui differe de Things ou Opt Cmd = haut/bas de liste). Ne pas ajouter ces chords a un menu avec `keyboardShortcut` : le menu aurait priorite sur la liste et ferait doublon.
3. DEVIATIONS.md, a mettre a jour : "05 (deplacer)" (reordonnancement fait, drag et clavier, dans une section a la fois, pas d'auto-defilement pendant le drag, pas de deplacement hors section), "04 section 2 Today" (boite d'evenements faite : affichee seulement si l'acces EventKit est deja accorde, jamais de demande de permission depuis la liste), "04 section 11" (Esc deselectionne, Espace avale sans creer de to-do).
4. `ThingsMetrics.Layout.listHorizontalMargin` vaut 10 sur Mac (etait 20) : la surbrillance de ligne commence a x = 0 et la case a 10. `ThingsInlineAddRow` et la Home iPhone le lisent, iOS inchange (16).
5. `ThingsMetrics.Card.outerMargin` vaut 0 sur Mac : la carte est decalee de `Card.outset` (4) vers l'exterieur par `ThingsMacTodoList`.
6. Le titre de la fenetre Mac (barre d'outils transparente) est suppose a 52 pt : `Header.topPadding` (18) en depend. Si `ThingsMacRootView` change le style de la barre, ajuster ce token.
7. Barre de filtre : filtre local a l'ecran par tag (pas de Ctrl-Esc, pas de filtre global).
8. L'ordre manuel passe par `AppState.moveTask(_:toPosition:)` : exige un `listViewId` de projet (sinon l'appel renvoie false et la ligne revient a sa place) et une connexion (hors ligne : alerte `rejectOffline`).
