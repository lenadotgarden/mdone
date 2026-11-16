# 01 - Design tokens

Rappel : Cultured Code ne publie aucune valeur visuelle. Tout ce qui est chiffré ici est `[FROM-MEMORY]` ou `[PROPOSAL]` et doit être calibré sur captures. Les noms de tokens sont des propositions pour le code SwiftUI (`ThingsTheme`).

Mise a jour : la section 8 calibre sur les captures Mac (`reference/mac-dark-0N.png`) les valeurs Mac et la palette sombre chaude, avec une etiquette MEASURED, ESTIMATED, DERIVED ou UNSURE par valeur. Elle l emporte sur les sections 2 a 4 pour tout ce qui y figure.

## 1. Principes visuels

- "Une feuille de papier propre" : fond blanc, contenu sans bordure, très peu de séparateurs `[VERIFIED https://culturedcode.com/things/features/]` (citation de presse : "a clean, crisp piece of paper").
- À l'ouverture, un to-do "se transforme en une feuille blanche" : l'item s'agrandit en carte blanche avec ombre portée, les champs secondaires (tags, checklist, When, Deadline) sont rangés dans un coin tant qu'ils ne servent pas `[VERIFIED features]`.
- Tout est animé avec un toolkit maison ("Everything you do in Things is nicely animated for pop") `[VERIFIED features]`.
- Retour haptique présent partout ("Haptic Feedback") `[VERIFIED features]`.
- Mode sombre et Dynamic Type supportés, thème "Black" (noir pur) pour widgets `[VERIFIED https://culturedcode.com/things/support/articles/2803567/]`.

## 2. Couleurs

### 2.1 Accent et sémantique `[FROM-MEMORY]` sauf mention

| Token | Light | Dark | Usage |
|-|-|-|-|
| accent (blue) | #1E7BF4 `[UNSURE]` approx #007AFF-like | #3D8FF7 | boutons, liens, Magic Plus, sélection, badge Inbox, flèches |
| todayStar (yellow) | #FFCC00 approx `[UNSURE]` | #FFD60A | icône Today, étoile devant to-do Today dans Anytime/projets |
| eveningMoon | #3A59D1 bleu-violet `[UNSURE]` | #5E7CF5 | icône et titre de section This Evening |
| deadlineFlame (red) | #FF3B30 approx `[UNSURE]` | #FF453A | drapeau/flamme + "X days left" ; en retard : plus soutenu |
| inboxBlue | = accent | | icône tray |
| upcomingRed | #F2405D approx `[UNSURE]` | | icône calendrier Upcoming (rouge-rose) |
| anytimeTeal | #35B6A7 approx `[UNSURE]` | | icône Anytime (pile de couches) |
| somedayTan | #D8B98A approx `[UNSURE]` | | icône Someday (boîte beige) |
| logbookGreen | #4CC260 approx `[UNSURE]` | | icône Logbook (livre avec coche) |
| areaGray | #8E8E93 | | icône Area (boîte/coffre) |
| filterBarGreen | #34C759 approx | | barre de filtre de tag active `[VERIFIED https://culturedcode.com/things/support/articles/2803581/]` ("tap the green filter bar") ; teinte exacte `[UNSURE]` |

### 2.2 Neutres

| Token | Light | Dark `[FROM-MEMORY]` |
|-|-|-|
| bgPrimary (liste, fenêtre) | #FFFFFF | #1C1C1E (thème Dark) ou #000000 (thème Black, réglage Appearance) |
| bgSidebar / Home iPhone | #F5F6F8 mac sidebar translucide ; iPhone Home #FFFFFF | #2C2C2E |
| bgExpandedTodo (carte ouverte) | #FFFFFF + ombre | #2C2C2E |
| textPrimary | #1D1D1F `[UNSURE]` approx noir | #F2F2F7 |
| textSecondary (notes aperçu, tags, compteurs) | #8E8E93 | #98989D |
| textPlaceholder | #C7C7CC | #48484A |
| separator | #E5E5EA, 0,5 pt, inset gauche aligné sur le texte du titre | #38383A |
| checkboxBorder | #B8BCC4 `[UNSURE]` | #636366 |
| tagPillBg | #EDEDF0 | #3A3A3C |
| tagPillText | #6D6D72 | #AEAEB2 |
| selectionRow (multi-select) | accent à 12 % | accent à 22 % |
| somedayDim | textPrimary à 50 % (items Someday "prennent la place arrière visuellement") `[VERIFIED https://culturedcode.com/things/support/articles/4001304/]` | idem |

