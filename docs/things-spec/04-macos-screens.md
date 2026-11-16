# 04 - Écrans macOS

Légende `[VERIFIED url]` / `[FROM-MEMORY]` / `[UNSURE]`. Les raccourcis complets sont dans 05. Tokens dans 01.

## 1. Fenêtre principale

```
+________________________________________________________________+
| (o)(o)(o)   [<][>]   Today                     [ + ] [search]  |  barre de titre / toolbar
+________________________+_______________________________________+
| Inbox              3   |  [star] Today                         |
|                        |                                       |
| [star] Today      12   |  [ ] To-do A                          |
| [cal]  Upcoming        |  [ ] To-do B             #tag  flag 2d|
| [stack]Anytime         |  [ ] To-do C                          |
| [box]  Someday         |                                       |
|                        |  [moon] This Evening                  |
| [book] Logbook         |  [ ] To-do D                          |
|                        |                                       |
| [pie] Projet libre     |                                       |
| v [area] Work          |                                       |
|    [pie] Projet A      |                                       |
|    [pie] Projet B      |                                       |
| > [area] Home          |                                       |
|                        |                                       |
| [+ New List]           |                           [ + ]       |  pied de fenêtre
+________________________+_______________________________________+
```

- Sidebar : Inbox, Today, Upcoming, Anytime, Someday, Logbook, (Trash si non vide), puis projets libres, puis Areas avec projets repliables `[FROM-MEMORY]`. "The sidebar neatly groups projects underneath their area" `[VERIFIED https://culturedcode.com/things/features/]`.
- Compteurs à droite des lignes ; Today et Inbox au minimum `[FROM-MEMORY]`.
- Sidebar masquable : `Cmd-/` ; en mode "Slim", titre de liste cliquable pour naviguer `[VERIFIED https://culturedcode.com/things/features/]` + `[VERIFIED https://culturedcode.com/things/support/articles/2785159/]` (`Cmd-/`, `Shift-Cmd-O` popover de navigation).
- Barre d'outils masquable `Opt-Cmd-T` `[VERIFIED 2785159]`.
- Fenêtres multiples : `Ctrl-Cmd-N` nouvelle fenêtre ; Cmd-clic pour ouvrir une liste/projet/area en nouvelle fenêtre ; Opt + bouton New Window ouvre la même liste `[VERIFIED 2785159]`. Drag de to-dos entre fenêtres `[VERIFIED features]`.
- Expand/Collapse toutes les Areas : Cmd-clic sur un chevron ; une seule Area ouverte : Opt-Cmd-clic `[VERIFIED 2785159]`.
- Toolbar : boutons précédent/suivant, bouton + (nouveau to-do), bouton de partage, recherche (apparaît en tapant : Type Travel) `[FROM-MEMORY]` ; "New Window button is in the upper-right corner" `[VERIFIED 2785159]`.
- Pas de panneau inspecteur permanent : le détail s'ouvre en place dans la liste (carte) `[FROM-MEMORY]`. Il n'y a donc pas de 3e colonne, contrairement à d'autres apps ; ne pas en créer `[FROM-MEMORY]`.

## 2. Listes (mêmes règles que iOS, voir 02/06)

| Liste | Spécificités Mac `[FROM-MEMORY]` sauf mention |
|-|-|
| Inbox | idem iOS ; "x to-dos were moved out of the Inbox" `[VERIFIED 4001304]` |
| Today | événements calendrier en tête `[VERIFIED 2803583]` ; This Evening en section ; Settings > General pour grouper par projet/area `[VERIFIED 4001304]` |
| Upcoming | 7 jours séparés à partir de demain `[VERIFIED 4001304]` ; drag-drop pour reschedule `[VERIFIED 4001304]` ; événements calendrier aussi `[VERIFIED 2803583]` |
| Anytime | `[VERIFIED 4001304]` comme iOS |
| Someday | contenu estompé `[VERIFIED 4001304]` |
| Logbook | `Shift-Cmd-Y` pour "Move completed to Logbook" `[VERIFIED 2785159]` ; Trash pour suppression définitive (vider la corbeille) `[VERIFIED 4001304]` |
| Area / Project | notes, tags, headings, progression ; "More" à côté du titre : Add Tags, Repeat, Share `[VERIFIED 2803581]` `[VERIFIED 2803564]` `[VERIFIED 2803566]` |
| Listes spéciales | View > Go To : Tomorrow, Deadlines, Repeating, All Projects, Logged Projects `[VERIFIED 2803584]` |
| Filter bar | barre de tags en haut de liste ; clic = filtre, bouton "All" = efface, Cmd-clic = multi-tag (ET) `[VERIFIED 2803581]` ; `Ctrl-Esc` quitte le filtre `[VERIFIED 2785159]` |

