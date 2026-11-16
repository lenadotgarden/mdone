# 02 - Écrans iPhone

Légende : `[VERIFIED url]` / `[FROM-MEMORY]` / `[UNSURE]`. Les wireframes sont indicatifs (proportions approximatives). Tokens visuels dans 01. Gestes détaillés dans 03. Règles métier dans 06.

Plan de navigation iPhone `[FROM-MEMORY]` :

```
Home (main lists view)
 +- Inbox | Today | Upcoming | Anytime | Someday | Logbook
 +- Area -> Project
 +- Quick Find (pull-down)  +- Settings
Liste -> to-do ouvert (carte en place, pas de push)
Projet -> headings, to-dos
```

## 1. Home (liste des listes)

Sur iPhone la racine est la "main lists view" ; sur iPad/Vision/Duo c'est une sidebar `[VERIFIED https://culturedcode.com/things/support/articles/4001304/]` ("sidebar (Mac/iPad/iPhone Duo/Vision) and the main lists view (iPhone)").

```
+______________________________________+
|                                      |   (pas de titre ; zone de pull-down = Quick Find)
|  [tray]  Inbox                    3  |   blanc, compteur gris
|                                      |   (espace vertical ~ 16 pt)
|  [star]  Today                   12  |   compteur: nb de to-dos
|  [cal ]  Upcoming                    |
|  [stack] Anytime                     |
|  [box ]  Someday                     |
|                                      |
|  [book]  Logbook                     |
|                                      |
|  [pie] Projet sans area              |   projets orphelins d'abord
|  [pie] Autre projet                  |
|                                      |
|  [area] Work                         |   Area en gras / grise
|     [pie] Projet A                   |   projets nestés sous leur Area
|     [pie] Projet B                   |
|  [area] Home                         |
|                                      |
|  [+] New List                [gear]  |   barre basse : bouton gauche, Settings droite
+______________________________________+
```

