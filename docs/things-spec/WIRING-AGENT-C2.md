# Wiring notes, agent C2 (project hierarchy)

Changes other owners must apply (files agent C2 does not own). Nothing here blocks the build: the feature works without them, except item 1 which is the cause of the flat tree after a relaunch.

## 1. Core/Persistence/CacheService.swift: CachedProject drops `parentProjectId` (root cause)

`CachedProject` has no parent column, so every project read back from the cache (`SyncService.loadCachedProjects`, used at launch before the network answers, offline, and when the first fetch fails) comes back with `parentProjectId == nil`. The tree is then flat: no Areas, no sub-projects, until `refreshAll` succeeds. `SyncService.updateCachedProject` rewrites the cached row without the parent as well.

Exact patch (an added optional attribute is a lightweight SwiftData migration, no data loss, no `PendingOperation` change):

```swift
// CachedProject
var parentProjectId: Int64?          // new, after `updated`

// init(from:)
parentProjectId = project.parentProjectId
// update(from:)
parentProjectId = project.parentProjectId
// toProject(): add the argument, in declaration order, after `updated: updated`
parentProjectId: parentProjectId
```

`Project.init` order is `id, title, description, hexColor, isArchived, isFavorite, position, owner, created, updated, parentProjectId, ...`. Add a test next to `ProjectServiceTests`: `CachedProject(from: Project(id: 3, title: "Sub", parentProjectId: 2)).toProject().parentProjectId == 2`.

## 2. Core/Preferences/DefaultProjectPreference.swift: Inbox fallback

`resolve(in:)` falls back to `candidates.first` when no project is titled "Inbox" and no default is stored. That can be a root project with a whole subtree (Lena has none called Inbox in some accounts). The tree no longer hides a project that has children (`ThingsProjectTree.build`), but the Inbox list and quick add would still target that project. Suggested: in the last fallback prefer the first root project without children (`parentProjectId` nil or 0 and not a parent of any other project), then `candidates.first`.

## 3. ThingsMacModel.swift / ThingsMacModel+Actions.swift (agent A)

- `collapsedProjectIDs`, `toggleCollapsed`, `setAllCollapsed` are no longer used by the sidebar, which reads `AppState.collapsedProjectIDs` (persisted, shared with the iPhone). They can be deleted. If they stay, make `setAllCollapsed` call `appState.setAllProjectsExpanded(!collapsed, tree: projectTree)` and `toggleCollapsed` call `appState.toggleProjectFold(_:)`.
- `moveProject(_:toParent:)`: replace `if let parentID = parentID { collapsedProjectIDs.remove(parentID) }` with `if let parentID = parentID { appState.setProjectExpanded(true, for: parentID) }`, so a project moved from the Move popover (Shift-Cmd-M) is not hidden under a folded parent. The drop paths already do this.

## 4. ThingsMacRootModifiers.swift: ThingsMacNewListSheet (agent A)

New Project now nests under the Area or project on screen without any change there: the screens set `ThingsHomeViewModel.parentForNewProject` and `model.createProject(title:isArea:)` already goes through `home.createProject`. Optional: show the target in the sheet, for example a secondary line "In <title>" read from `model.home.parentForNewProject` and `model.appState.projects`. New Area is always a root project.

## 5. DesignSystem tokens wanted (agent B)

Local constants stay in `ThingsMacSubprojectList.swift` (`ThingsSubprojectStyle`) and `ThingsMacSidebar.swift` until tokens exist:
- sub-project row: level indent 20, chevron slot 12, count badge radius 3 and horizontal padding 4;
- sidebar chevron resting opacity 0.55;
- drop insertion line: 2 pt accent capsule (`ThingsProjectDropFeedback`).

## 6. Other files that still use the marker-only Area rule (outside C2 ownership)

- `Features/Things/ThingsQuickFindEngine.swift` line `ThingsProjectMeta.isArea(project)`: use `ThingsProjectTree.build(...).node(id:)?.isArea` so an unmarked Area is listed as an Area in Quick Find.
- `Features/Things/ThingsListViewModel.swift` `quickAddProjectID` (Anytime): `ThingsProjectMeta.looseProjects` is marker based, so a root with sub-projects counts as a loose project. Use `ThingsProjectTree.build(...).looseProjects.first?.id`.

## 7. Localization

Added `Move Project...` (fr: `Déplacer le projet...`) to `mDone/Localizable.xcstrings` and `localization/fr.json`. `zh-Hans.json` has no entry yet; run `scripts/localization.py` if the file must list every key.