## 3. To-do ouvert (expanded)

Double-clic, Return, ou clic sur titre déjà sélectionné ouvre `[VERIFIED 2803581]` (double-clic) / `[VERIFIED 2785159]` (Return ouvre).

```
+______________________________________________________________+
|  [ ]  Titre du to-do                                         |
|       Notes (Markdown)                                       |
|                                                              |
|       [ ] item de checklist                                  |
|       [ ] item                                               |
|                                                              |
|  [tag][tag]                          [star Today]  [flag 5d] |
|  [Tags] [Checklist] [When]  [Deadline]              [More]   |  barre d'actions
+______________________________________________________________+
```

- Champs et boutons : Tags (clic -> champ de saisie, Return), When, Deadline (drapeau), Checklist (`Shift-Cmd-C`), More (Share..., Repeat...) `[VERIFIED 2803581]` `[VERIFIED 2803566]` `[VERIFIED 2803564]`.
- "In the toolbar at the bottom of the window, click More > Share..." `[VERIFIED 2803566]`.
- Esc : ferme et enregistre ; `Cmd-Return` : enregistre et ferme `[VERIFIED 2785159]` ("In the main app, the Esc key collapses open to-dos and saves changes").
- Supprimer un tag : clic sur le tag puis Delete `[VERIFIED 2803581]`.
- Survol devant un to-do : un bouton calendrier apparaît à gauche ("hover your mouse in front of a to-do and click the calendar button") `[VERIFIED features]` (Jump Start).
- Find in Text (`Cmd-F` dans notes via Shift-Cmd-F) `[VERIFIED 2785159]`.
- Liens : `Opt-Cmd-Return` ouvre le lien sous le curseur `[VERIFIED 2785159]`.
- Un to-do copié depuis un répétitif : lien "This is a copy of a repeating to-do" `[VERIFIED 2803564]`.

## 4. Popovers

### When (Jump Start), `Cmd-S`

```
+__________________________+
| [ type a date ...      ] |  champ NL ("tues 8am", "17d") [VERIFIED 9780167]
| [star] Today             |
| [moon] This Evening      |
| [box]  Someday           |
|  < nov 2026 >            |
|  calendrier mois         |
| [+] Add Reminder         |
| [Clear]                  |
+__________________________+
```

- Taper pour filtrer/interpréter ; Return pour valider `[VERIFIED 9780167]`.
- Add Reminder : champ d'heure puis Done `[VERIFIED 2803585]`.
- Les raccourcis `Cmd-T/E/R/O` évitent le popover `[VERIFIED 2785159]`.

### Deadline, `Shift-Cmd-D`

- Même popover calendrier, avec NL, bouton Clear `[VERIFIED 9780167]` `[VERIFIED 2803579]`.

### Tags

- Popover liste de tags avec case, recherche ; `Shift-Cmd-T` ; fenêtre dédiée Window > Tags (`Ctrl-Cmd-T`) pour gérer, assigner des raccourcis, imbriquer par drop, réordonner `[VERIFIED 2803581]`.
- Drag and drop to-do sur tag ou tag sur to-do `[VERIFIED 2803581]`.

### Move dialog (`Shift-Cmd-M`)

