# 06 - Règles sémantiques de Things

Légende : `[VERIFIED url]` / `[FROM-MEMORY]` / `[UNSURE]`. Sources principales : 4001304 (Today/Upcoming/Anytime/Someday), 2803579 (Scheduling), 2803564 + 3743733 (Repeating), 2803581 (Tags), 2803585 (Reminders), tous sous https://culturedcode.com/things/support/articles/.

## 1. Le modèle : listes par date vs contexte

Deux perspectives sur les to-dos `[VERIFIED 4001304]` :

- Contexte : Areas et Projects créés par l'utilisateur.
- Temps : listes par défaut Inbox, Today (+ This Evening), Upcoming, Anytime, Someday, Logbook. Elles ne se renomment, ne se suppriment ni ne se réordonnent pas `[VERIFIED 2803579]`.

Chaque to-do appartient à exactement une des listes de statut : Inbox, Today (y c. This Evening), Upcoming, Anytime, Someday, ou (une fois fini) Logbook `[VERIFIED 2803579]` ("Every to-do belongs to one of the following lists"). Anytime, Upcoming et Someday sont mutuellement exclusifs `[VERIFIED 4001304]`. Un to-do peut en plus avoir un parent (projet ou area) ou aucun (loose).

## 2. Table de décision : dans quelle liste apparaît un to-do ouvert

Entrées : parent, When (start date / Someday / This Evening), Deadline, répétition.

