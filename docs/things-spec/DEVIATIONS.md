# Écarts avec la spec Things

Chaque écart est rattaché à la section de la spec concernée. Statut : `TODO` = à faire, `stopgap` = solution provisoire en place.

## Première tranche iPhone (Home, listes, projet)

Code écrit sans compilateur, à valider par la CI.

| Spec | Écart | Statut |
|-|-|-|
| 02 section 11 (to-do ouvert en place) | Un tap sur une ligne ouvre l'existant `TaskDetailSheet` en feuille. Les écrans de `Features/Things` référencent donc `Features/TaskDetail` (autorisé pour ce stopgap, pas d'`import`, même module). | stopgap |
| 03 (Magic Plus, drag) | Le bouton `ThingsMagicPlusButton` ne gère que le tap : une ligne vide s'ouvre en haut de la liste. Pas de drag, pas de position d'insertion, pas de cible Inbox, pas de création de heading ni de projet dans une Area depuis Home. | TODO |
| 03 (swipe gauche) | La spec veut la multi-sélection avec barre d'actions. Le swipe gauche propose Supprimer (suppression définitive). | TODO |
| 03 (swipe droit) | Le menu When propose Today, This Evening, Tomorrow, Someday, Clear dans une `confirmationDialog`. Pas de calendrier ni de Add Reminder. | TODO |
| 02 section 10 (headings) | `ThingsProjectScreen` est une liste plate. Les headings demandent l'id de la vue `things-headings`, que `AppState.fetchBuckets` ne lit pas (il lit la vue Kanban). `ThingsHeadingMapping` est prêt. Pas de notes, tags ni deadline de projet non plus. | TODO |
| 02 section 9 (Area) | Une Area affiche ses to-dos directs puis ses projets sous forme de lignes. | stopgap |
| 06 section 16 (création depuis une liste) | Today : startDate à 12:00 aujourd'hui. This Evening et Someday : label réservé via `AppState.createLabel` si absent, puis création avec `labelIds`. Upcoming : demain. Anytime : premier projet racine qui n'est pas l'Inbox (un to-do de l'Inbox sans When est dans l'Inbox). Création en deux appels (`createTask` puis `updateTask` pour la startDate) car `createTask` n'accepte pas de startDate : le to-do passe brièvement par l'Inbox. | stopgap |
| 02 section 1 (Inbox) | Le projet Inbox est `AppState.defaultProject` (préférence de l'utilisateur, sinon projet nommé "Inbox", sinon le premier projet). | stopgap |
| 02 section 1 (compteurs) | Badges pour Inbox et Today seulement, masqués à zéro. Today n'est pas colorée quand il y a des retards. | TODO |
| 02 section 1 (Quick Find) | Une barre `searchable` filtre les titres des to-dos ouverts. Pas de Quick Find complet (listes, tags, projets, pull-down). | stopgap |
| 02 section 1 (New List) | New Project et New Area créent un projet via `AppState.createProject` (Area = description commençant par `things:area`). Pas d'édition de la liste. Les projets Someday ou à start date future ne sont pas masqués. | stopgap |
| 02 section 2 (ligne) | Pas d'aperçu de note (icône seulement) ni d'heure de rappel. | TODO |
| 02 section 4 (Today) | Pas de section d'événements du calendrier. | TODO |
| 02 section 8 (Logbook) | Groupes par jour seulement (Today, Yesterday, date), pas de regroupement par mois ni de projets complétés. Le Logbook dépend de `AppState.tasks` qui doit contenir les to-dos finis. | stopgap |
| 06 section 2 (complétion) | La coche s'affiche à l'instant, la complétion est envoyée après `ThingsMotion.completionRemovalDelay` ; un second tap pendant ce délai annule. Une fermeture de l'écran pendant le délai annule l'envoi sans le faire (le to-do reste ouvert). | stopgap |
| Interface | `@AppStorage("thingsUIEnabled")` (vrai par défaut sur iOS) choisit `ThingsRootView` ou `MainTabView`. Réglage "Interface Things" dans Settings. `ThingsRootView` reprend de `MainTabView` le rafraîchissement, la bannière d'erreur, l'alerte de sync, le focus plein écran et l'undo par secousse, mais pas la cloche de notifications ni les raccourcis clavier. macOS : shell inchangé. | stopgap |

## Première tranche Mac (fenêtre, sidebar, listes, éditeur, commandes)

Code écrit sans compilateur, à valider par la CI macOS puis sur un Mac. Fichiers dans `mDone/Platform/macOS/Things*`, table des raccourcis et moteur de Quick Find dans `mDone/Features/Things/` (purs, testés).

| Spec | Écart | Statut |
|-|-|-|
| Interface | `@AppStorage("thingsUIEnabled")` (vrai par défaut) choisit `ThingsMacRootView` ou `MacContentView` sur Mac aussi. Le réglage "Interface Things" est visible sur Mac. Les tests d'écran Mac (`MacScreenshotTests`) passent `-thingsUIEnabled NO` pour rester sur l'ancienne fenêtre. Avec l'ancienne interface, les menus Things sont grisés mais le menu Fichier perd "New Window" (Cmd N est pris par le groupe `newItem` remplacé). | stopgap |
| 04 section 1 (fenêtre) | Un seul panneau de détail, pas d'inspecteur. Pas de Trash, pas de listes spéciales (Tomorrow, Deadlines, Repeating, All Projects, Logged Projects), pas de nouvelle fenêtre (Ctrl-Cmd-N), pas de Cmd-clic pour ouvrir en fenêtre, pas de masquage de la barre d'outils, pas de Cmd-clic sur un chevron d'Area pour tout replier. Bouton Partager absent. | TODO |
| 04 section 1 (sidebar) | Compteurs pour Inbox et Today seulement, masqués à zéro. Areas repliables par un chevron propre (pas de `DisclosureGroup`, pour garder la sélection de la `List`). Pas de glisser-déposer d'un to-do ou d'un projet sur une ligne. | stopgap |
| 04 section 3 (to-do ouvert) | `ThingsMacTodoEditor` est écrit à neuf (pas de réutilisation de `TaskDetailSheet`, qui est un formulaire). Il enregistre par `AppState.updateTask`. Les notes sont éditées en texte brut (une description HTML du web reste du HTML), sans Markdown. Pas de Repeat, pas de Share, pas de rappel, pas de Find in Text, pas de Opt-Cmd-Return pour ouvrir un lien. Double-clic ou Return ouvre ; Esc ou Cmd-Return enregistre et ferme ; sélectionner une autre ligne ferme (et enregistre). Un clic sur le titre déjà sélectionné n'ouvre pas. | TODO |
| 04 section 4 (popovers) | When : Today, This Evening, Someday, calendrier mois, Clear. Pas de champ langage naturel ni Add Reminder. Deadline : calendrier mois et Clear. Tags : recherche, cases, création. Move : recherche puis Inbox, projets, Areas (pas de headings ni de projets inactifs). | TODO |
| 04 section 5 (Quick Entry) | Panneau flottant `NSPanel` (titre, notes, destination Inbox fixe). Ctrl-Space ouvre par le menu quand l'app est active. Le raccourci global utilise `NSEvent.addGlobalMonitorForEvents`, installé seulement si `AXIsProcessTrusted()` ; le menu "Enable Global Quick Entry..." demande l'accès Accessibilité. Un moniteur global ne peut pas consommer la touche : macOS peut aussi basculer la source de saisie. Pas d'Autofill, pas de tags, When ni Deadline dans le panneau, pas de réglage du raccourci. | stopgap |
| 04 section 6 (Quick Find) | Feuille ouverte par Cmd-F ou la loupe : listes, Areas, projets, tags et titres de to-dos ouverts. Un tag choisi reste dans le champ et montre les to-dos qui le portent. Pas de Type Travel (taper n'importe où), pas de "Continue Search" (notes, checklists, Logbook), pas de Cmd-Return en nouvelle fenêtre, pas de headings dans les résultats. | TODO |
| 04 section 11 / 05 (sélection) | Sélection simple. Flèches, Opt-flèche (premier, dernier), Return (ouvrir), Delete (supprimer, avec confirmation, suppression définitive) sont gérés par le gestionnaire de touches de la liste, pas par le menu (une touche sans Cmd ni Ctrl en menu s'activerait pendant la saisie). Opt-clic sur la case annule. Pas de Shift-flèches, Cmd-A, multi-sélection, ni Espace (nouveau to-do sous la sélection). | TODO |
| 05 (déplacer) | Cmd-Haut/Bas et Opt-Cmd-Haut/Bas (réordonner) : demandent la vue liste du projet (`AppState.moveTask(toPosition:)`) et un tri manuel. Pas de drag and drop. Shift-Cmd-Y ("Move completed to Logbook") : un to-do terminé entre dans le Logbook tout de suite. | TODO |
| 05 (navigation) | Cmd-Gauche (retour) entre en conflit avec le curseur dans les champs de texte : les boutons précédent et suivant de la barre d'outils existent, sans raccourci. Shift-Cmd-O (popover de navigation), Cmd-L, Cmd-Droite, Ctrl-Opt-Cmd-flèches : absents. | TODO |
| 05 (création) | Shift-Cmd-N (New Heading) : l'entrée de menu existe, désactivée, tant que les headings ne sont pas lus (voir plus haut, 02 section 10). Opt-Shift-Cmd-N et Cmd-V multi-lignes : absents. Cmd-D duplique par `createTask` (titre, notes, deadline, priorité, tags, start date), sans la checklist. | TODO |
| 05 (dates, tags) | Cmd-S/T/E/R/O, Ctrl-] et [ (jour, semaine), Shift-Cmd-D, Ctrl-. et , (jour, semaine), Shift-Cmd-T sont faits. Shift-Cmd-R (Repeat) est absent. Cmd-R (Anytime) retire le When (To-do de projet : liste Anytime). Ctrl-Cmd-T (fenêtre Tags), raccourcis de tags, filtre par tag (Ctrl-Esc) : absents. | TODO |
