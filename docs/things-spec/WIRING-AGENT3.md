# Wiring agent 3: natural language and Type Travel

Code written without a compiler. Everything below is to be checked by the macOS CI, then on a Mac.

## What is in place

| Piece | File |
|-|-|
| Pure mapper, plan, preview chips | `mDone/Domain/Mapping/ThingsNaturalLanguage.swift` |
| Creation from a plan, preference helper, mapper factory | `mDone/Features/Things/ThingsListViewModel+NaturalLanguage.swift` |
| Preview line (chips) | `mDone/Features/Things/ThingsNaturalLanguagePreview.swift` |
| Empty to-do row with preview | `mDone/Features/Things/ThingsInlineAddRow.swift` |
| Quick Entry preview | `mDone/Platform/macOS/ThingsQuickEntryPanel.swift` |
| Quick Find engine (groups, accents, tag filter, Type Travel key test) | `mDone/Features/Things/ThingsQuickFindEngine.swift` |
| Quick Find card (overlay, tag mode) | `mDone/Platform/macOS/ThingsQuickFindView.swift` |
| Type Travel | `mDone/Platform/macOS/ThingsTypeTravel.swift`, one line in `ThingsMacRootView.swift` |
| Quick Find shown as overlay instead of sheet | `mDone/Platform/macOS/ThingsMacRootModifiers.swift` |
| Tests | `mDoneTests/Features/ThingsNaturalLanguageTests.swift`, `ThingsQuickFindGroupingTests.swift` |

## Edit of a file owned by another agent (unavoidable)

`mDone/Features/Things/ThingsListViewModel.swift`, minimal and additive:

1. `appState`, `calendar` and `clock` went from `private let` to `let`, because an extension in another file cannot read private members.
2. The two `quickAdd` methods start with
   `if let plan = naturalLanguagePlan(for: trimmed) { return await create(plan: ..., defaultProjectID: ..., defaultWhen: ...) }`.
   Swift cannot override a method from an extension, and this is what makes every caller (iPhone list and project screens, Mac inline row, Quick Entry) use natural language without editing `ThingsListScreen`, `ThingsProjectScreen`, `ThingsMacModel+Actions`.

The other agent's extension file can now read `appState`, `calendar`, `clock`.

## How every creation path gets it

All paths call `ThingsListViewModel.quickAdd(title:when:)` or `quickAdd(title:inProject:)`.

- iPhone: Magic Plus opens `ThingsInlineAddRow` (preview under the field), finish calls `quickAdd`.
- Mac inline new to-do: `ThingsMacTodoList` shows `ThingsInlineAddRow`, `ThingsMacModel.finishAdding` calls `quickAdd`.
- Mac Quick Entry panel: preview under the title, save calls `quickAdd` on the Inbox list.
- `ThingsMagicPlusButton.swift` is unchanged in behaviour (it only opens the row); it now lives in `DesignSystem/Components/Things`.

`naturalLanguagePlan(for:)` returns nil when the preference is off or the text names nothing: then the old path creates the typed title verbatim.

## Preference

The switch is `SmartParsingPreference.storageKey` ("Smart parsing" in Settings). It is ON by default everywhere (`SmartParsingPreference.defaultValue == true`, since agent B). `ThingsNaturalLanguagePreference` no longer exists.

## Syntax (case-insensitive)

Kept from `SmartTaskParser`: `+Project` or `#Project` (project or Area, unique prefix allowed), `*tag` (existing tags only), `!1` to `!5` (priority), today, tomorrow, weekdays, `next week`, `next month`, `in 3 days`, `Sept 25`, `15 April`, `25/9`, `2026-12-01`, `at 5pm`, `17:30`, `noon`, `midnight`, `tomorrow morning/afternoon/evening`.

Added by `ThingsNaturalLanguage`:

- When: the parsed date becomes the When (today or a future day). `this evening`, `tonight`, `ce soir` give This Evening. `someday` gives Someday, `un jour` or `un de ces jours` at the end of the line too. Someday wins over any date.
- Reminder: a clock time gives an absolute reminder at that time on the When day (`tomorrow at 5pm`, `demain soir` gives 19:00).
- Deadline: a date right after `by`, `due`, `due on`, `due by`, `deadline`, `before`, `avant`, `pour`, `d'ici`, `echeance` (optional `le`). Several dates work (`tomorrow by friday`).
- Estimate: `~30m`, `~1h`, `~1h30`, `~1.5h`, `~2 hours`, `~90` (minutes). Stored with `EstimateMarker` in the notes.
- Repeat: `daily weekly monthly yearly`, `every day|week|month|year`, `every 2 weeks`, `every other week`, `every monday` (weekly, first on that weekday). A repeat with no date starts today.
- French, translated to the parser's English before parsing: `aujourd'hui`, `demain`, `apres-demain`, `lundi` to `dimanche` (+ `prochain`, `matin`, `soir`, `apres-midi`), `dans 3 jours`, `dans 2 semaines`, `la semaine prochaine`, `le mois prochain`, `le 15 avril`, `a 17h`, `17h30`, `a midi`, `a minuit`, `tous les jours`, `chaque semaine`, `toutes les 2 semaines`, `chaque mois`, `tous les ans`, `quotidien`, `hebdomadaire`, `mensuel`, `annuel`. A bare `2h` is a duration, not a time. A French word right after a sigil (`+Demain`) is left alone.

Not supported: `*` or `#` creating a missing tag or project (unknown names stay in the title), several reminders, weekday sets (`every weekday`), end dates.

## Type Travel (macOS)

`ThingsTypeTravel` (root `onKeyPress`) opens Quick Find with the typed characters when no text field is being edited, no card or new to-do row is open, no sheet or alert is up, and the key has no Cmd/Ctrl/Opt. Arrows, Return, Esc, Tab, Delete, function keys and a leading space never start it. It also gives the list the keyboard focus after launch or a route change when nothing has it (the sidebar keeps it if it has it), because SwiftUI only delivers keys to the root when some view is focused.

Quick Find is now an overlay card (not a sheet) in `ThingsMacSheets`. Results: default lists, then To-Dos, Projects and Areas, Tags. Return opens, Esc closes, arrows move. Choosing a tag keeps the card open on the to-dos carrying that tag; Delete on an empty field leaves the tag.

## Things other agents may want

- `ThingsMacModel.showQuickFind` and `listFocusToken` are used as they are. No new field was added to `ThingsMacModel`; the typed characters travel in `ThingsQuickFindSeed.shared`.
- `ThingsMacCommands` could add a menu item for Quick Find that sets `showQuickFind` (already there).
- Localizable.xcstrings: those keys now have French (see docs/localization.md).

## DEVIATIONS.md rows to merge (file is shared, not edited here)

| Spec | Écart | Statut |
|-|-|-|
| 04 section 6 (Type Travel) | Fait sur Mac par un `onKeyPress` à la racine, sans combinaison requise. Les premières touches tapées pendant l'ouverture de la carte peuvent être perdues. Quick Find est une carte en surimpression, pas une fenêtre. Pas de "Continue Search", pas de Cmd-Return, pas de headings. Pas de Type Travel sur iPhone. | stopgap |
| 04 section 5 and 02 (langage naturel) | Le langage naturel remplace en partie les boutons When, Deadline et tags du Quick Entry. Syntaxe : voir WIRING-AGENT3.md. Les tags et projets inconnus ne sont pas créés. Un rappel utilise l'heure tapée sur le jour du When. | stopgap |