| Condition | Liste de statut |
|-|-|
| créé sans parent ni date (capture rapide) | Inbox `[VERIFIED 4001304]` |
| déplacé dans une liste (projet/area) ou daté | quitte l'Inbox `[VERIFIED 4001304]` |
| When = Today (start date = aujourd'hui) | Today |
| When = This Evening | Today, section This Evening `[VERIFIED 4001304]` |
| start date future | Upcoming, dormant ; devient Today à la date `[VERIFIED 4001304]` |
| When = Someday | Someday |
| aucune start date, pas Someday, rangé (ou Clear depuis Inbox puis Move > No Project) | Anytime `[VERIFIED 2803579]` |
| deadline = aujourd'hui (ou dépassée) | apparaît aussi dans Today `[VERIFIED 4001304]` ("if the start date, deadline, or repeating rule ... matches today's date") |
| deadline future, pas de start date | reste dans Anytime ; aussi visible dans Upcoming au jour de la deadline `[VERIFIED 4001304]` |
| règle de répétition tombe aujourd'hui | Today `[VERIFIED 4001304]` |
| complété ou annulé | Logbook `[VERIFIED 4001304]` |

Une même ligne peut s'afficher à plusieurs endroits : un to-do de Today est aussi dans Anytime, avec une étoile jaune `[VERIFIED 4001304]`. Un projet reste visible dans son area/sidebar tant qu'il n'est pas inactif.

## 3. When vs Deadline

| | When (start date) | Deadline |
|-|-|-|
| Question | "Quand je commence ?" | "Pour quand dois-je avoir fini ?" |
| Bouton | calendrier | drapeau `[VERIFIED 2803579]` |
| Effet | cache dans Upcoming jusqu'à la date, puis Today | garde l'item actif dans Anytime ; apparaît dans Today le jour J ; décompte "N days left" `[VERIFIED 2803579]` |
| Reminder | oui (heure attachée au When) | non `[VERIFIED 2803585]` |
| NL | oui | oui (Mac) `[VERIFIED 9780167]` |
| Durée | non : "merely indicates the day on which you want to begin work" | n/a |
| Calendrier | n'est pas un agenda `[VERIFIED 2803579]` | |

Une deadline avec plusieurs jours de travail : ajouter une start date avant la deadline `[VERIFIED 2803579]`.

Deadline passée : l'item est en retard, texte rouge "N days ago" `[FROM-MEMORY]` `[UNSURE]` (formulation).

## 4. Today et This Evening

- Today est un filtre global, pas un conteneur `[VERIFIED 4001304]`.
- Ordre manuel (drag) `[VERIFIED 4001304]` ; ce qui est en tête du Today est ce qu'on prend en premier.
- Option de grouper par projet/area dans Settings > General (synchronisée) `[VERIFIED 4001304]`.
- This Evening : section distincte en bas de Today `[VERIFIED 4001304]`. Un to-do This Evening posé aujourd'hui apparaît dans la section ; posé pour un jour futur, il apparaît ce jour-là dans la section du soir `[FROM-MEMORY]` `[UNSURE]`.
- Événements du calendrier : en tête de Today, si activés, calendriers Apple choisis, lecture seule, pas de sync `[VERIFIED 2803583]`.
- À la bascule de minuit : les items qui ont une start date = nouveau jour passent en Today ; les items non faits de la veille restent dans Today (comme "en retard" visuel) `[FROM-MEMORY]` `[UNSURE]`. Un reminder tire une notification à l'heure `[VERIFIED 2803585]`.
- Reminder non persistant, ne sonne pas en boucle `[VERIFIED 2803585]`.
- Snooze : 15 min, 1 h, 3 h, jusqu'au lendemain `[VERIFIED 2803585]`.

## 5. Upcoming

- Sept jours en tête à partir de demain, un bloc par jour `[VERIFIED 4001304]`.
- Contient to-dos datés, répétitions, deadlines, événements `[VERIFIED features]`.
- Le plus lointain regroupé par semaine puis mois `[FROM-MEMORY]` `[UNSURE]`.
- Reschedule par drag and drop `[VERIFIED 4001304]`.
- Un projet avec start date future est caché de la sidebar/Home et revient à la date `[VERIFIED 4001304]`. À l'intérieur d'un projet, les to-dos inactifs sont sous les actifs `[VERIFIED 4001304]`.
- Un to-do avec deadline mais sans start date n'est PAS dormant (reste actif dans Anytime) `[VERIFIED 4001304]`.

## 6. Anytime

- Seulement des to-dos actifs. Aucun blocage `[VERIFIED 4001304]`.
- Ordre : to-dos loose en tête, puis groupés par parent direct ; un parent sans to-do actif est omis `[VERIFIED 4001304]`.
- Les items Today portent l'étoile jaune `[VERIFIED 4001304]`.

## 7. Someday

- Idées non engagées, effet visuel estompé `[VERIFIED 4001304]`.
- Items (et projets) Someday absents d'Anytime et d'Upcoming ; projets Someday cachés de la sidebar `[VERIFIED 4001304]`.
- Revue conseillée tous les quelques mois `[VERIFIED 4001304]`.

## 8. Inbox

- Zone de staging, tout ce qui est capturé (Quick Entry, Mail to Things, share extension, Magic Plus target) `[VERIFIED 4001304]`.
- Titre non requis (peut être vide ou "New To-Do") `[VERIFIED 4001304]` ("It's ok if you don't know the exact title").
- Quand un item sort : section temporaire "x to-dos were moved out of the Inbox", qui disparaît à la navigation `[VERIFIED 4001304]`. On peut y cliquer pour continuer d'éditer l'item `[VERIFIED 4001304]` (phrase partielle dans la source) `[UNSURE]`.

## 9. Logbook et archivage

- Complétés et annulés (cancelled) vont dans le Logbook `[VERIFIED 4001304]`.
- Conservation indéfinie `[VERIFIED 4001304]`.
- Mac : "Move completed to Logbook" (`Shift-Cmd-Y`) force le transfert immédiat `[VERIFIED 2785159]`. Le réglage de fréquence automatique existe (immédiat/quotidien/manuel) `[FROM-MEMORY]` `[UNSURE]`.
- Vider : sélectionner tout (`Cmd-A`) et supprimer. iOS : définitif. Mac : Trash, à vider `[VERIFIED 4001304]`.
- Recherche : le Logbook n'est pas dans le premier niveau de Quick Find ; "Continue Search" l'inclut `[VERIFIED 2803584]`.
- Un heading peut être archivé avec ses to-dos `[VERIFIED features]`.
- Projet complété : va au Logbook ; "Logged Projects" via Quick Find `[VERIFIED 2803584]`.

## 10. Projets

- Éléments : titre, notes, tags, deadline/when, headings, to-dos, progression (pie) `[VERIFIED features]`.
- Pie : fraction de to-dos terminés sur le total `[FROM-MEMORY]` `[UNSURE]` (comment sont comptés headings/annulés).
- Complétion : un projet se complète manuellement ; si des to-dos sont ouverts, Things propose "Complete all to-dos?" / "Mark all as completed" `[FROM-MEMORY]` `[UNSURE]` (texte). Quand le dernier to-do est coché, le pie est plein et le projet reste ouvert jusqu'à action explicite (proposition d'achever) `[FROM-MEMORY]`.
- Projet avec start date future : hibernation `[VERIFIED 4001304]`.
- Projet répétitif : copie d'un modèle ; ses to-dos ne peuvent pas avoir leur propre répétition `[VERIFIED 2803564]`.
- Projets listés : "All Projects" (Quick Find) montre tous les ouverts `[VERIFIED 2803584]`.

