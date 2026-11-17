# Target architecture (Things-like fork)

Reference document. Every PR must respect this document; if it is wrong, we fix it in the same PR.
Details and justifications: `docs/architecture-audit/`. Visual and behavioural specification: `docs/things-spec/`.

## Product goal

Native iOS and macOS client for a Vikunja server, whose interface reproduces Things 3 screen by screen, gesture by gesture, shortcut by shortcut. The mDone features that Things lacks (natural language, focus, improved calendar, kanban, estimated duration, postponing, priorities) are added afterwards, in the Things style.

Display name: **Fern** (`MDONE_DISPLAY_NAME` in `project.yml`). The Swift module, the targets and the identifiers (`com.mdone.app`) keep `mDone` to limit merge noise with upstream. On the data side, we reuse Vikunja's names and reserved labels stay minimal.

## Non-negotiable rules

1. A single Swift module `mDone` for both platforms. The layers are folders.
2. Dependencies only point downwards (see "Layers"). `scripts/check-layering.sh` verifies this in CI.
3. No product logic in a view. Views read an `@Observable @MainActor` ViewModel or pure Domain state.
4. The Domain is pure: Foundation only, deterministic functions `(inputs, now, calendar) -> output`, testable without a simulator.
5. Every visual value comes from `DesignSystem/Tokens`. No hard-coded colour, size or animation duration in a view.
6. Every Things behaviour is referenced by its section number in `docs/things-spec/`. Deviations are noted in `docs/things-spec/DEVIATIONS.md`.
7. The SwiftData models (`CachedTask`, `CachedProject`, `CachedLabel`, `FocusRecord`, `PendingOperation`) do not change schema without a migration (risk of losing the offline queue).
8. No em-dash and no double hyphen in text, code and docs.
9. The code cannot be compiled on the dev server: everything goes through the macOS CI. One PR = one topic, small, compiled by CI before starting the next one.
10. Every visible string is in a String Catalog (`mDone/Localizable.xcstrings`) with the English text as key. One sentence is one whole key: no concatenation, no `count == 1 ?`. `scripts/check-things-localization.py` checks this for the Things code.
11. The module stays on Swift 5.9. New code avoids what will become an error in Swift 6: static properties of a non-`Sendable` type, non-`Sendable` captures in a `@Sendable` closure, `NSEvent` or `NotificationCenter` monitors that touch isolated state without going back through `@MainActor`.
12. Language: all documentation, code comments and app source strings are English. Translations (for example the French values in `mDone/Localizable.xcstrings`, see `docs/localization.md`) are optional regional additions and never the source.

## Structure

Actual state. The screens from before the fork (`MainTabView`, `MacContentView`, `Features/TaskList`, ...) remain and serve as a fallback when the `thingsUIEnabled` setting is false.

