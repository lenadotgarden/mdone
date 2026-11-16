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
