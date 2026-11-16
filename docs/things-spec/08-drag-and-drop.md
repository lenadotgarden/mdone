# 08 Glisser-déposer (Mac)

Un seul système, celui de macOS (`onDrag` et `DropDelegate`), pour deux usages : **ordonner** les to-dos dans une liste, et **déposer** un to-do ou un projet sur une ligne de la sidebar. Complète `04-macos-screens.md` section 10 (tableau des sources et cibles de Things).

Code écrit sans compilateur, à valider par la CI macOS puis sur un Mac.

## 1. Modèle

```
Source                         Payload                      Cibles
ligne de to-do (liste)   ->    ThingsDragPayload.todo(id)   -> la liste elle-même (ordre, section)
                                                            -> ligne de sidebar (projet, Area, Inbox, Today, Someday)
ligne de projet/Area     ->    ThingsDragPayload.project(id)-> ligne de sidebar (projet, Area)
(sidebar)
```

Le payload est une chaîne (`mdone-todo:42`, `mdone-project:7`) écrite dans le presse-papier de drag comme texte brut : aucun UTType à déclarer. Les deux sources passent par `ThingsDragItem.provider(for:)`, toutes les cibles acceptent `ThingsDragItem.contentTypes`. C'est ce qui garantit que le type est identique partout.

### Modules (`Features/Things/`, purs sauf mention)