### 2.3 Tags

Les tags de Things 3 n'ont pas de couleur propre : pill grise uniforme `[FROM-MEMORY]`. Seule la barre de filtre devient verte quand un filtre est actif `[VERIFIED 2803581]`. Tags livrés par défaut : Home, Office, Errand, Important, Pending `[VERIFIED 2803581]`. Les tags peuvent être groupés (imbriqués) `[VERIFIED 2803581]`.

### 2.4 Checkbox

| État | Rendu `[FROM-MEMORY]` |
|-|-|
| to-do ouvert | carré arrondi 22x22 pt (iPhone), 16x16 pt (Mac), rayon 5 pt (iPhone) / 4 pt (Mac), contour 1,5 pt checkboxBorder, intérieur vide |
| to-do complété | carré plein accent (ou gris atténué selon contexte), coche blanche ; le titre passe en gris et est barré après un court délai |
| to-do annulé (cancelled) | carré gris avec croix `x` ; titre barré |
| to-do du Today dans Anytime/projet | étoile jaune affichée devant la checkbox (la checkbox reste) `[VERIFIED 4001304]` ("yellow star in front of them") |
| projet | disque "progress pie" : cercle contour accent, secteur plein proportionnel à l'avancement `[VERIFIED features]` ("Progress Pies") |
| item de checklist | petit cercle (pas carré) `[VERIFIED https://culturedcode.com/things/support/articles/2803582/]` ("Tap the circle in front") 16 pt iPhone |
| template répétitif | flèche circulaire bleue devant le titre `[VERIFIED https://culturedcode.com/things/support/articles/2803564/]` ("blue circle arrow") |

## 3. Typographie (SF Pro, Dynamic Type)

Things suit Dynamic Type sur iOS, avec option "Custom" dans Settings > Appearance ; sur Mac un curseur "Text Size" dans Settings > General, avec atténuation de la sidebar aux grandes tailles `[VERIFIED https://culturedcode.com/things/support/articles/8537373/]`.

| Élément | iPhone | Mac | Graisse |
|-|-|-|-|
| Titre de liste (Today, Inbox, titre de projet) | 34 pt (largeTitle) `[UNSURE]` | 26 pt `[UNSURE]` | bold |
| Titre de to-do en liste | 17 pt (body) | 13 pt | regular |
| Titre de to-do ouvert | 17 pt | 14 pt | regular (pas de bold) |
| Notes aperçu / notes | 15 pt | 12-13 pt | regular, textSecondary |
| Heading de projet | 20 pt (title3) `[UNSURE]` | 16 pt | semibold, couleur accent ; trait sous le titre (hairline accent) |
| Titre de section (This Evening, jour dans Upcoming) | 17-20 pt | 13-16 pt | semibold |
| Jour dans Upcoming (grand chiffre) | 28 pt `[UNSURE]` | 26 pt | bold + nom du jour en gris 15 pt |
| Sidebar / Home row | 17 pt | 13 pt | regular ; compteurs 15/12 pt secondary |
| Tags pill | 13 pt (footnote) | 11 pt | regular |
| Deadline label ("5 days left") | 13 pt | 11 pt | regular, rouge si <= 0 |

Pas de style dans les titres : le Markdown n'affecte ni titres de to-do, ni noms de projets/areas `[VERIFIED https://culturedcode.com/things/support/articles/4438545/]` ("styling will not show in to-do titles or names of projects or areas"). Les notes supportent Markdown, les marqueurs restent visibles `[VERIFIED 4438545]`.

## 4. Espacements et dimensions

Valeurs `[FROM-MEMORY]` / `[PROPOSAL]`, à calibrer.