## 11. Headings et checklists

- Heading : conteneur visuel dans un projet, glissable avec son contenu, archivable `[VERIFIED features]`. Les headings ne sont pas des to-dos : pas de checkbox. Un heading a un nom, éventuellement des notes `[UNSURE]`.
- Checklist : petite liste de sous-étapes dans un to-do, non listée en dehors, pas de dates/tags `[VERIFIED features]` ("break down the finer details of a to-do"). On ne peut pas cocher les checklists d'un template répétitif, seulement de la copie `[VERIFIED 2803564]`.
- Un to-do dont tous les items de checklist sont cochés n'est pas complété automatiquement `[FROM-MEMORY]` `[UNSURE]`.

## 12. Tags

- Tags par défaut : Home, Office, Errand, Important, Pending `[VERIFIED 2803581]`.
- Appliqués à to-dos, projets, areas. Un tag posé sur une liste est hérité par ses enfants, non affiché sur eux mais pris en compte pour filtrer/chercher `[VERIFIED 2803581]`.
- Filtre : barre de tags en tête de liste ; plusieurs tags = ET (intersection) `[VERIFIED 2803581]`.
- Hiérarchie : tag parent regroupe des enfants `[VERIFIED 2803581]` ; filtrer par le parent inclut les enfants `[FROM-MEMORY]` `[UNSURE]`.
- Ordre des tags = ordre dans la filter bar `[VERIFIED 2803581]`.
- Raccourcis clavier par tag `[VERIFIED 2803581]`.
- Pas de couleur par tag `[FROM-MEMORY]`.

## 13. Répétition

Deux patrons `[VERIFIED 3743733]` :

1. After completion : le prochain to-do est créé seulement après avoir coché le précédent ; intervalle de répétition conservé depuis la date de complétion. Exemple verbatim : arroser les plantes chaque semaine ; si fait le samedi au lieu du mercredi, le suivant tombe le samedi suivant. La première copie apparaît dans Today immédiatement ; replanifier si besoin `[VERIFIED 3743733]`.
2. Regular (daily, weekly, monthly, yearly) : un nouveau est créé selon le calendrier, que l'on ait fini ou non. Attention aux copies empilées en daily `[VERIFIED 3743733]`. Options exclusives : jours précis (ex. lun-ven, 3e mardi) et date de fin `[VERIFIED 3743733]` `[VERIFIED 2803564]`.