- Ordre, regroupement : Inbox seule ; puis Today, Upcoming, Anytime, Someday ; puis Logbook ; puis projets sans area ; puis Areas avec leurs projets `[FROM-MEMORY]`. Les listes par défaut ne peuvent être ni renommées, ni supprimées, ni réordonnées `[VERIFIED https://culturedcode.com/things/support/articles/2803579/]`.
- Les projets avec une date de début future ou dans Someday disparaissent de cette vue tant qu'ils sont inactifs `[VERIFIED 4001304]`.
- Compteurs : Inbox (nombre d'items), Today (nombre ; en couleur si items en retard/deadline) `[FROM-MEMORY]`. Les autres listes n'ont pas de compteur `[UNSURE]`.
- Tap sur une ligne : push de la liste (transition standard iOS, edge-swipe retour).
- "New List" (en bas à gauche) : feuille avec choix New Project / New Area `[FROM-MEMORY]` ; "Magic Plus" glissé dans cette vue crée un projet directement dans une Area `[VERIFIED https://culturedcode.com/things/support/articles/2803582/]`.
- Settings : icône engrenage en bas à droite `[UNSURE]` (position exacte).
- Pull-down : révèle la barre de recherche Quick Find `[VERIFIED 2803582]`.
- Edit mode : un long press sur une liste la soulève (drag) ; un swipe gauche sur un projet ou une area la sélectionne (barre d'actions en bas) `[VERIFIED 2803582]`.
- Quand Today est vidé, la ligne Today garde l'icône étoile (grisée) `[UNSURE]`.

## 2. Écran de liste générique (structure commune)

```
+______________________________________+
| < Back                       [...]   |  nav bar transparente, '...' = menu de la liste
|                                      |
|  [star] Today                        |  grand titre (34 pt bold) + icône
|                                      |
|  [ ] Acheter du pain      #errand    |  to-do row
|  [ ] Appeler Kate                    |
|  [ ] Rapport              flag 3 d   |
|                                      |
|                              ( + )   |  Magic Plus
+______________________________________+
```

- Titre grand scrolle avec la liste ; quand on descend, le titre compact apparaît en barre supérieure ; le toucher fait apparaître le menu de navigation (Quick Find) `[VERIFIED 2803584]` ("When you're scrolled down in a list, tap the list name at the top").
- Bouton "..." (More) en haut à droite : Share, Filter by Tag, etc. `[VERIFIED 2803581]` (Filter by Tag via "More") et `[VERIFIED 2803566]` (Share via "More"). Contenu exact du menu `[UNSURE]`.
- Filter by tag : barre verte en haut quand le filtre est actif, bouton `x` pour effacer `[VERIFIED 2803581]`.

### Ligne de to-do (état repos)

```
 [ ]  Titre du to-do                         
      Aperçu de la note sur une ligne (gris, optionnel)
      [tag][tag]                 flag 5 days left
```

- Checkbox à gauche. Titre 17 pt. Si le to-do a une note : petite icône note `[FROM-MEMORY]` ou ligne d'aperçu (une ligne max) `[UNSURE]`. Si checklist : indicateur "x/y" `[FROM-MEMORY]`.
- Tags : pills grises à droite du titre ou sous lui `[FROM-MEMORY]`. Seuls les tags posés directement sont affichés, pas les hérités `[VERIFIED 2803581]`.
- Deadline : drapeau + "N days left" / "Today" / "N days ago", rouge à partir de J `[FROM-MEMORY]` ; "The days remaining until the deadline will show next to the to-do and count down" `[VERIFIED 2803579]`.
- Étoile jaune devant le to-do dans Anytime et projets quand il est dans Today `[VERIFIED 4001304]`.
- Reminder : heure affichée (ex. "9:00") près du titre dans Today `[UNSURE]`.
- Item complété : coche remplie, titre barré gris, reste visible brièvement puis part au Logbook `[FROM-MEMORY]`.

## 3. Inbox

- Titre "Inbox" icône tray bleue.
- Contenu : items non traités, ordre manuel, nouveaux en bas `[FROM-MEMORY]`.
- Section temporaire en bas : "x to-dos were moved out of the Inbox", disparaît à l'entrée dans une autre liste `[VERIFIED 4001304]`.
- Tout to-do déplacé dans une liste ou daté quitte l'Inbox `[VERIFIED 4001304]`.
- Pas de ligne "Move to" spécifique ; Clear du When + Move vers "No Project" le renvoie en Anytime `[VERIFIED 2803579]` ("Anytime from the Inbox, use Move > No Project").
- Texte d'état vide `[UNSURE]` (voir 06).

## 4. Today

```
+______________________________________+
| <                            [...]   |
|  [star] Today                        |
|                                      |
|  09:00  Réunion équipe        (cal)  |  section événements calendrier (si activée)
|  14:00  Dentiste                     |
|  ____________________________________|
|  [ ] To-do A                         |
|  [ ] To-do B                         |
|  [ ] To-do C           flag 1 day    |
|                                      |
|  [moon] This Evening                 |  en-tête de section
|  [ ] Lire                            |
|  [ ] Appeler maman                   |
|                              ( + )   |
+______________________________________+
```

- "Think of it as a filter across the entire app": start date, deadline ou règle de répétition = aujourd'hui `[VERIFIED 4001304]`.
- Section d'événements calendrier en tête si Settings > Calendar Events est activé, pour les calendriers choisis ; événements locaux en lecture seule, Apple Calendar seulement `[VERIFIED https://culturedcode.com/things/support/articles/2803583/]`.
- This Evening : section en bas de Today avec sa propre icône/titre `[VERIFIED 4001304]`.
- Réglage : grouper Today par projet/area (Settings > General) `[VERIFIED 4001304]` ("Enable this in Things > Settings > General").
- Items avec deadline arrivée à échéance apparaissent aussi ici `[VERIFIED 4001304]`.
- Ordre manuel par drag `[VERIFIED 4001304]` ("drag and drop to-dos into the order").
- Reschedule rapide : swipe droit -> When `[VERIFIED 2803582]`.

## 5. Upcoming

```
+______________________________________+
|  [cal] Upcoming                      |
|                                      |
|  Tomorrow                            |  semaine à venir : 7 jours listés, à partir de demain
|    [ ] To-do                         |
|  Wed 18                              |
|    (vide ou ligne d'en-tête seule)   |
|  Thu 19                              |
|  ...                                 |
|  Next week / mois suivants           |  puis regroupement par semaines puis mois
|  December                            |
|    [ ] Planifié le 3                 |
+______________________________________+
```

- "At the top of Upcoming, you'll see the next seven days listed separately, starting with tomorrow" `[VERIFIED 4001304]`.
- Contient to-dos planifiés (start date future), répétitions à venir, deadlines, événements calendrier `[VERIFIED features]` ("scheduled to-dos, repeating to-dos, deadlines, and calendar events").
- Reschedule par drag and drop sur un autre jour `[VERIFIED 4001304]`.
- Au-delà de 7 jours : groupes par semaine puis par mois `[FROM-MEMORY]` `[UNSURE]` (granularité exacte).
- Les projets avec date de début future y sont aussi listés `[VERIFIED 4001304]`.
- Deadline : le to-do apparaît dans Upcoming au jour de sa deadline, avec drapeau `[VERIFIED 4001304]`.

## 6. Anytime

- Titre "Anytime" icône teal.
- Ordre : to-dos libres (sans parent) en haut, puis groupés sous leur parent direct (projet ou area) ; une liste sans to-do actif n'apparaît pas `[VERIFIED 4001304]`.
- Les to-dos de Today ont l'étoile jaune `[VERIFIED 4001304]`.
- Contient aussi to-dos avec deadline (actifs) `[VERIFIED 4001304]`.

## 7. Someday

- Titre "Someday" icône boîte.
- Contenu estompé (visuellement en retrait) `[VERIFIED 4001304]`.
- Projets Someday cachés de Home et sidebar `[VERIFIED 4001304]`.
- Mêmes regroupements que Anytime `[FROM-MEMORY]`.

## 8. Logbook

- Titre "Logbook" icône livre/coche verte.
- Groupes par période (Today, Yesterday, mois/années) `[FROM-MEMORY]` `[UNSURE]`.
- Items complétés ou annulés (annulé = croix) `[VERIFIED 4001304]` ("completed or cancelled").
- Conservation illimitée ; suppression en masse via sélection (Cmd A sur clavier externe ou multi-select) ; suppression iOS définitive `[VERIFIED 4001304]`.
- Projets complétés listés aussi ; "Logged Projects" via Quick Find `[VERIFIED 2803584]`.
- Auto-archive : "Move completed to Logbook" immédiat ou différé (Mac `Shift-Cmd-Y`) `[VERIFIED https://culturedcode.com/things/support/articles/2785159/]`.

## 9. Area view

```
+______________________________________+
| <                            [...]   |
|  [area] Work                         |  titre bold + icône Area
|  Notes de l'area (optionnel)         |  (zone texte Markdown)
|  [tag]                               |
|                                      |
|  [ ] To-do libre de l'area           |  to-dos directement dans l'area
|  [ ] Autre                           |
|  ____                                |
|  [pie] Project A      (n restants)   |  projets de l'area (pies)
|  [pie] Project B                     |
+______________________________________+
```

- Une Area contient to-dos libres et projets `[FROM-MEMORY]`.
- "More > Add Tags" pour tagguer l'area ; les items héritent du tag `[VERIFIED 2803581]`.
- Pas de checkbox sur une Area (jamais "complétée") `[FROM-MEMORY]`.
- Quand on glisse Magic Plus dans Home, un nouveau projet se crée dans l'Area `[VERIFIED 2803582]`.
- Une Area déplacée entraîne ses projets `[VERIFIED 2803582]`.

## 10. Project view

```
+______________________________________+
| <                            [...]   |
|  [pie] Titre du projet               |  titre bold 28-34 pt, pie à gauche
|  Notes du projet (Markdown)          |
|  [tag]  [flag deadline]  [when]      |
|                                      |
|  [ ] To-do sans heading              |
|  [ ] To-do                           |
|                                      |
|  Heading 1  ________________________ |  heading : texte accent + ligne
|  [ ] To-do sous heading              |
|  [ ] To-do                           |
|                                      |
|  Heading 2  ________________________ |
|  [ ] ...                             |
|                                      |
|  (to-dos complétés : lien "x completed"?)  [UNSURE]
+______________________________________+
```

- Header : pie de progression + titre ; notes ; deadline/when ; tags. `[FROM-MEMORY]`.
- Menu "..." du projet : Add Tags, Repeat, Share, Move?, Complete Project, Delete `[VERIFIED 2803564]` (Repeat), `[VERIFIED 2803581]` (Add Tags), `[VERIFIED 2803566]` (Share) ; le reste `[UNSURE]`.
- Headings : rangent les to-dos ; archivables avec leur contenu ; glissables avec leur groupe `[VERIFIED features]` ("archive your heading and all of its to-dos"). Un heading a son propre menu (Archive, Move, Delete...) `[FROM-MEMORY]`.
- Dans un projet, les to-dos inactifs (start date future) sont placés sous les actifs `[VERIFIED 4001304]`.
- Un to-do du projet qui est dans Today a l'étoile `[VERIFIED 4001304]`.
- Création d'un heading : glisser le Magic Plus à l'extrême gauche de l'écran `[VERIFIED 2803582]`.
- Complétion d'un projet : voir 06.
- Projet avec deadline : drapeau et jours restants à droite du titre `[FROM-MEMORY]`.

## 11. To-do inline editor / to-do ouvert

Un tap sur un to-do l'ouvre en place : carte blanche avec ombre, le clavier apparaît pour le titre `[VERIFIED features]`.

```
+______________________________________+
|  +__________________________________+|
|  | [ ] Titre du to-do               ||  champ titre, 17 pt
|  |     Notes                        ||  zone note (Markdown), placeholder "Notes"
|  |                                  ||
|  |     [ ] Item de checklist   ===  ||  grip à droite pour réordonner
|  |     [ ] Autre item          ===  ||
|  |                                  ||
|  |  [tag] [tag]                     ||  pills des tags
|  |  [star] Today          flag 5 d  ||  When à gauche, Deadline à droite
|  |                                  ||
|  |  (cal) (tag) (list) (flag)  ...  ||  barre d'icônes : When, Tags, Checklist, Deadline, "..."
|  +__________________________________+|
+______________________________________+
|  clavier iOS                    (v)  |  bouton pour fermer le clavier
+______________________________________+
```

Détails `[FROM-MEMORY]` sauf mention :

- Les champs vides sont "rangés dans un coin" : seule la rangée d'icônes (When/calendar, Tags, Checklist, Deadline/flag) est visible en bas de la carte tant qu'ils ne sont pas remplis `[VERIFIED features]`.
- Champs : Title, Notes, Tags, When, Deadline, Checklist, plus menu "..." (More) en bas à droite avec : Repeat, Move, Share, Find in Text, Manage Tags, Duplicate, Delete `[VERIFIED 2803564]` (More > Repeat), `[VERIFIED 4438545]` ("..." > Find in Text), `[VERIFIED 2803581]` (Manage Tags), `[VERIFIED 2803566]` (More > Share). Ordre `[UNSURE]`.
- Bouton en haut à droite pour fermer le clavier `[VERIFIED 2803564]` ("Tap the button in the upper right to dismiss the keyboard").
- Barre du bas : More à gauche ? Les articles disent "More > Repeat at the bottom of your screen" `[VERIFIED 2803564]` donc More est en barre du bas.
- Format dans les notes : appui dans la zone note -> popover "Format" avec styles Markdown, ">" pour plus d'options `[VERIFIED 4438545]`.
- Les notes acceptent Markdown : `**gras**`, `*italique*`, `::surbrillance::`, titres `#`, listes `-`, `1.`, `- [ ]` tâches, liens `[...]()`, code `` ` `` `[VERIFIED 2785159]`. Les liens sont affichés dans leur forme complète `[VERIFIED 4438545]`.
- Pas d'image/pièce jointe `[VERIFIED 4438545]`.
- Checklist : tap sur le cercle = complète ; swipe gauche = supprime ; grip à droite (trois barres) = réordonne en long press `[VERIFIED 2803582]`. Coller une liste à puces la convertit en checklist `[VERIFIED features]`. Mac : `Shift-Cmd-C` nouvelle checklist `[VERIFIED 2785159]`.
- Repeat dans "More" ; à l'ouverture d'un template : flèche bleue `[VERIFIED 2803564]`.
- Un copy d'un répétitif affiche "This is a copy of a repeating to-do" cliquable vers le template `[VERIFIED 2803564]`.
- Fermeture : tap hors carte ou bouton Done ; sauvegarde automatique `[FROM-MEMORY]`.
- Création : le tout nouveau to-do s'ouvre directement en édition avec clavier `[FROM-MEMORY]`.
- Dans l'Inbox via Magic Plus, le Quick Entry popover permet de choisir une autre liste en tapant "Inbox" `[VERIFIED 2803582]` ("Tap Inbox in the Quick Entry popover to file your to-do in another list").

## 12. When picker (Jump Start)

Ouvert via l'icône calendrier du to-do, un tap sur la date affichée, un swipe droit sur la ligne, ou `Cmd-S` clavier `[VERIFIED 2803579]`. Sur iPhone : feuille du bas (popover compact) `[FROM-MEMORY]`.

```
+______________________________________+
|  (pull-down : champ texte NL)        |  "Pull down in the date picker to type"  [VERIFIED 2803582]
|                                      |
|  [star]  Today                       |
|  [moon]  This Evening                |
|  [box]   Someday                     |
|                                      |
|  < Novembre 2026 >                   |  grille calendrier mensuelle
|  L  M  M  J  V  S  D                 |  (semaine commence selon région)
|  ..  ..  16 17 18 ..                 |  aujourd'hui entouré/étoile
|                                      |
|  [+] Add Reminder                    |  -> time picker (barrel) puis Set
|  [x] Clear                           |
+______________________________________+
```

- Options : Today, This Evening, Someday ; clic sur date de la grille = Upcoming ; Clear = enlève toute planification et met en Anytime `[VERIFIED 2803579]`.
- Add Reminder : "Tap -> + Add Reminder, set a reminder time from the time picker, tap Set -> Done" `[VERIFIED https://culturedcode.com/things/support/articles/2803585/]`. Le sélecteur d'heure est un "barrel" (roue) `[VERIFIED features]`.
- Natural language : pull-down dans le picker pour taper ("tues 8am") puis touche Return bleue `[VERIFIED https://culturedcode.com/things/support/articles/9780167/]`. Exemples dans 06.
- Snooze de notification : 15 min, 1 h, 3 h, jusqu'au lendemain `[VERIFIED 2803585]`.
- Plus de contenu : après sélection la popover se ferme (l'article dit qu'elle peut se refermer quand on pose date + reminder, d'où l'usage du NL) `[VERIFIED 2803585]`.

## 13. Deadline picker

- Bouton drapeau dans la carte ouverte. Popover calendrier avec bouton Clear `[VERIFIED 2803579]`.
- Pas de reminder pour une deadline `[VERIFIED 2803585]`.
- NL dans le picker Deadline iPhone nécessite un clavier matériel `[VERIFIED 9780167]` (limite d'origine ; à ne pas reproduire forcément `[PROPOSAL]`).

## 14. Tag picker

- Popover/feuille avec liste des tags (cases à cocher), "New Tag" en tête, bouton Done `[VERIFIED 2803581]`.
- Pull-down pour chercher un tag `[VERIFIED 2803582]`.
- "Manage Tags" : créer, supprimer, renommer, grouper (bouton bleu à droite du tag > Group), réordonner par long press `[VERIFIED 2803581]`.
- Multi-select : barre du bas More > Set Tags `[VERIFIED 2803581]`.
- Tags héritables depuis liste `[VERIFIED 2803581]`.

## 15. Move sheet

- Ouverte par More > Move (to-do/liste sélectionnée) `[FROM-MEMORY]`.
- Barre de recherche en tête (filtre tapé) `[VERIFIED features]` ("Quick Move ... Type to filter down the list").
- Liste : Inbox, Areas et projets (nesting visuel), option "No Project" / "No Area"... `[VERIFIED 2803579]` ("Move > No Project").
- Peut aussi cibler un heading dans un projet `[FROM-MEMORY]` ; Mac Move dialog permet d'ajouter dans projets inactifs `[VERIFIED 4001304]`.

## 16. Quick Find (search)

- Déclenchée par pull-down sur une liste `[VERIFIED 2803584]`. Sur iPad/Duo toujours en haut de la sidebar.
- Premier niveau : noms de to-dos, projets, areas, tags, listes par défaut, headings `[VERIFIED 2803582]`.
- "Continue Search" en bas étend à notes, checklists, Logbook `[VERIFIED 2803584]`.
- Navigation : taper le nom d'une liste (ex. "tod") puis choisir pour y aller ; fonctionne aussi pour listes spéciales : Tomorrow, Deadlines, Repeating, All Projects, Logged Projects `[VERIFIED 2803584]`.
- Taper un tag donne un filtre app-wide `[VERIFIED features]`.
- Une résultat = ligne avec icône et titre ; tap = aller à l'élément `[FROM-MEMORY]`.

## 17. Settings

Écran accessible depuis Home. Entrées `[FROM-MEMORY]` sauf mention :

- Things Cloud (compte, sync) `[VERIFIED https://culturedcode.com/things/support/articles/2803586/]` (service de sync).
- General : Group Today by project/area `[VERIFIED 4001304]`, badge count, "Add new to-dos to the top/bottom" `[UNSURE]`.
- Appearance : thème Light/Dark/Black, taille du texte Custom `[VERIFIED 8537373]`, widgets appearance `[VERIFIED 2803567]`.
- Calendar Events : interrupteur Show Calendar Events, liste de calendriers, bouton Close en haut à droite `[VERIFIED 2803583]`.
- Notifications / Reminders, Siri AI (beta) `[VERIFIED https://culturedcode.com/things/support/articles/2877019/]`.
- Mail to Things, Shortcuts, About / Help `[FROM-MEMORY]`.
- Taper "Settings" dans Quick Find y mène `[VERIFIED 2803584]` ("Access Settings ... by typing their name").

## 18. Magic Plus

- Bouton `+` bleu, en bas à droite de chaque liste `[FROM-MEMORY]`.
- Tap : nouveau to-do en haut/bas de la liste courante (selon réglage `[UNSURE]`), mode édition ; dans Today -> start date Today ; dans Upcoming -> jour ; dans Inbox -> Inbox ; dans un projet -> dans le projet `[FROM-MEMORY]`.
- Drag : "Drag the Magic Plus Button anywhere ... your new to-do will be inserted where you drop it" `[VERIFIED 2803582]` ; dans Today à l'endroit voulu, sous un heading, dans le bon jour d'Upcoming `[VERIFIED features]`.
- Drag vers cible Inbox en bas à gauche : crée dans l'Inbox quelle que soit la liste `[VERIFIED 2803582]`.
- Drag vers le bord gauche dans un projet : crée un heading à l'endroit `[VERIFIED 2803582]`.
- Drag dans Home : crée un projet dans l'Area sur laquelle on dépose `[VERIFIED 2803582]`.
- Long press prolongé -> même effet que drag `[UNSURE]`.
- Dans une liste filtrée par tag, le nouveau to-do reçoit le tag `[UNSURE]`.

## 19. Mode multi-sélection

- Entrée : swipe gauche sur un to-do (le sélectionne), ou tap sur d'autres. "swiping a to-do not only shows you the actions you can perform, but it also immediately enters multi-select mode" `[VERIFIED features]`.
- Cercles de sélection à droite ; glisser le doigt le long du bord droit sélectionne un groupe `[VERIFIED 2803582]`.
- Barre du bas : actions (When, Move, Tags (More > Set Tags), Duplicate, Delete...) `[VERIFIED 2803581]` (More > Set Tags) ; liste exacte `[UNSURE]`.
- Long press sur un sélectionné : drag de toute la sélection `[VERIFIED 2803582]`.
- Sélection d'Areas/projets : swipe gauche sur un projet ou une area `[VERIFIED 2803582]`.
- Sortie : bouton Done ou tap vide `[UNSURE]`.

## 20. Share extension / ajout depuis d'autres apps

- Share sheet iOS : "Add to Things" (extension) ; crée un to-do avec titre, notes (URL) et choix de la liste ; Quick Entry style popover `[FROM-MEMORY]`.
- Partage sortant : More > Share sur to-do ou liste, texte brut ; notes/tags des enfants non inclus `[VERIFIED https://culturedcode.com/things/support/articles/2803566/]`.
- Mail to Things (adresse personnelle) `[VERIFIED https://culturedcode.com/things/support/articles/1059358/]` (existence).
- Siri / Shortcuts / URL scheme : voir sources `[VERIFIED 2877019]`.
- Widgets : Home/Lock Screen (Today, Upcoming, listes perso, tags), bouton + vers Inbox, case à cocher interactive `[VERIFIED 2803567]`.
- Apple Watch : Today uniquement, avec checklists et headings `[VERIFIED https://culturedcode.com/things/support/articles/2157909/]`.

## Récapitulatif [UNSURE]

Position bouton Settings ; compteurs Home ; contenu exact des menus "..." (liste, projet, to-do) ; barre d'actions multi-select ; regroupement de Logbook et d'Upcoming après 7 jours ; position (haut/bas) des nouveaux to-dos ; tags sur Magic Plus dans liste filtrée ; icône notes sur ligne ; sortie du mode multi-select.