| Élément | iPhone | Mac |
|-|-|-|
| Marge horizontale de liste | 16 pt (checkbox x=16) | 20 pt |
| Hauteur minimale de ligne to-do | 44 pt (titre seul) ; ~ 52-58 pt avec tags/deadline/notes | 28-30 pt (titre seul) |
| Checkbox - titre espacement | 12 pt | 8 pt |
| Séparateur ligne | 0,5 pt, inset gauche 50 pt, droite 0 | 0,5 pt hairline |
| To-do ouvert (carte) | marge 8 pt autour, padding intérieur 16 pt, rayon 10 pt `[UNSURE]`, ombre douce (y 2, flou 12, 12 % noir) | rayon 8 pt, ombre y 2 flou 10 |
| Rayon des boutons capsules (tags, When) | capsule (rayon = h/2) | idem |
| Magic Plus | disque 56 pt, bleu accent, plus blanc, ombre ; position : coin bas-droit, 16 pt des bords, au-dessus de la barre d'accueil | n/a (bouton + en bas à gauche de la fenêtre, 22 pt) |
| Sidebar Mac | largeur 220 pt, redimensionnable 180-400 pt `[UNSURE]` | |
| Ligne Home iPhone | 44-48 pt, icône 24 pt à x=16, titre x=56 | |
| Icône de liste | 24 pt iPhone, 18 pt Mac | |

## 5. Icônes par liste (à redessiner)

