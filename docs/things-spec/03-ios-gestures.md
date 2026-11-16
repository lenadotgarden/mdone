# 03 - Gestes iOS (iPhone, avec notes iPad)

Base officielle : https://culturedcode.com/things/support/articles/2803582/ (Using Gestures) `[VERIFIED]`. Tout complément est marqué.

## Table des gestes

| Geste | Où | Résultat exact | Source |
|-|-|-|-|
| Tap checkbox | ligne to-do | complète le to-do : coche + titre barré, puis part au Logbook ; re-tap pendant le délai annule | `[FROM-MEMORY]` |
| Tap sur la ligne | liste | ouvre le to-do en place (expand-to-edit), clavier sur titre | `[FROM-MEMORY]` |
| Tap sur une ligne projet/area | Home, Area | entre dans la liste (push) | `[FROM-MEMORY]` |
| Swipe droit sur un to-do | liste | ouvre le picker When (Today, This Evening, Someday, calendrier, Add Reminder) | `[VERIFIED 2803582]` ("Swipe right to bring up When") |
| Swipe gauche sur un to-do | liste | sélectionne le to-do et entre en multi-select ; la barre d'actions du bas apparaît | `[VERIFIED 2803582]` ("To select a to-do, swipe it to the left") |
| Swipe/tap sur d'autres | multi-select | ajoute à la sélection | `[VERIFIED 2803582]` |
| Glisser le doigt vers le bas le long du bord droit | multi-select | sélectionne un groupe consécutif | `[VERIFIED 2803582]` ("dragging your finger down the right side") |
| Swipe gauche sur projet/area | Home | sélectionne le projet/area | `[VERIFIED 2803582]` |
| Long press sur un to-do | liste | soulève l'item sous le doigt ; drag pour réordonner ; drop pour déposer | `[VERIFIED 2803582]` ("tap and hold a to-do until it pops up under your finger") |
| Long press sur un to-do sélectionné | multi-select | tous les items sélectionnés se rassemblent sous le doigt et se déplacent ensemble | `[VERIFIED 2803582]` |
| Drag d'un to-do sur un autre jour | Upcoming | change la start date | `[VERIFIED 4001304]` |
| Long press sur une liste | Home | soulève la liste (Area : emporte ses projets) | `[VERIFIED 2803582]` |
| Long press sur un heading | projet | soulève le heading (avec ses to-dos pour le déplacement de groupe) | `[VERIFIED 2803582]` + `[VERIFIED features]` |
| Swipe gauche sur heading | projet | sélectionne le heading | `[VERIFIED 2803582]` |
| Tap Magic Plus | toute liste | nouveau to-do à l'emplacement par défaut de la liste | `[VERIFIED features]` ("tapping it creates a new to-do") |
| Drag Magic Plus | liste | nouveau to-do inséré à l'endroit du drop | `[VERIFIED 2803582]` |
| Drag Magic Plus vers cible Inbox (bas gauche) | liste | nouveau to-do dans l'Inbox | `[VERIFIED 2803582]` |
| Drag Magic Plus vers bord gauche | projet | nouveau heading à cet endroit | `[VERIFIED 2803582]` |
| Drag Magic Plus | Home | nouveau projet dans l'Area survolée | `[VERIFIED 2803582]` |
| Pull-down | liste | révèle la recherche Quick Find | `[VERIFIED 2803582]` |
| Pull-down dans le picker When | picker | champ de saisie en langage naturel | `[VERIFIED 2803582]` |
| Pull-down dans le popover de tags | tag picker | champ de recherche de tag | `[VERIFIED 2803582]` |
| Long press sur le grip (3 barres) | checklist | réordonne l'item | `[VERIFIED 2803582]` |
| Tap cercle | checklist | complète l'item | `[VERIFIED 2803582]` |
| Swipe gauche sur item de checklist | checklist | supprime l'item | `[VERIFIED 2803582]` |
| Tap sur le nom de liste scrollée | liste | ouvre la navigation Quick Find | `[VERIFIED 2803584]` |
| Edge swipe (bord gauche vers droite) | pile de navigation | retour à la vue précédente (standard iOS) | `[FROM-MEMORY]` |
| Shake | global | Undo (annule la dernière action) / Redo | `[FROM-MEMORY]` |
| Pull-down sur Home | Home | recherche | `[FROM-MEMORY]` |
| Tap long sur Magic Plus puis relâche sans bouger | liste | comme tap `[UNSURE]` | |
| Tap sur la date (When) dans la carte | to-do ouvert | ouvre le picker When `[VERIFIED 2803579]` | |
| Tap sur le drapeau | to-do ouvert | ouvre le picker Deadline `[VERIFIED 2803579]` | |
| Tap sur un tag | to-do ouvert | ouvre le tag picker `[VERIFIED 2803581]` | |
| Tap sur titre de liste sticky | liste | menu "..." : voir 02 | `[UNSURE]` |

