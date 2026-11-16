import Foundation

/// Where a Things navigation stack can go. Shared by the Home screen (which
/// creates the links) and the shell that resolves them (Platform/iOS).
enum ThingsRoute: Hashable {
    /// One of the built-in lists.
    case list(ThingsList)
    /// A project or an Area, by Vikunja project id.
    case project(Int64)
}