| Fichier | Contenu |
|-|-|
| `Domain/Mapping/ThingsDragPayload.swift` | `ThingsDragPayload` (`todo`, `project`, `todoID`, `projectID`, encodage). |
| `ThingsDragDrop.swift` | `ThingsDropTarget` (liste ou projet de la sidebar), `ThingsDropAction`, `ThingsDropFacts`, `ThingsDropResolver` (que fait un drop sur une ligne de sidebar), `ThingsSectionID`, `ThingsDropRules` (quels changements de section ont un sens). |
| `ThingsDropGeometry.swift` | `ThingsDropSlot` (point d'insertion), `ThingsDropGeometry.slot` (pointeur Y et frames des lignes vers slot), `shift` (de combien chaque ligne glisse). Aucune valeur de mise en page : le nombre de points vient des frames. |
| `ThingsDropPlan.swift` | `ThingsDropPlan` (`reorder` ou `changeSection`), `make(slot:movingID:sections:)`, `overrides`, `ThingsDropArrangement` (ordre optimiste, d'une section à l'autre). |
| `ThingsDragItem.swift` | `NSItemProvider` et lecture asynchrone du payload (Foundation et UniformTypeIdentifiers seulement). |
| `ThingsListViewModel+Reorder.swift` | `ThingsReorder` (inchangé), `commitReorder`, `commitDrop`. |
| `Platform/macOS/ThingsMacDragDrop.swift` | `ThingsDragSession`, `ThingsListDropDelegate`, `ThingsSidebarDropDelegate`, `ThingsSidebarDragSource`. |
| `Platform/macOS/ThingsMacTodoList.swift` | Source de drag sur chaque ligne, un seul `DropDelegate` pour toute la liste, animation de l'écart. |
| `Platform/macOS/ThingsMacSidebar.swift` | Une cible par ligne, surbrillance, source de drag des projets et Areas. |
| `Platform/macOS/ThingsMacModel+Actions.swift` | `dropAction(for:on:)` (lit l'état, appelle le resolver) et `handleDrop(_:on:)` (exécute). |

Tokens : `ThingsMotion.reorder` (ressort de l'écart qui s'ouvre et se ferme, du glissement des lignes et du retour), `ThingsMotion.reorderSwap` (clavier), `ThingsMotion.dropTargetHighlight` (surbrillance d'une ligne de sidebar), `ThingsMetrics.Reorder.*` (ombre de l'image de drag, hauteur d'écart de secours), `ThingsMetrics.Card.cornerRadius`, `ThingsColorOpacity.liftShadow`.

## 2. Ordonner dans la liste

1. Le drag démarre au mouvement de la souris (seuil du système). La ligne est sélectionnée, un retour haptique est donné, et l'image du drag est la ligne sur une carte avec l'ombre de soulèvement.
2. Toute la liste est une cible. À chaque `dropEntered` et `dropUpdated`, `ThingsDropGeometry.slot` calcule le slot : au-dessus de la première ligne dont le milieu est sous le pointeur, ou sous la dernière. Entre deux sections (zone de l'en-tête), le côté le plus proche gagne.
3. Pendant que le pointeur est dans la liste, la ligne source est masquée, les lignes entre l'ancienne et la nouvelle place glissent d'une hauteur de ligne (ressort `reorder`) : l'écart s'ouvre là où le to-do atterrira et se ferme là où il était. `dropExited` remet le slot à nil, tout revient, la ligne source réapparaît (un drag annulé ne laisse donc rien de masqué).
4. `performDrop` construit un `ThingsDropPlan` et le valide, applique l'ordre optimiste (`orderOverride`, avec animation), puis `ThingsListViewModel.commitDrop` envoie `AppState.moveTask(_:toPosition:)`. La position vient de `TaskPositioning` (mêmes règles que le web Vikunja). Quand le serveur répond, l'ordre optimiste est retiré. Si l'envoi a échoué, les lignes reviennent à leur place (rollback).
5. Un drop qui ne change rien renvoie `false` : le système ramène l'image à la ligne.

## 3. Entre sections d'un même écran

Règles (`ThingsDropRules.when(from:to:)`), tout le reste est refusé :

| De | Vers | Effet |
|-|-|-|
| Today | This Evening | When = This Evening (label `things:evening`, via `ThingsListViewModel.schedule`) |
| This Evening | Today | When = Today (retire le label) |
| Projet (to-dos ouverts) | groupe Someday du même projet | When = Someday |
| groupe Someday | to-dos ouverts du même projet | When retiré (Anytime) |

Jamais source ni cible : Overdue (vient d'une deadline), Upcoming (demande une date), Logged (vient de l'état terminé). Le to-do prend une position entre ses voisins de la section cible (`TaskPositioning.position(forInserting:at:into:)`), envoyée après le changement de When. Pendant l'envoi, il est affiché dans la section cible (`ThingsDropArrangement`), l'ancienne section perd la ligne ; une section avec titre qui devient vide disparaît.

Une section cible doit contenir au moins un to-do pour apparaître : on ne peut pas déposer dans une section absente (This Evening vide).

## 4. Sur la sidebar

- Une ligne de sidebar n'est surlignée au survol que si `ThingsMacModel.dropAction` renvoie une action (donc jamais pour un drop sans effet : même projet, cycle, liste sans sens). Le surlignage est animé (`dropTargetHighlight`).
- Cibles et effets (`ThingsDropResolver`) : to-do sur projet ou Area = déplacer ; sur Inbox = projet Inbox ; sur Today ou Someday = planifier (sauf s'il y est déjà) ; projet sur projet ou Area = re-parenter (sans cycle). Upcoming, Anytime, Logbook refusent.
- Le to-do quitte la liste par le changement de données : `ThingsMacTodoList` anime les entrées et sorties d'ids (`rowRemoval`), donc la ligne se referme comme un to-do terminé.
- Le drop de la sidebar relit le payload dans le presse-papier (asynchrone) avant d'agir ; le survol utilise `ThingsDragSession`.

### ThingsDragSession

Une cible ne peut pas lire le presse-papier pendant le survol, mais doit savoir ce qui est traîné. La source enregistre le payload au début du drag (`ThingsDragSession.shared.begin`). Aucun callback de fin de drag n'existe pour `onDrag` : la session est vidée au drop et au prochain clic. Elle ne sert qu'au retour visuel et à la validation du survol.

## 5. Sans pointeur

- Cmd-Opt-Haut et Cmd-Opt-Bas (et Cmd-Haut et Cmd-Bas) : un cran, dans la section (`ThingsReorder.plan(by:)`).
- Actions d'accessibilité et menu contextuel : Move Up, Move Down, et Move to This Evening, Today, Someday ou Anytime quand la règle de la section 3 le permet (`ThingsDropRules.moves`). Ce sont les mêmes plans que le drag.
- Move... (Maj-Cmd-M) reste le moyen clavier pour un projet ou une Area.

## 6. Tests

`mDoneTests/Features/ThingsDropPlanTests.swift` : slot depuis le pointeur (haut et bas de ligne, zone d'en-tête, lignes sans frame, sections filtrées), glissement des lignes, plans (même section, autre section, refus), règles de section, ordre optimiste inter-sections, résolution des drops sur la sidebar, payload. `ThingsReorderTests` couvre toujours `ThingsReorder` et `TaskPositioning`.

## 7. Limites connues et pistes

- Pas d'auto-défilement garanti pendant un drag près du bord (laissé au `ScrollView` du système, à vérifier sur Mac).
- Pas de dépliage automatique d'une Area repliée survolée, ni d'ouverture d'une liste au survol prolongé.
- Pas de drop d'un to-do sur un jour d'Upcoming ni sur un tag (04 section 10), pas de multi-sélection, pas de headings.
- Les lignes qui changent de section se fondent (retrait et insertion) au lieu de glisser d'une section à l'autre.
- Les lignes hors écran n'ont pas de frame (liste paresseuse) : le slot se calcule sur les lignes visibles, ce qui suffit car le pointeur est toujours sur une ligne visible.
- Un drag annulé hors de la fenêtre laisse le payload dans `ThingsDragSession` jusqu'au prochain clic ; seul le retour visuel d'une cible peut en dépendre.
- Les libellés `Move to This Evening`, `Move to Today`, `Move to Someday`, `Move to Anytime`, `Move` sont à ajouter à `Localizable.xcstrings` (fichier d'un autre lot).
