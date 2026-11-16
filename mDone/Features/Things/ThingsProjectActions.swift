import Foundation

/// Body of `PUT /projects/{id}` that also carries `position`. `ProjectUpdateRequest` (Core)
/// has no position field, so a sibling reorder needs its own request. Like the Core one it
/// sends the project's full field set, so no column is blanked server side. Snake-casing is
/// applied by `APIClient`'s encoder.
struct ThingsProjectPlacementRequest: Encodable {
    var title: String
    var description: String
    var hexColor: String
    var isFavorite: Bool
    var isArchived: Bool
    /// 0 means top level.
    var parentProjectId: Int64
    var position: Double

    init(from project: Project, parentProjectId: Int64, position: Double) {
        self.title = project.title
        self.description = project.description ?? ""
        self.hexColor = project.hexColor ?? ""
        self.isFavorite = project.isFavorite ?? false
        self.isArchived = project.isArchived ?? false
        self.parentProjectId = parentProjectId
        self.position = position
    }
}

/// Project hierarchy actions of the Things UI, shared by Mac and iPhone: folding (persisted
/// by `AppState.collapsedProjectIDs`, absent = expanded) and placing a project between
/// siblings. Kept in an extension file so `AppState.swift` stays untouched.
extension AppState {
    // MARK: - Folding

    /// Folds or unfolds one project in the sidebar and the Area screens.
    func toggleProjectFold(_ id: Int64) {
        setProjectExpanded(!isProjectExpanded(id), for: id)
    }

    /// Folds every project that has children, or unfolds everything.
    func setAllProjectsExpanded(_ expanded: Bool, tree: ThingsProjectTree) {
        collapsedProjectIDs = expanded ? [] : Set(tree.expandableIDs)
    }

    // MARK: - Placement between siblings

    /// Moves a project under `placement.parentID` and writes the sibling positions.
    /// The local list changes first so the row lands at once; a failure restores it
    /// and shows the error banner. Returns whether the server accepted every write.
    ///
    /// The local cache of projects is not rewritten here (`SyncService` is private to
    /// `AppState`); the next refresh brings the server state back.
    @MainActor
    @discardableResult
    func placeProject(_ placement: ThingsProjectPlacement) async -> Bool {
        guard placement.projectID > 0 else { return false }
        let snapshot = projects
        apply(placement)
        do {
            for update in placement.updates {
                guard let project = snapshot.first(where: { $0.id == update.projectID }) else { continue }
                let isMoved = update.projectID == placement.projectID
                let parent: Int64 = isMoved ? (placement.parentID ?? 0) : (project.parentProjectId ?? 0)
                let request = ThingsProjectPlacementRequest(from: project, parentProjectId: parent, position: update.position)
                let _: Project = try await APIClient.shared.send(
                    Endpoint.updateProject(id: update.projectID),
                    body: request
                )
            }
            return true
        } catch {
            projects = snapshot
            let friendly = NetworkError.friendly(from: error)
            errorMessage = friendly.errorDescription
            activeError = friendly
            return false
        }
    }

    /// The local effect of a placement: new parent and positions.
    @MainActor
    private func apply(_ placement: ThingsProjectPlacement) {
        var updated = projects
        for update in placement.updates {
            guard let index = updated.firstIndex(where: { $0.id == update.projectID }) else { continue }
            updated[index].position = update.position
            if update.projectID == placement.projectID {
                updated[index].parentProjectId = placement.parentID
            }
        }
        projects = updated
    }
}