Modèle : "Behind every repeating to-do or project is a template" ; chaque occurrence est une copie créée dans Today depuis ce template `[VERIFIED 2803564]`.
- Template identifié par flèche circulaire bleue ; éditer le template modifie les futures copies ; éditer une copie ne conserve rien `[VERIFIED 2803564]`.
- Actions sur la règle : Edit Rule, Create Next Copy, Show Previous Copy, Pause, Resume, Stop `[VERIFIED 2803564]`.
- Deadlines répétitives : case "Add deadlines" + "days earlier" ; la deadline tombe le jour de répétition, l'item apparaît N jours plus tôt `[VERIFIED 2803564]`.
- Reminder possible sur le template `[VERIFIED 2803564]`.
- Liste Repeating : templates groupés (loose en haut, puis par parent), triés par prochaine occurrence, en pause ou en attente en bas `[VERIFIED 2803564]`.
- Complétion anticipée d'un template ou copie dans Upcoming : possible `[VERIFIED 2803564]`.
- Un to-do copie ou dans un projet répétitif ne peut pas avoir sa propre répétition `[VERIFIED 2803564]`.

## 14. Langage naturel (When et Deadline)

Langues : EN, DE, FR, IT, ES, RU, ZH, JA `[VERIFIED 9780167]`. Exemples `[VERIFIED 9780167]` :

| Saisie | Résultat |
|-|-|
| tod... | Today |
| tomorrow, Monday, next week | relatif |
| 10-3 | 3 octobre (format selon région) |
| 10-3 9 | 9h le 3 octobre (reminder) |
| 2p | reminder 14h |
| 17d | dans 17 jours (w semaines, mo mois, y ans) |
| 17d from jul9 / jul9 + 17d | 17 jours après le 9 juillet |
| wed jul... | liste de mercredis de juillet |
| 3rd wed jul | 3e mercredi de juillet |
| 3rd wed jul 2026 | idem en 2026 |
| last fri jul | dernier vendredi de juillet |

Les mots n'ont pas besoin d'être complets. Reminders seulement sur start date, pas sur deadline `[VERIFIED 9780167]`.

## 15. Textes d'états vides et libellés

Les sources n'en donnent aucun. Tout ce qui suit est `[UNSURE]` : à tester sur un vrai Things ou à remplacer par du texte propre `[PROPOSAL]`.

| Liste | Texte / visuel candidat `[UNSURE]` |
|-|-|
| Inbox | gros icône tray vide, sans texte ou "Inbox is empty" |
| Today | étoile grande + "Today is empty" / "Enjoy your day" |
| Upcoming | jours listés vides, pas de texte |
| Anytime | rien |
| Someday | rien |
| Logbook | rien |
| Projet vide | ligne vierge, pas de texte |

Libellés d'UI sûrs `[VERIFIED]` : "x to-dos were moved out of the Inbox", "This is a copy of a repeating to-do", "Continue Search", "Add Reminder", "Clear", "Add Tags", "Manage Tags", "Set Tags", "Filter by Tag", "Add deadlines", "days earlier", "Edit Rule...", "Create Next Copy", "Show Previous Copy", "Pause", "Resume", "Stop", "After Completion", "Regularly", "Show Calendar Events", "New Tag", "Quick Entry", "Autofill", "Plus Button".

## 16. Divers

- Les raccourcis de planification : voir 05. Swipe droit : When `[VERIFIED 2803582]`.
- Création : un to-do créé depuis une liste hérite du contexte (Today -> start date aujourd'hui ; projet -> dans ce projet ; heading -> sous ce heading ; Upcoming -> jour) `[FROM-MEMORY]`.
- Duplication (`Cmd-D`) crée une copie à côté `[VERIFIED 2785159]`.
- Corbeille : suppression Mac vers Trash ; iOS définitive `[VERIFIED 4001304]`.
- Annuler (cancel) : statut distinct de complété, croix, barré `[VERIFIED 2785159]` (Cancel selected item).

## Récapitulatif [UNSURE]

Textes d'état vide ; règle de complétion de projet et libellé de la confirmation ; comptage du pie ; bascule de minuit des non faits ; This Evening sur jour futur ; ordre exact de regroupement d'Upcoming au-delà de 7 jours ; réglage de fréquence de passage au Logbook ; filtrage par tag parent ; auto-complétion d'un to-do à checklist cochée ; formulation de "en retard".
