# Wiring notes, agent B (localization, preference, Swift 6, tokens, docs)

Code written without a compiler. To be checked by the macOS CI.

## What changed

- Localization: French for every Things string, see `docs/localization.md` (section Things) and DEVIATIONS.md (Transverse). `scripts/check-things-localization.py` runs in CI.
- `SmartParsingPreference.defaultValue` is `true`. `ThingsNaturalLanguagePreference` is gone: use `SmartParsingPreference.isEnabled()`.
- Concatenated sentences became whole keys: `Go to %@` (ThingsMacCommands), `Deadline %@` and `Priority %lld` (chips of `ThingsNaturalLanguage`), estimates `%lld min`, `%lld h`, `%lld h %lld`.
- `ThingsCheckboxState.open` reads "Incomplete" for VoiceOver (the key "Open" is the menu verb).
- `ThingsMagicPlusButton` moved from `Platform/iOS` to `DesignSystem/Components/Things` (Features cannot depend on Platform).
- `APIClient` no longer captures `ISO8601DateFormatter` in a `@Sendable` closure (private `APIDateParser`, `@unchecked Sendable`, never mutated after init).

## For the sidebar owner (ThingsMacSidebar.swift, not edited here)

`ThingsSidebarStyle` can adopt the tokens that now exist:

| Local constant | Token |
|-|-|
| `groupGap` | `ThingsMetrics.Sidebar.groupGap` (16) |
| `highlightRadius` | `ThingsMetrics.Sidebar.selectionCornerRadius` (6) |
| `levelIndent` | `ThingsMetrics.Sidebar.levelIndent` (16) |
| `chevronWidth` | `ThingsMetrics.Sidebar.chevronWidth` (10) |
| `selectionOpacity` (textPrimary at 0.12) | `ThingsColorToken.bgSidebarSelection` |

WIRING-AGENT1.md section 3 asked for a new `sidebarSelection` token. `bgSidebarSelection` already exists (dark 0x3B3E42 measured, light 0xDADDE3), so no duplicate was added. Use `ThingsPalette(scheme)[.bgSidebarSelection]` as the row fill and delete `selectionOpacity`.

## Swift 6 review of the Things files

Reviewed for captured vars in `@Sendable` closures, non-Sendable captures, main-actor statics, Timer and NSEvent monitors. Findings, none changed:

- Statics in tokens are `CGFloat`, `Font`, `Animation`, `Double`: Sendable.
- `ThingsNaturalLanguage` holds `NSRegularExpression` statics; the existing parsers do the same.
- `ThingsQuickEntryController` is `@MainActor`; the global key monitor and the activation observer copy a `UInt16` and hop with `Task { @MainActor in }`. No `Timer` anywhere in Things.
- `ThingsTypeTravel` uses `MainActor.assumeIsolated` inside `onKeyPress` (called on the main thread by SwiftUI).
- Skipped: `mDoneApp.swift:104` (`[weak appState]` on an `@State` property of the App struct). The exact diagnostic is unknown without a compiler and the closure feeds `FocusManager.taskLookup`; changing it blind risks a behaviour change.