| Élément | Glyphe | Couleur |
|-|-|-|
| Inbox | plateau/tray ouvert | accent bleu |
| Today | étoile pleine (5 branches arrondies) | todayStar |
| This Evening | croissant de lune | eveningMoon |
| Upcoming | calendrier (page avec bandeau) | upcomingRed |
| Anytime | pile de couches (3 losanges empilés) | anytimeTeal |
| Someday | boîte/caisse en carton | somedayTan |
| Logbook | livre ouvert avec coche | logbookGreen |
| Trash | corbeille (Mac sidebar, n'apparaît que si non vide) | gris |
| Area | boîte/coffre gris `[UNSURE]` | areaGray |
| Project | disque progress pie | accent |
| Deadline | drapeau (flag) `[VERIFIED https://culturedcode.com/things/support/articles/2803579/]` ("deadline button ... the flag button") | deadlineFlame |
| When | calendrier / étoile selon état | gris ; jaune si Today |
| Tags | étiquette | gris |
| Checklist | liste à puces | gris |
| Repeat | flèches circulaires | gris ; bleu pour template |
| Reminder | cloche / horloge | gris |
| Magic Plus | `+` blanc sur disque bleu | |

Dans l'app d'origine ces icônes sont dessinées sur mesure (SVG propriétaires) : les redessiner.

## 6. Haptique `[FROM-MEMORY]` (présence `[VERIFIED features]`)

| Événement | Feedback iOS proposé |
|-|-|
| compléter un to-do (tap checkbox) | UIImpactFeedbackGenerator .light (ou .soft) |
| soulever un item pour drag | .medium impact |
| déposer un item | .light |
| Magic Plus : soulever | .medium ; survol de l'Inbox target ou du bord gauche (heading) | selection feedback |
| entrée en multi-select (swipe gauche) | selection changed |
| balayage de sélection le long du bord droit | selection changed à chaque ligne |
| pull-down atteint le seuil Quick Find | .light |
| shake undo | notification .warning |

## 7. Animations `[FROM-MEMORY]` + `[PROPOSAL]` SwiftUI

Cultured Code ne publie pas les courbes. Équivalents recommandés :

| Interaction | Comportement observé | SwiftUI proposé |
|-|-|-|
| compléter un to-do | la coche se remplit (~ 0,15 s), titre grisé et barré, après ~ 1 s (laisse annuler) la ligne se rétracte et disparaît ; ou reste jusqu'au "Move completed to Logbook" selon réglage | `withAnimation(.spring(response:0.3,dampingFraction:0.8))` coche ; suppression après `DispatchQueue` 1,0 s avec `.easeInOut(0.25)` sur la hauteur |
| ouvrir un to-do (expand-to-edit) | la ligne grandit en carte blanche, les lignes voisines glissent, ombre apparaît | `matchedGeometryEffect` + `.spring(response:0.35,dampingFraction:0.85)` ; ombre fade 0,2 s |
| fermer | inverse, mêmes timings | idem |
| reorder (drag) | item soulevé, légèrement agrandi (scale 1,03), ombre, les autres s'écartent | `.spring(response:0.28,dampingFraction:0.8)` |
| Magic Plus drag | bouton suit le doigt, une ligne vide s'ouvre sous le doigt à l'endroit d'insertion ; relâcher : la ligne devient un nouveau to-do en édition | idem |
| ouverture picker When | popover/feuille depuis le bas ; calendrier avec défilement mensuel | sheet standard |
| bascule This Evening | l'item glisse vers la section du bas | `.easeInOut(0.3)` |
| pull-down search | la barre de recherche se révèle, le contenu descend ; au-delà du seuil, bascule en recherche | seuil ~ 60 pt `[UNSURE]` |

## Récapitulatif [UNSURE]

Tous les hex de 2.1 et 2.2 ; tailles du titre de liste, des headings, des jours Upcoming ; rayons de carte ouverte ; largeur sidebar Mac ; seuil pull-down ; icône exacte d'Area ; teinte exacte de la filter bar.

## 8. Calibration sur captures Mac (palette "dark warm")

Source : `reference/mac-dark-01.png` a `05.png`, 3500 x 2218 px, capture retina 2x (1 pt = 2 px). Fenetre 1750 pt, sidebar 302 pt de large, colonne de liste 1020 pt (centree dans le volet de detail, 1448 pt). Cote des valeurs : `MEASURED` = lu sur la capture a environ 1 pt pres ou echantillon de pixel ; `ESTIMATED` = lu a l'oeil sur la capture, a 1 pt ou quelques niveaux pres ; `DERIVED` = variante claire deduite de la sombre, aucune capture claire ; `UNSURE` = toujours une hypothese (iOS, palette claire). Le code est dans `DesignSystem/Tokens`, un commentaire par valeur porte la meme etiquette. La palette sombre chaude remplace le gris froid iOS comme palette sombre par defaut (iOS aussi).

### 8.1 Couleurs (sombre)

| Token | Hex | Cote | Usage |
|-|-|-|-|
| bgPrimary | #302C2A | MEASURED | fond de fenetre et de liste |
| bgSidebar | #312D2C | MEASURED | fond de sidebar |
| bgSidebarSelection | #3B3E42 | MEASURED | ligne selectionnee de la sidebar |
| selectionRow | #393C3F | MEASURED | ligne selectionnee de la liste |
| bgCalendarBox | #3F3B39 | MEASURED | boite des evenements du calendrier, pastille de date |
| separator | #4F4B4A | MEASURED | filet sous un en-tete de section |
| bgExpandedTodo | #3B3735 | ESTIMATED | carte du to-do ouvert |
| textPrimary | #F4F2F0 | ESTIMATED | titres |
| textSecondary | #8F8B89 | ESTIMATED | ligne de projet, icone de notes |
| textPlaceholder | #77726F | ESTIMATED | "Notes", icones de la barre de la carte |
| textMutedLink | #7A7674 | ESTIMATED | "Hide later items", "Show N logged items" |
| checkboxBorder | #7C7875 | ESTIMATED | contour de la case |
| tagPillBorder / tagPillText | #6A6664 / #9A9694 | ESTIMATED | pastille de tag (contour seul) |
| chipFill / chipText | #8F8B89 / #2B2725 | ESTIMATED | pastille "All" selectionnee |
| todayStar | #FFD60A | ESTIMATED | etoile |
| eveningMoon | #A9B7F3 | ESTIMATED | lune de This Evening |
| upcomingRed | #F0476B | ESTIMATED | icone calendrier |
| anytimeTeal | #3BAFA8 | ESTIMATED | icone Anytime |
| somedayTan | #DCC48C | ESTIMATED | icone Someday |
| logbookGreen | #57C26A | ESTIMATED | icone Logbook |
| areaTint | #7CCFAE | ESTIMATED | cube d'Area dans l'en-tete |
| accent, deadlineFlame, filterBarGreen | inchanges | UNSURE | pas visibles sur les captures |

Variantes claires : `DERIVED` pour bgCalendarBox (#F1F1F3) et bgSidebarSelection (#DADDE3), `UNSURE` pour le reste (aucune capture claire).

### 8.2 Dimensions Mac (pt)

| Element | Valeur | Cote |
|-|-|-|
| Hauteur de ligne, titre seul | 28 | MEASURED (pas entre lignes) |
| Hauteur de ligne, titre + ligne de projet | 38 | MEASURED |
| Case a cocher | 12, rayon 3, contour 1, centree verticalement dans la ligne | MEASURED taille, ESTIMATED rayon et contour |
| Case Someday | contour en pointilles 2 / 2 | MEASURED (pointilles), ESTIMATED motif |
| Gouttiere gauche | surbrillance a x = 0, case a x = 10 | MEASURED |
| Case a titre | 9 (titre a x = 31 depuis le bord de la ligne) | MEASURED |
| Rayon de la surbrillance | 6 continu | ESTIMATED |
| Separateurs entre lignes | aucun | MEASURED |
| Titre de to-do | 14 regular | ESTIMATED |
| Ligne de projet | 12 regular, emoji inclus dans le texte | ESTIMATED |
| Icone de notes apres le titre | 10, ecart 5 | MEASURED position, ESTIMATED taille |
| Pastille de tag en ligne | contour 0,75, capsule 16 haut, texte 11 medium, 8 apres le titre | MEASURED hauteur, ESTIMATED reste |
| Pastille de date ("Thu") | 16 haut, rayon 4, fond bgCalendarBox, texte 11 | MEASURED hauteur |
| Titre de liste | 22 bold, icone 22, ecart 8, centre a y = 84 (barre d'outils 52) | MEASURED centre, ESTIMATED corps |
| Titre au premier to-do | 27 (sans boite ni filtre) | MEASURED |
| Boite d'evenements Today | 1000 x 66 pour 3 lignes, rayon 10, marge 12 / 9, pas 16, barre 3 x 11, texte 12 | MEASURED sauf rayon et texte (ESTIMATED) |
| Titre a la boite / boite au filtre / filtre a la premiere ligne | 13 / 16 / 46 | MEASURED |
| Pastille de filtre | 20 haut, texte 12 semibold, "All" = capsule pleine | MEASURED hauteur, ESTIMATED texte |
| En-tete de section | icone 14, titre 14 bold a x = 31, filet 0,5 a 6 sous le texte, 7 de marge de chaque cote | MEASURED positions, ESTIMATED corps |
| Espace avant un en-tete / filet a la premiere ligne | 40 / 9 | MEASURED (34 a 46 selon la ligne precedente) |
| Carte ouverte | decalage 4 hors de la ligne, rayon 12, marge interne 14, haut 18, bas 19, zone de notes 60 mini | MEASURED sauf rayon (ESTIMATED) |
| Barre de la carte | when a gauche a x = 35, 3 icones de 13 pt, pas 32, marge droite 28 | MEASURED |
| Fil d'Ariane sous la carte | 12 semibold, aligne a 17 du bord droit de la carte, 17 sous la carte | MEASURED |
| Ombre de la carte | rayon 12, y 3, noir a 30 % (sombre) | ESTIMATED (quasi invisible sur les captures) |
| "Hide later items" | 12, 38 sous la derniere ligne, a x = 10 ; "Show N logged items" 23 plus bas | MEASURED |
| Largeur de la sidebar | 302 | MEASURED (largeur de la capture, le code garde 240 ideal pour une fenetre normale) |

Valeurs de la spec d'origine rendues obsoletes par ce tableau : 4 (carte Mac : rayon 8, ombre y 2 flou 10), 3 (titre de liste Mac 26, titre de to-do 13), 4 (case Mac 16, hauteur de ligne 28 a 30, marge 20).

### 8.3 Animations de reordonnancement

Pas dans les captures (statiques), donc `[PROPOSAL]` : levee de la ligne `scale 1,03` + ombre (ressort 0,2 / 0,75), autres lignes qui s'ecartent (`ThingsMotion.reorder`, ressort 0,28 / 0,8), echange clavier Cmd Opt fleche (`ThingsMotion.reorderSwap`, ressort 0,26 / 0,82), retour a la place en cas d'echec reseau.