- Champ de recherche, liste d'Inbox, Areas, projets ; Enter pour valider ; permet de cibler headings et projets inactifs `[VERIFIED 4001304]` + `[VERIFIED features]` ("Quick Move").

### Repeat (`Shift-Cmd-R`)

- Panneau avec mode (After completion / Daily / Weekly / Monthly / Yearly), intervalle, jours sélectionnables via bouton +, "Add deadlines" avec "days earlier", date de fin, OK `[VERIFIED 2803564]` `[VERIFIED 3743733]`.
- Menu de la règle (sur template) : Edit Rule..., Create Next Copy, Show Previous Copy, Pause, Resume, Stop `[VERIFIED 2803564]`.

## 5. Quick Entry (global)

```
+__________________________________________+
| [ ] Titre du to-do                       |
|     Notes                                |
|  [Inbox v]  [tags] [When] [Deadline]     |
|                          [Cancel] [Save] |
+__________________________________________+
```

- Raccourci global par défaut : `Ctrl-Space` ; configurable dans Things > Settings > Quick Entry `[VERIFIED https://culturedcode.com/things/support/articles/2249437/]`.
- Fenêtre flottante près du curseur/centre `[FROM-MEMORY]`. Titre, notes, choix de la liste destination (Inbox par défaut), tags, When, Deadline ; "All the keyboard shortcuts ... work inside of Quick Entry as well" `[VERIFIED 2249437]`.
- Boutons Save / Cancel ; `Esc` ferme et jette ; `Cmd-Return` ferme et enregistre `[VERIFIED 2249437]`.
- Navigation Tab nécessite "Keyboard Navigation" macOS `[VERIFIED 2249437]`.
- Bug connu : apple bloque les raccourcis à seul modificateur Shift (macOS 15.2) `[VERIFIED 2249437]`.

### Quick Entry with Autofill

- `Ctrl-Opt-Space` par défaut ; capture le lien de la page Safari, du mail Mail ou du fichier Finder courant dans les notes du to-do ; nécessite l'installation d'un "Helper" ; Settings > Quick Entry > "Enable shortcut for Quick Entry with Autofill" `[VERIFIED 2249437]`.
- Peut ranger directement sous un heading `[VERIFIED 2249437]`.

## 6. Quick Find et Type Travel

- Type Travel : aucune combinaison requise, on commence à taper n'importe où ; la recherche s'ouvre immédiatement `[VERIFIED features]` ("As soon as you strike a key, the search is on") `[VERIFIED 2803584]`.
- `Cmd-F` ouvre aussi la recherche `[VERIFIED 2785159]`.
- Résultats instantanés : to-dos, projets, areas, tags, listes par défaut/spéciales, headings ; "Continue Search" pour notes/checklists/Logbook `[VERIFIED 2803584]`.
- Navigation : taper "tod" puis Return -> Today ; "finan" -> area Finances ; "next action" -> heading `[VERIFIED 2803584]`.
- `Cmd-Return` ou Cmd-clic : ouvrir le résultat en nouvelle fenêtre `[VERIFIED 2785159]`.
- Taper un tag : filtre app-wide `[VERIFIED features]`.

## 7. Menu bar (menus de l'app) `[FROM-MEMORY]`, détails `[VERIFIED 2785159]`

| Menu | Entrées principales |
|-|-|
| Things | About, Settings... (`Cmd-,`), Services, Hide, Quit |
| File | New To-Do, New Project, New Heading, New Repeating To-Do `[VERIFIED 2803564]`, New Window, Close, Print |
| Edit | Undo/Redo, Cut/Copy/Paste, Duplicate, Select All, Find (Quick Find), Find in Text/Find and Replace, Markdown submenu, Spelling, Substitutions `[VERIFIED 4438545]` |
| Items | Complete, Cancel, When (Show When, Today, This Evening, Anytime, Someday), Add Deadline, Repeat..., Tags, Move..., Move to Top/Bottom, Show in Parent List `[VERIFIED 2785159]` `[VERIFIED 2803564]` ("Items > Repeat") |
| View | Show/Hide Sidebar, Toolbar, Go To (listes spéciales : Tomorrow, Deadlines, Repeating, All Projects, Logged Projects), Show/Hide later items `[VERIFIED 2803584]` `[VERIFIED 2785159]` |
| Window | Minimize, Zoom, Tags (fenêtre) `[VERIFIED 2803581]`, nouvelle fenêtre |
| Help | Keyboard Shortcuts (page de support) `[VERIFIED 2785159]` |

