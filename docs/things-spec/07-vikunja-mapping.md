# 07 - Correspondance Things vers Vikunja v2

Tout ce fichier est du `[PROPOSAL]` (conception de notre fork) appuyé sur les faits du modèle Vikunja. Faits Vikunja : `[VERIFIED docs/vikunja-api-inventory.md]` (repo mDone, API v2, serveur >= 2.5.0) ou `[FROM-MEMORY]` (modèle de données Vikunja connu : champs `start_date`, `end_date`, `due_date`, `reminders`, `repeat_after`, `repeat_mode`, `priority`, `position`, `related_tasks`, `labels`, `parent_project_id`, `done_at`). Valider chaque champ sur `/api/v2/openapi.json` avant de figer `[UNSURE]`.

Rappel Things : voir 06 pour la sémantique à reproduire.

## 1. Tableau de correspondance

| Concept Things | Vikunja | Écart / convention |
|-|-|-|
| To-do | Task | direct |
| Titre / Notes | `title` / `description` (Markdown, ou HTML selon le client) | Vikunja web écrit du HTML dans `description` ; notre app écrira du Markdown : voir §4 |
| Inbox | projet "Inbox" (le projet par défaut de l'utilisateur, `default_project_id` du profil) `[FROM-MEMORY]` | convention : Inbox = ce projet ; un to-do sort de l'Inbox quand on le déplace dans un autre projet ou qu'on lui donne un When |
| Area | projet de premier niveau marqué comme Area | pas de type "Area" dans Vikunja : voir §2 |
| Project | projet enfant d'une Area, ou projet racine (= projet sans area) | direct via `parent_project_id` |
| Sous-projet de projet | non existant dans Things | on ignore (profondeur max 2 : Area > Project) ; les projets Vikunja plus profonds s'affichent à plat `[PROPOSAL]` |
| Heading | bucket d'une vue Kanban dédiée | voir §3 |
| Checklist item | sous-tâche (relation `subtask`) | voir §5 |
| When = date | `start_date` (date locale du jour de début) | voir §6 |
| When = Today | `start_date` = aujourd'hui ou avant (mais voir §6) | Today est calculé, pas stocké |
| When = This Evening | `start_date` + label réservé `things:evening` | voir §7 |
| When = Someday | label réservé `things:someday` | voir §8 |
| When = Anytime | `start_date` nul, pas de label Someday, dans un projet ou Area | calculé |
| Reminder | `reminders[]` absolu (`reminder` datetime) | un seul reminder par to-do côté UI, comme Things |
| Deadline | `due_date` | direct |
| Repeat | `repeat_after` (secondes) + `repeat_mode` | écarts importants : voir §9 |
| Tag | Label | pas de couleur côté Things ; ignorer `hex_color` à l'affichage `[PROPOSAL]` |
| Tag imbriqué | aucune hiérarchie de labels | convention de nom "Parent/Enfant" `[PROPOSAL]` `[UNSURE]` |
| Cancelled | `done = true` + label `things:cancelled` | voir §10 |
| Logbook | `done = true` triés par `done_at` desc | direct |
| Trash | non (2.8.0 a une corbeille serveur : `/tasks/deleted`, `/tasks/{id}/restore`) `[VERIFIED docs/vikunja-api-inventory.md]` | utiliser la corbeille serveur si version >= 2.8 |
| Priority | `priority` 0-5 | n'existe pas dans Things : ne pas afficher ; la préserver à l'écriture (PATCH n'envoie que les champs modifiés) `[VERIFIED docs/vikunja-api-inventory.md]` |
| Order dans une liste | `position` par vue (`PUT /tasks/{id}/position`, body `{position, project_view_id}`) `[VERIFIED docs/vikunja-api-inventory.md]` | voir §11 |
| Project progress pie | calculé côté client (done / total) | pas de champ serveur |
| Project notes | `description` du projet | direct |
| Project deadline | pas de `due_date` projet | gap : voir §12 |
| Project start date / Someday | pas de champ | gap : voir §12 |
| Area notes / tags | `description` du projet ; tags : pas de labels sur projets | gap : voir §12 |
| Archive (Logbook projet) | `is_archived = true` ou projet marqué done via label ? | voir §12 |
| Calendar events | local EventKit, pas Vikunja | comme Things : lecture locale, aucune écriture `[VERIFIED 2803583]` |

## 2. Areas

Options évaluées :

1. Projet racine dont le titre est le nom de l'Area, avec un marqueur : description commençant par une ligne `things:area` (ligne simple), ou `hex_color` réservé, ou présence d'un label "things:area" (les labels ne s'appliquent pas aux projets : à exclure).
2. Projet racine "Areas" qui contient les Areas comme enfants. Rejeté : ajoute un niveau parasite.
3. Convention de structure : tout projet qui a des enfants = Area. Un projet sans enfant et sans parent = projet libre. Ambigu pour une Area vide.

Recommandation : option 1 avec marqueur dans `description` (première ligne `things:area`) car c'est le seul champ libre, qui survit à l'API et n'est pas visible dans le web Vikunja si placé dans un commentaire HTML. Une Area n'a pas de to-dos "propres" côté Vikunja, mais Things permet des to-dos libres dans une Area : ils vivent comme tâches directes de ce projet Area `[PROPOSAL]`. Risque : si l'Area est aussi un projet Vikunja normal, la web app permet d'y ajouter des tâches (ce qui est cohérent).

Tradeoff : sans marqueur, un projet racine ordinaire qu'on crée dans la web app apparaît comme "projet libre" dans notre app (acceptable).

## 3. Headings

Deux candidats :

| Option | + | - |
|-|-|-|
| A. Buckets d'une vue Kanban `things-headings` | structure native, position par bucket, API présente (`/projects/{id}/views/{view}/buckets/tasks`, move card `PUT .../buckets/{bucket}/tasks`) `[VERIFIED docs/vikunja-api-inventory.md]`, visible dans la web app | une tâche = un bucket ; doit créer et maintenir une vue dédiée ; paging des buckets `[VERIFIED docs/vikunja-api-inventory.md]` ; ordre "to-dos hors heading" = bucket par défaut |
| B. tâche factice avec label `things:heading` | simple, ordre unifié dans la vue liste | pollue les compteurs, apparaît dans la web app comme tâche, risque de complétion par erreur |
| C. préfixe dans `description` de la tâche | aucune structure serveur | fragile |

Recommandation : A. Un projet Things avec headings reçoit une vue Kanban nommée `things-headings` créée au besoin ; le premier bucket (défaut) = "to-dos sans heading" (sans titre affiché) ; chaque autre bucket = un heading. Archiver un heading = marquer le bucket (nom préfixé `[archived]`) ou terminer ses tâches `[UNSURE]`. Si le projet n'a pas de headings, pas de vue supplémentaire à créer.

Ordre : le `position` des tâches dans la vue `things-headings` donne l'ordre intra-heading ; l'ordre des buckets donne l'ordre des headings `[UNSURE]` (champ `position` de bucket à vérifier).

## 4. Notes

Vikunja stocke `description` en HTML (éditeur Tiptap) dans le web ; le Markdown de Things n'y est pas natif. Choix : notre app stocke du Markdown brut ; la web app l'affichera comme texte. Si l'utilisateur édite aussi sur le web, la description devient HTML : l'app doit détecter (présence de balises) et afficher de façon tolérante ou convertir HTML vers Markdown `[PROPOSAL]` `[UNSURE]` (rendu exact de l'éditeur web).

## 5. Checklists

| Option | + | - |
|-|-|-|
| A. sous-tâches (`related_tasks.subtask`, `POST /tasks/{id}/relations`) `[VERIFIED docs/vikunja-api-inventory.md]` | structure typée, cochables, ordre par `position` | chaque item est une vraie tâche : apparaît dans toutes listes si on n'exclut pas ; doit filtrer les tâches qui ont une relation `parenttask` hors des listes ; un appel par item |
| B. cases Markdown `- [ ]` dans `description` | un seul PATCH, atomique, aucun filtrage | ne se synchronise pas proprement avec les sous-tâches Vikunja ; parsing à maintenir ; confusion avec notes Markdown |

Recommandation : A, avec filtre `expand=subtasks` pour ne ramener que les tâches de premier niveau `[VERIFIED docs/vikunja-api-inventory.md]`, et masquage de toute tâche qui a un parent. Les sous-tâches héritent du projet du parent. Things interdit dates/tags sur les items de checklist : ne pas les exposer `[VERIFIED features]` (les items sont de simples étapes).

Si latence ou volume posent problème : repli B `[PROPOSAL]`.

## 6. When = start_date, et "Today"

Vikunja distingue `start_date`, `end_date`, `due_date`, tous datetimes. Mappage :

- `start_date` = jour de début. Représentation : datetime à 12:00 locale du jour choisi, pour qu'un décalage de fuseau de moins de 12 h ne change pas le jour `[PROPOSAL]` `[UNSURE]` (alternative : 00:00 UTC + convention date flottante). Le jour est relu en fuseau local.
- `end_date` : inutilisé par l'UI Things, à préserver tel quel.
- `due_date` = Deadline, même représentation midi.
- Today = tâches non faites avec `start_date <= fin de journée` OU `due_date <= fin de journée` (la deadline atteinte), hors Someday. Filtre Vikunja : `done = false && (start_date <= now || due_date <= now)` (syntaxe DSL à valider `[UNSURE]`) ; le plus sûr : télécharger et filtrer côté client `[PROPOSAL]`.
- Upcoming = `start_date > fin de journée` ou `due_date > fin de journée` sans start date ; groupes calculés côté client.
- Anytime = `start_date` nul, ni Someday ni Inbox.
- Un to-do dans Today dont `start_date` est passé depuis plusieurs jours reste en Today (c'est le comportement Things aussi `[FROM-MEMORY]`).
- Reminder : `reminders = [{reminder: <datetime absolu>}]` sur la tâche ; quand on définit un reminder, `start_date` du jour du reminder est posé aussi `[PROPOSAL]`. Un seul reminder maximum côté UI. Les `relative_to` de Vikunja (par rapport à due/start/end) ne sont pas utilisés.
- Les reminders "début à 9:00" mettent le jour dans `start_date` et l'heure dans le reminder, pas dans `start_date`.

## 7. This Evening

Aucun équivalent. Options :

| Option | + | - |
|-|-|-|
| A. label réservé `things:evening` | simple, lisible par les autres clients ; survit aux changements de date | visible dans les labels de la web app ; doit être caché dans notre UI ; nettoyage au passage de la journée |
| B. heure sentinelle (ex. `start_date` à 18:00 local) | pas de label | entre en conflit avec les vrais horaires ; 12:00 est déjà utilisé comme "journée" ; fragile |
| C. champ local uniquement | aucune pollution | perdu à la synchro ; non cohérent multi-appareils |

Recommandation : A. Règle : `things:evening` n'a de sens que si `start_date` est posée (jour). Effacer le When retire le label. Today affiche en section This Evening les tâches Today portant ce label. À minuit, le label reste valable pour un jour futur (cf. 06 §4) `[UNSURE]`.

## 8. Someday

- Label réservé `things:someday` (A) ; une tâche Someday n'a pas de `start_date` (sinon contradiction : le label gagne et on ignore `start_date`).
- Variante B : projet "Someday" dédié : perd la place dans l'Area/projet d'origine. Rejetée.
- Projet Someday : voir §12.

## 9. Répétition

Champs Vikunja : `repeat_after` (secondes) et `repeat_mode` : 0 = intervalle fixe depuis la `due_date`, 1 = mensuel (même jour du mois), 2 = depuis la date de complétion (`from current date`) `[FROM-MEMORY]` `[UNSURE]` (à valider). Vikunja ne crée pas de copie : à la complétion, la même tâche est remise à `done = false` avec dates avancées (le PATCH `done: true` "rolls the due date forward" `[VERIFIED docs/vikunja-api-inventory.md]`).

| Fonction Things | Faisable ? |
|-|-|
| After completion | oui : `repeat_mode = 2` |
| Regular daily/weekly | oui : `repeat_mode = 0`, `repeat_after = 86400*n` ou `604800*n` |
| Regular monthly | oui : `repeat_mode = 1` (1 mois) ; pas "tous les 2 mois" `[UNSURE]` |
| Yearly | `repeat_after = 31536000` approximatif ; dérive sur années bissextiles |
| Jours précis (lun-ven, 3e mardi) | non : gap |
| Date de fin | non : gap (peut se gérer côté app en arrêtant la répétition) |
| Template + copies | non : une seule tâche ; la notion de "copie" disparaît ; la liste Repeating = tâches avec `repeat_after > 0` |
| Pause / Resume | non : simuler en mettant `repeat_after = 0` et en sauvegardant l'ancien dans un label/description `[UNSURE]` |
| Deadlines "days earlier" | partiellement : écart `start_date` vs `due_date` conservé à l'avancement `[UNSURE]` |

Recommandation : exposer d'abord After completion + Daily/Weekly/Monthly/Yearly simples ; masquer le reste ; documenter les écarts dans l'UI. Toute règle plus riche = convention app-side dans `description` (bloc `things:repeat {...}`) `[PROPOSAL]` non recommandé pour v1.

## 10. Cancelled

Vikunja n'a pas de statut annulé. Convention : `done = true` + label `things:cancelled`. Affichage Logbook : croix au lieu de coche. Retirer le label si on "uncancel".

## 11. Ordre (position)

- Vikunja tient une `position` par (tâche, vue). Chaque projet a des vues (liste, Kanban...) `[VERIFIED docs/vikunja-api-inventory.md]` (`/projects/{id}/views`).
- Listes Things "intrinsèques" au projet (le projet lui-même, une Area) : utiliser la vue Liste du projet pour `position`.
- Listes transverses (Today, Upcoming, Anytime, Someday, Inbox) : Things stocke un ordre global par liste. Vikunja n'a pas de vue pour cela. Options : (1) utiliser la `position` de la vue Liste du projet d'origine (l'ordre de Today suivra l'ordre dans leur projet respectif : acceptable pour un MVP), (2) créer des "saved filters" Vikunja (pseudo-projets, ids négatifs) `[VERIFIED docs/vikunja-api-inventory.md]` pour Today/Anytime et utiliser leurs vues pour la position `[UNSURE]` (positions de saved filters), (3) ordre local seulement (non synchronisé). Recommandation : (1) pour v1 ; Inbox = projet Inbox donc position native.

## 12. Écarts non résolus pour projets et areas

| Besoin Things | Contournement |
|-|-|
| Tags sur projet/area | label non applicable à un projet : stocker la liste de tags dans `description` en première ligne `things:tags a,b` `[PROPOSAL]` `[UNSURE]` ; hérités à l'exécution par l'app |
| Deadline / start date de projet | idem : `things:deadline YYYY-MM-DD`, `things:start YYYY-MM-DD` en tête de description ; ou ignorer |
| Projet Someday | `things:someday` dans la description du projet |
| Projet complété (Logbook) | `is_archived = true` (le serveur le sort des listes) + date dans `things:completed` ; ou terminer toutes ses tâches. `GET /projects` avec `is_archived=true` renvoie actifs et archivés `[VERIFIED docs/vikunja-api-inventory.md]` |
| Projet annulé | archivé + `things:cancelled` |
| Projet répétitif | gap : ne pas supporter en v1 |
| Pie | calculé : done / total de ses tâches (hors sous-tâches) |

Cette dépendance au champ `description` du projet doit être encapsulée dans un seul module (`ProjectMetaCodec`) qui lit et écrit un bloc de lignes en tête et préserve le reste du texte.

## 13. Tags (labels)

- Tag Things = Label Vikunja. API : `GET/POST /labels`, `POST/DELETE /tasks/{id}/labels` `[VERIFIED docs/vikunja-api-inventory.md]`.
- Tags réservés app-side : préfixe `things:` (evening, someday, cancelled) : à masquer de tous les écrans de tags, du filtre et de la recherche.
- Raccourcis de tags par lettre (Mac) : stockage local.
- Ordre des tags : local (Vikunja n'a pas d'ordre de labels).
- Tags hérités par la liste : calcul app-side, pas d'écriture sur les tâches `[VERIFIED 2803581]` (ne pas matérialiser).

## 14. Quick Entry / Inbox / Share

- Création : `POST /projects/{inboxId}/tasks` `[VERIFIED docs/vikunja-api-inventory.md]`.
- Création directe dans un projet : `POST /projects/{id}/tasks`.
- Magic Plus dans une liste temporelle : crée dans le projet Inbox (ou parent contextuel) puis `PATCH` avec `start_date` si Today/Upcoming.
- Déplacement : `PATCH` du `project_id`.

## 15. Mises à jour atomiques

Toujours `PATCH /tasks/{id}` avec les seuls champs modifiés (mDone le fait déjà : #292) `[VERIFIED docs/vikunja-api-inventory.md]`. Effacer une date = `null`. Les tableaux (`labels`, `reminders`) remplacent la liste entière : lors d'un changement d'un seul label réservé, relire les labels pour ne pas écraser `[VERIFIED docs/vikunja-api-inventory.md]` (labels passent par `/tasks/{id}/labels` plutôt que PATCH).

## 16. Récapitulatif des conventions réservées

| Marqueur | Emplacement | Sens |
|-|-|-|
| `things:evening` | label de tâche | This Evening |
| `things:someday` | label de tâche | Someday |
| `things:cancelled` | label de tâche | annulée (avec done) |
| `things:area` | première ligne de `description` de projet | cet élément est une Area |
| `things:tags`, `things:deadline`, `things:start`, `things:someday`, `things:completed`, `things:cancelled` | lignes en tête de `description` de projet | métadonnées de projet |
| vue `things-headings` | vue Kanban du projet | headings = buckets |
| projet Inbox | `default_project_id` du profil, sinon projet nommé Inbox | Inbox |
| `start_date` / `due_date` à 12:00 locale | tâche | dates plein jour |

## Récapitulatif [UNSURE]

Valeurs exactes de `repeat_mode` ; formats de filtre pour Today ; ordre des buckets (`position`) ; position dans saved filters ; HTML vs Markdown dans `description` ; mois/années non standard ; représentation midi des dates ; hiérarchie de tags ; existence et nom du projet Inbox par défaut selon la version serveur ; sémantique d'un heading archivé.
