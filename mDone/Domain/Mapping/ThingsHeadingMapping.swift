import Foundation

/// A Things heading, backed by a bucket of the `things-headings` view.
struct ThingsHeading: Equatable, Identifiable {
    /// The bucket id.
    let id: Int64
    /// The title to show (archived prefix removed).
    let title: String
    let isArchived: Bool
}

/// The tasks under one heading. `heading` is nil for the default bucket,
/// which holds the to-dos without a heading (07 section 3).
struct ThingsHeadingGroup: Equatable {
    let bucketId: Int64?
    let heading: ThingsHeading?
    let tasks: [VTask]
}

enum ThingsHeadingMapping {
    /// Title of the Kanban view whose buckets are the headings.
    static let viewTitle = "things-headings"

    /// Bucket title prefix that marks an archived heading.
    ///
    /// SPEC-UNSURE: 07 section 3 leaves archived headings open; the prefix
    /// variant is the one implemented here.
    static let archivedPrefix = "[archived]"

    // MARK: - View

    /// The `things-headings` Kanban view of `project`, nil when it has none.
    /// The title is matched ignoring case and surrounding whitespace.
    static func headingsView(in project: Project) -> ProjectView? {
        (project.views ?? []).first { view in
            view.viewKind == "kanban" && isHeadingsViewTitle(view.title)
        }
    }

    /// The id of the headings view, nil when the project has none.
    static func headingsViewId(in project: Project) -> Int64? {
        headingsView(in: project)?.id
    }

    static func isHeadingsViewTitle(_ title: String) -> Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == viewTitle
    }

    // MARK: - Buckets

    /// Buckets in heading order: position, then id.
    static func sortedBuckets(_ buckets: [Bucket]) -> [Bucket] {
        buckets.sorted { lhs, rhs in
            let lp = lhs.position ?? 0
            let rp = rhs.position ?? 0
            if lp != rp { return lp < rp }
            return lhs.id < rhs.id
        }
    }

    /// The bucket holding to-dos without a heading: the view's default bucket,
    /// else the project's, else the first bucket in order.
    static func defaultBucketId(view: ProjectView?, project: Project?, buckets: [Bucket]) -> Int64? {
        if let id = view?.defaultBucketId, id != 0 { return id }
        if let id = project?.defaultBucketId, id != 0 { return id }
        return sortedBuckets(buckets).first?.id
    }

    /// Whether a bucket title marks an archived heading.
    static func isArchivedTitle(_ title: String) -> Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix(archivedPrefix)
    }

    /// A bucket title as a heading title: archived prefix and spaces removed.
    static func displayTitle(of bucketTitle: String) -> String {
        let trimmed = bucketTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix(archivedPrefix) {
            let rest = trimmed.dropFirst(archivedPrefix.count)
            return String(rest).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }

    /// The bucket title that stores `title` as a heading.
    static func bucketTitle(forHeading title: String, archived: Bool) -> String {
        let clean = displayTitle(of: title)
        return archived ? archivedPrefix + " " + clean : clean
    }

    /// The heading for a bucket.
    static func heading(from bucket: Bucket) -> ThingsHeading {
        ThingsHeading(
            id: bucket.id,
            title: displayTitle(of: bucket.title),
            isArchived: isArchivedTitle(bucket.title)
        )
    }

    /// Headings in order, the default bucket excluded.
    static func headings(from buckets: [Bucket], defaultBucketId: Int64?) -> [ThingsHeading] {
        sortedBuckets(buckets)
            .filter { $0.id != defaultBucketId }
            .map { heading(from: $0) }
    }

    // MARK: - Grouping

    /// Tasks in display order: position, then id.
    static func sortedTasks(_ tasks: [VTask]) -> [VTask] {
        tasks.sorted { lhs, rhs in
            let lp = lhs.position ?? 0
            let rp = rhs.position ?? 0
            if lp != rp { return lp < rp }
            return lhs.id < rhs.id
        }
    }

    /// Groups `tasks` by their `bucketId`. The default bucket group comes
    /// first, then one group per heading in bucket order. A task without a
    /// bucket, or in an unknown one, falls in the default group. Headings
    /// with no task still get a (empty) group.
    static func groups(
        tasks: [VTask],
        buckets: [Bucket],
        defaultBucketId: Int64?
    ) -> [ThingsHeadingGroup] {
        let known = Set(buckets.map { $0.id })
        var byBucket: [Int64: [VTask]] = [:]
        var defaultTasks: [VTask] = []
        for task in tasks {
            if let id = task.bucketId, known.contains(id), id != defaultBucketId {
                byBucket[id, default: []].append(task)
            } else {
                defaultTasks.append(task)
            }
        }
        return assemble(
            buckets: buckets,
            defaultBucketId: defaultBucketId,
            defaultTasks: defaultTasks,
            byBucket: byBucket
        )
    }

    /// Groups the tasks embedded in `buckets` (each task belongs to the bucket
    /// that carries it, whatever its own `bucketId` says).
    static func groups(from buckets: [Bucket], defaultBucketId: Int64?) -> [ThingsHeadingGroup] {
        var byBucket: [Int64: [VTask]] = [:]
        var defaultTasks: [VTask] = []
        for bucket in buckets {
            if bucket.id == defaultBucketId {
                defaultTasks.append(contentsOf: bucket.allTasks)
            } else {
                byBucket[bucket.id, default: []].append(contentsOf: bucket.allTasks)
            }
        }
        return assemble(
            buckets: buckets,
            defaultBucketId: defaultBucketId,
            defaultTasks: defaultTasks,
            byBucket: byBucket
        )
    }

    private static func assemble(
        buckets: [Bucket],
        defaultBucketId: Int64?,
        defaultTasks: [VTask],
        byBucket: [Int64: [VTask]]
    ) -> [ThingsHeadingGroup] {
        var result: [ThingsHeadingGroup] = [
            ThingsHeadingGroup(
                bucketId: defaultBucketId,
                heading: nil,
                tasks: sortedTasks(defaultTasks)
            )
        ]
        for bucket in sortedBuckets(buckets) where bucket.id != defaultBucketId {
            result.append(
                ThingsHeadingGroup(
                    bucketId: bucket.id,
                    heading: heading(from: bucket),
                    tasks: sortedTasks(byBucket[bucket.id] ?? [])
                )
            )
        }
        return result
    }
}