## Détails de comportement

### Swipe droit (When)

- Révèle une icône/action calendrier sous la ligne ; un swipe franc l'ouvre ; le picker s'affiche en popover/feuille `[FROM-MEMORY]`.
- Pas de swipe droit "complète" : la complétion passe par la checkbox seulement `[FROM-MEMORY]`.

### Swipe gauche (sélection)

- Ne montre pas de boutons au fil de la ligne (pas de "Delete" rouge) : il entre directement en mode sélection et fait apparaître la barre du bas. Source : "swiping a to-do not only shows you the actions you can perform, but it also immediately enters multi-select mode" `[VERIFIED features]`.
- Sortie : retirer toutes les sélections, ou tap sur Done `[UNSURE]`.

### Drag and drop (réorganisation)

- Le long press soulève l'item (scale léger + ombre + haptique), les autres lignes s'écartent `[VERIFIED 2803582]` pour le soulèvement, animations `[FROM-MEMORY]`.
- Drop entre deux items = nouvelle position. Dans un projet, glisser sous un heading rattache le to-do à ce heading `[FROM-MEMORY]`.
- Dans Today, drop dans la zone This Evening le met en This Evening `[FROM-MEMORY]`.
- Dans Upcoming, drop sur un jour = reschedule `[VERIFIED 4001304]`.
- Sur iPad/Vision avec sidebar visible : drop d'un to-do sur une liste de la sidebar le déplace dedans `[VERIFIED 2803582]`.

### Magic Plus : détail du drag

1. Pression sur le bouton : il se soulève (agrandi, ombre) sous le doigt.
2. Le doigt se déplace ; une ligne vide s'ouvre à l'endroit d'insertion en suivant la position, les autres lignes s'écartent `[FROM-MEMORY]`.
3. Zones spéciales apparaissent : cible Inbox en bas à gauche `[VERIFIED 2803582]` ; bord gauche pour heading dans un projet `[VERIFIED 2803582]`.
4. Relâcher : le to-do est créé et ouvert en édition avec clavier. Relâcher dans une zone non valide revient au tap `[UNSURE]`.

### Pull-down

- Premier seuil : la barre Search apparaît ; continuer à tirer ou toucher la barre la met au focus avec clavier `[FROM-MEMORY]`.
- Dans un picker : champ texte NL `[VERIFIED 2803582]`.

### Shake

- Undo système iOS ; la boîte d'alerte standard "Undo ..." avec nom de l'action `[FROM-MEMORY]`. Redo disponible via secouer à nouveau `[UNSURE]`.

### Double tap

- Aucun double tap spécifique dans les sources `[UNSURE]` ; sur Mac double-clic ouvre un to-do `[VERIFIED 2803581]` ("Double-click a to-do to open it").

### iPad (hors périmètre, mais utile pour les gestes partagés)

- Drag entre fenêtres, drop sur sidebar, collapse de sidebar par swipe `[VERIFIED 2803582]` / `[VERIFIED features]` ("Slim Mode").

## Récapitulatif [UNSURE]

Sortie du multi-select ; comportement de relâche invalide du Magic Plus ; double tap ; seuils de pull-down ; Redo par shake.