```
mDone/
  App/            entry point, composition, AppState (facade, not yet slimmed down), intents
  Core/
    Models/       VTask, Project, VLabel, Bucket...
    Networking/   APIClient, Endpoint, *Service (actors), Auth
    Persistence/  SwiftData, ModelStoreBootstrap
    Sync/         SyncService, operation queue, NetworkMonitor
    Preferences/  typed keys and *Preference types (SmartParsingPreference: on by default)
  Domain/
    ThingsLists/  ThingsListBuilder: Inbox, Today (+ This Evening), Upcoming, Anytime, Someday, Logbook
    Mapping/      Things encoding onto Vikunja (things-spec/07): When, Deadline, checklist, headings,
                  project tree and Areas, move targets, natural language (ThingsNaturalLanguage)
    Scheduling/ Repeat/ Parser/ Filtering/ Focus/
  DesignSystem/
    Tokens/       ThingsColors, ThingsMetrics (including Sidebar), ThingsTypography, ThingsMotion, ThingsIcons
    Components/   generic components from before the fork, and Things/ (checkbox, to-do row, headers,
                  event box, Magic Plus)
  Features/
    Things/       iPhone screens (Home, list, project), ViewModels (ThingsListViewModel and its
                  NaturalLanguage and Reorder extensions, ThingsHomeViewModel), ThingsRowMapper,
                  ThingsQuickFindEngine, ThingsShortcutTable, ThingsRoute, drag and drop plans (pure)
    Board/ Calendar/ Focus/ Notifications/ Projects/ QuickAdd/ Settings/ Setup/ TaskDetail/ TaskList/
  Platform/
    iOS/          ThingsRootView (iPhone shell), FocusManager, MainTabView, ShakeDetector
    macOS/        Things*: window (ThingsMacRootView, ThingsMacModel), sidebar, list, editor, popovers,
                  menu commands, Quick Entry (NSPanel), Quick Find (card), Type Travel; and the old
                  window (MacContentView, ...)
  Resources/
mDoneShared/      shared with the extensions, imports nothing from mDone/
mDoneWidgets/, mDoneMacWidgets/
mDoneTests/       Domain/ and Features/ for the Things tests, the rest flat (AppState, services, intents)
localization/     flat files per language (fr.json, zh-Hans.json), see docs/localization.md
docs/             ARCHITECTURE.md, ROADMAP.md, localization.md, things-spec/ (spec, DEVIATIONS.md, WIRING-*.md),
                  architecture-audit/
scripts/          check-layering.sh, check-things-localization.py, localization.py, update-string-catalogs.sh
```

## Layers

```
Core/Models, Domain  <  Core/(Networking, Persistence, Sync, Preferences)  <  Features, DesignSystem  <  Platform  <  App
```

Detailed rules per folder: `docs/architecture-audit/04-proposed-structure.md` §5.

### Verification: `scripts/check-layering.sh`

Run by `ci-build.yml` (job `layering`, Ubuntu). It greps, leaving comment lines out:

- Core/Models and Domain: no import of SwiftUI, UIKit, AppKit, SwiftData, EventKit, no `AppState` and no `UserDefaults.standard`;
- Core/Networking: no import of UIKit, AppKit, SwiftUI;
- DesignSystem: no `AppState` and no `SwiftData`;
- Features and DesignSystem: no Things Platform type (`ThingsMac*`, Quick Entry, Type Travel, `ThingsRootView`), DesignSystem without a Things ViewModel;
- Core and Domain: no Things ViewModel, mapper, engine or shortcut table;
- mDoneShared: no import of `mDone` and no `@testable`.

Without the strict option, the script warns and returns 0. The known violations predate the fork (`Core/Models/Label.swift`, `CalendarEvent.swift`, `VNotification.swift`, `Domain/Focus/FocusHistoryQuery.swift`, `Core/Networking/WebAuthenticator.swift`, `DesignSystem/Components/TaskRow.swift`). The Things code adds none of them; enabling the strict option requires handling those first.

### Drag and drop and reordering

Documented by the batch that carries them (`docs/things-spec/WIRING-AGENT1.md`, `WIRING-AGENT2.md`, and the accompanying drag and drop spec). Nothing is described here, to avoid two sources.

## Conventions

- File naming: one main type per file, named after the type. View: `XxxView`, ViewModel: `XxxViewModel`, pure Domain function: `XxxRules`/`XxxBuilder`.
- Platform: `#if os()` only in `Platform/` or for small modifiers. Otherwise, two views, one per platform, sharing the ViewModel.
- Tests: every Domain rule has unit tests. Every screen has one preview per state (empty, filled, dark).
- Changelog: `CHANGELOG.md` under `[Unreleased]`.
- Commits: conventional commits, branches `things/<topic>`, PRs to `things-redesign`.

## Test environments

- Compilation and tests: GitHub Actions (`macos-latest`), workflows `ci-build.yml` (fast, on every push), `ios-tests.yml`, `macos-tests.yml`.
- Disposable Vikunja server: `docker-compose.dev.yml` + `scripts/seed-dev-vikunja.sh`.
- Device: free Apple account, 7-day signing (AltStore or Xcode). Widgets and Live Activities need entitlements validated on device.
