# Roadmap

Status: `[ ]` to do, `[~]` in progress, `[x]` done. Each milestone is validated by the macOS CI before the next one. All the Things code was written without a compiler: `[x]` only means "done" for what is green in CI.

## Phase 0 - Foundations
- [x] Fork, Things spec (`docs/things-spec/`), audit (`docs/architecture-audit/`)
- [x] ARCHITECTURE.md, fast build CI (ci-build.yml), layering script (`scripts/check-layering.sh`, warnings only until the violations from before the fork are resolved)
- [x] Steps 1 to 4 of the move plan (iOS + macOS CI green on f858e26)
- [ ] Steps 5 to 9 (Domain extracted, AppState split, typed preferences)

## Phase 1 - Things Domain (tested in CI, no UI)
- [x] Vikunja mapping (Domain/Mapping, tests green in CI)
- [x] Inbox, Today, Upcoming, Anytime, Someday, Logbook lists (tests green in CI)
- [~] Project tree and Areas, move targets, drag and drop payload (`ThingsProjectTree`, `ThingsMoveTargets`, `ThingsDragPayload`), natural language (`ThingsNaturalLanguage`): written with tests, not validated by the CI
- [ ] Repetition (fixed / after completion), reminders

## Phase 2 - DesignSystem
- [~] Tokens (values to calibrate against real screenshots; warm dark palette, `ThingsMetrics.Sidebar`)
- [~] Components written, previews to validate, Magic Plus (tap only)

## Phase 3 - iPhone
- [~] Home, Today, Upcoming, Anytime, Someday, Logbook, Area, Project (written, not validated by the CI: project/area flat, without headings)
- [ ] Expanded to-do, When/Deadline/Tags pickers, Move, Quick Find
- [~] Gestures: swipe right for When, Magic Plus tap, shake (undo) done; drag, Magic Plus dragging and multi-selection still to do

## Phase 4 - Mac
- [~] Window, tree sidebar, lists, expanded editor, popovers for When, Deadline, Tags, Move (written, not validated by the CI nor on a Mac)
- [~] Quick Entry (panel, global monitor subject to Accessibility access), Quick Find (overlay card), Type Travel: written, not validated
- [~] Shortcuts: tested table (`ThingsShortcutTable`), menu commands written; what remains is listed in DEVIATIONS.md
- [~] Reordering and drag and drop (list, sidebar): see DEVIATIONS.md, batch in progress

## Phase 5 - mDone features in the Things style
- [~] Natural language (English and French, on by default) done on the Things side
- [ ] Focus, postponing, estimated duration, improved calendar, kanban, widgets, Siri in the Things style

## Cross-cutting
- [x] French for all Things strings (`localization/fr.json`, `scripts/check-things-localization.py`); the rest of the app stays in English and Simplified Chinese
- [ ] Swift 6: the project stays on Swift 5.9; the Things files were re-read (WIRING-AGENT-B.md), one warning from `mDoneApp.swift` remains

## Phase 6 - iPad