Tout raccourci peut être redéfini dans Réglages Système pour toute commande visible dans les menus `[VERIFIED 2785159]`.

## 8. Settings (Things > Settings) `[FROM-MEMORY]` sauf mention

- General : Text Size (curseur) `[VERIFIED 8537373]`, Group Today by project/area `[VERIFIED 4001304]`, Show Mac badge count / compteur du Dock `[UNSURE]`, Move completed to Logbook : Immediately / Daily / Manually `[UNSURE]`.
- Calendar Events : case Show Calendar Events in Today and Upcoming + calendriers `[VERIFIED 2803583]`.
- Quick Entry : raccourcis, option Autofill + Helper `[VERIFIED 2249437]`.
- Things Cloud `[VERIFIED 2803586]`.
- Appearance : "Icon & widget style" `[VERIFIED 2803567]`.
- Notifications `[UNSURE]`.

## 9. Menu bar extra / badge

- Badge Dock : nombre de to-dos Today (+ rouge si deadlines atteintes ?) `[UNSURE]`.
- Pas de menu bar extra officiel (Things n'en a pas) `[FROM-MEMORY]` ; tout passe par Quick Entry, widget et Dock badge.
- Widgets macOS : bureau et Notification Center depuis Sonoma ; mêmes types que iOS `[VERIFIED 2803567]`.

## 10. Drag and drop (Mac)

| Source | Cible | Résultat `[FROM-MEMORY]` sauf mention |
|-|-|-|
| to-do | autre position dans la liste | réordonne |
| to-do | liste dans la sidebar (Today, Someday, projet, area) | déplace/planifie dans cette liste |
| to-do | jour dans Upcoming | start date = ce jour `[VERIFIED 4001304]` |
| to-do | tag dans la fenêtre Tags | applique le tag `[VERIFIED 2803581]` |
| tag | to-do | applique le tag `[VERIFIED 2803581]` |
| tag | autre tag | imbrique `[VERIFIED 2803581]` |
| to-dos multiples | n'importe où | déplace en bloc |
| heading | autre position dans le projet | déplace avec ses to-dos `[VERIFIED features]` |
| heading | autre fenêtre | déplace vers un autre projet `[VERIFIED 2803582]` (iPad) |
| projet | area dans sidebar | range dans l'area |
| to-do | autre fenêtre Things | déplace entre listes `[VERIFIED features]` |
| texte multi-lignes | liste | un to-do par ligne (comme `Cmd-V`) `[VERIFIED 2785159]` |

## 11. Interactions diverses

- Espace sur un to-do sélectionné : nouveau to-do en dessous `[VERIFIED 2785159]`.
- `Cmd-V` de texte multi-lignes : un to-do par ligne `[VERIFIED 2785159]`.
- Clic sur la checkbox avec Opt : annule (cancel) au lieu de compléter `[VERIFIED 2785159]`.
- Hover devant un to-do : bouton When (calendrier) `[VERIFIED features]`.
- Selection : flèches, Shift pour étendre, Opt pour sauter aux extrêmes `[VERIFIED 2785159]`.
- Touch Bar : accès aux commandes fréquentes `[VERIFIED features]`.

## Récapitulatif [UNSURE]

Largeur de sidebar ; position exacte des boutons de toolbar ; contenu exact des menus File/Items/View ; options exactes de Settings > General ; comportement du badge Dock ; menu "Move completed to Logbook" (options) ; apparence exacte des popovers.
