# Spec Things 3 (Cultured Code) pour la refonte mDone

Cible : ingénieurs SwiftUI qui n'ont jamais vu Things. Objectif : reproduire l'UI/UX de Things 3 trait pour trait (iPhone + macOS), l'app étant renommée et les icônes redessinées. Usage personnel.

Langue : français. Les termes et libellés d'UI de Things restent en anglais tels que l'app les affiche (Inbox, Today, This Evening, Upcoming, Anytime, Someday, Logbook, Magic Plus, Quick Entry, Quick Find, Type Travel, When, Deadline...).

## Convention de fiabilité

Chaque affirmation non triviale porte une étiquette :

- `[VERIFIED url]` : lu sur la page citée (aspect textuel ; les valeurs visuelles exactes ne sont jamais données par Cultured Code).
- `[FROM-MEMORY]` : connaissance de l'app, non revérifiable sans appareil. Fiable pour la structure et le comportement, approximative pour les pixels.
- `[UNSURE]` : à valider avant de figer. Liste récapitulative en fin de ce fichier.
- `[PROPOSAL]` : choix de conception de notre fork, pas un fait sur Things (surtout dans 01 pour les valeurs SwiftUI et dans 07).

Règle d'or : les valeurs en pixels, hex et durées de 01 sont des estimations `[FROM-MEMORY]` ou `[PROPOSAL]` sauf mention contraire. Cultured Code ne publie ni spécification visuelle ni code. Calibrer par comparaison visuelle avec des captures de l'app dès qu'un appareil est disponible.

## Fichiers

| Fichier | Contenu |
|-|-|
| 00-README.md | cet index, sources, [UNSURE] |
| 01-design-tokens.md | couleurs, typo, espacements, rayons, icônes, haptique, animations |
| 02-ios-screens.md | tous les écrans iPhone avec wireframes ASCII |
| 03-ios-gestures.md | tous les gestes iOS et leur résultat exact |
| 04-macos-screens.md | fenêtre Mac, Quick Entry, Quick Find, popovers, menus, préférences, drag and drop |
| 05-macos-shortcuts.md | table complète des raccourcis clavier Mac (vérifiée) |
| 06-behaviors-rules.md | règles sémantiques (listes, dates, répétition, Logbook, tags, textes vides) |
| 07-vikunja-mapping.md | correspondance concepts Things vers Vikunja v2, écarts, conventions |
| 08-drag-and-drop.md | modèle du glisser-déposer Mac : payload, slot d'insertion, plans, sidebar, accessibilité |

## Sources

Toutes lues le 2026-11-16 par `curl` (extraction texte du HTML).

Pages de support Cultured Code (base https://culturedcode.com/things/support/articles/) :

- 2785159 Keyboard Shortcuts for Mac (table complète, source de 05)
- 2803582 Using Gestures (iPhone, iPad, Vision)
- 4001304 An In-Depth Look at Today, Upcoming, Anytime, and Someday
- 2803579 Scheduling To-Dos in Things
- 2803564 Using Repeating To-Dos ; 3743733 Choosing a Repeat Pattern
- 2803581 Using Tags
- 2803584 Searching and Navigating with Quick Find
- 2803583 Connecting Your Calendars
- 9780167 Using Natural Language Input
- 2803585 Setting a Reminder
- 2803567 Using Things' Widgets
- 2249437 Adding To-Dos From Anywhere On Your Mac Through Quick Entry
- 4438545 Writing Notes in Things ; 4651820 Markdown Guide
- 8537373 Changing the Text Size
- 2803566 Using the OS Share Feature
- 2877019 Speaking to Siri ; 2157909 Using Things on Apple Watch
- 1059358 Discover Great Features (index des articles)

Autres : https://culturedcode.com/things/features/ (page "What's new in the all-new Things" : Magic Plus, Jump Start, Quick Find, Type Travel, Slim Mode, progress pies, haptics, animations).

Mémoire : connaissance générale de Things 3 pour iOS/macOS (jusqu'à fin 2025 environ). Les captures d'écran du site sont des vidéos, non exploitables ici : aucune valeur pixel n'a pu être mesurée.

Autres fichiers du repo consultés : `docs/vikunja-api-inventory.md` (API v2, minimum Vikunja 2.5.0).

## Contraintes de rédaction

Pas de tiret cadratin ni de double tiret : tiret simple uniquement. Les wireframes ASCII utilisent `|`, `+`, `_`, `=` pour les traits.

## Liste récapitulative des [UNSURE]

Voir la section "Récapitulatif [UNSURE]" à la fin de chaque fichier 01 à 07. Résumé des plus importants :

1. Valeurs hex exactes de toutes les couleurs (01).
2. Tailles et graisses exactes des titres de liste, en-têtes, notes (01).
3. Hauteurs de ligne exactes, rayons de coins (01).
4. Courbes et durées d'animations réelles (01).
5. Textes exacts des états vides par liste (06).
6. Position exacte des boutons de la barre du bas de l'écran Home iPhone (02).
7. Ordre exact des actions dans les menus "..." (02).
8. Comportement de l'ordre de Today dans Vikunja (07).
