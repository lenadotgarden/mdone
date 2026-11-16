import XCTest
@testable import mDone

/// A failed reorder, a stray 401 or a refresh that finds nothing new must never
/// end the user's session. Only a rejected refresh token does (that path is
/// covered by `APIClientRefreshTests`).
@MainActor
final class SessionStabilityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    private let project = Project(
        id: 7,
        title: "Work",
        views: [ProjectView(id: 100, title: "List", projectId: 7, viewKind: "list")]
    )

    private func makeState(client: APIClient) -> AppState {
        let state = AppState(
            taskService: TaskService(apiClient: client),
            projectService: ProjectService(apiClient: client),
            labelService: LabelService(apiClient: client)
        )
        state.isAuthenticated = true
        state.projects = [project]
        var first = VTask(id: 1, title: "A", done: false, priority: 0, projectId: 7)
        first.position = 100
        var second = VTask(id: 2, title: "B", done: false, priority: 0, projectId: 7)
        second.position = 200
        state.tasks = [first, second]
        return state
    }

    /// Cmd-Opt-Up on the second row: the server refuses with each client error.
    func testRefusedPositionUpdateKeepsTheSessionAndTheOrder() async {
        for status in [400, 403, 404, 422] {
            let client = MockURLProtocol.mockClient()
            await client.configure(
                serverURL: "https://mock.vikunja.io",
                token: "tk_apikey_abcdef123456"
            )
            let expired = ExpiryFlag()
            await client.setOnSessionExpired { expired.mark() }
            let state = makeState(client: client)

            MockURLProtocol.requestHandler = { request in
                (MockURLProtocol.makeResponse(statusCode: status, url: request.url), Data())
            }

            let moved = state.tasks[1]
            let ok = await state.moveTask(moved, toPosition: 50, newOrder: [moved, state.tasks[0]])

            XCTAssertFalse(ok, "HTTP \(status) fails the move")
            XCTAssertTrue(state.isAuthenticated, "HTTP \(status) must not log the user out")
            XCTAssertFalse(expired.isSet, "HTTP \(status) must not fire the session expiry")
            XCTAssertEqual(state.tasks.count, 2, "No task may be dropped by a failed move")
        }
    }

    /// A refresh whose answer is a bare 401 (no session-expiry callback fired by
    /// the client) must not tear the session down from AppState on its own.
    func testRefreshAllNeverExpiresTheSessionByItself() async {
        let client = MockURLProtocol.mockClient()
        await client.configure(serverURL: "https://mock.vikunja.io", token: "tk_apikey_abcdef123456")
        let state = makeState(client: client)

        MockURLProtocol.requestHandler = { request in
            (MockURLProtocol.makeResponse(statusCode: 401, url: request.url), Data())
        }
        await state.refreshAll()

        XCTAssertTrue(state.isAuthenticated)
        XCTAssertEqual(state.tasks.count, 2, "Local data stays after a failed refresh")
    }

    /// Two refreshes asked together run as one.
    func testConcurrentRefreshesShareOneDownload() async {
        let client = MockURLProtocol.mockClient()
        await client.configure(serverURL: "https://mock.vikunja.io", token: "tk_apikey_abcdef123456")
        let state = makeState(client: client)

        MockURLProtocol.requestHandler = { request in
            (MockURLProtocol.makeResponse(statusCode: 200, url: request.url), MockURLProtocol.page("[]"))
        }
        async let first: Void = state.refreshAll()
        async let second: Void = state.refreshAll()
        _ = await (first, second)

        let taskRequests = MockURLProtocol.capturedRequests.filter { $0.url?.path == VikunjaAPI.path("/tasks") }
        XCTAssertEqual(taskRequests.count, 1, "The second caller must join the refresh in flight")
    }

    /// Returning to the app right after a refresh does not download again.
    func testRefreshIfStaleSkipsARecentRefresh() async {
        let client = MockURLProtocol.mockClient()
        await client.configure(serverURL: "https://mock.vikunja.io", token: "tk_apikey_abcdef123456")
        let state = makeState(client: client)

        MockURLProtocol.requestHandler = { request in
            (MockURLProtocol.makeResponse(statusCode: 200, url: request.url), MockURLProtocol.page("[]"))
        }
        await state.refreshAll()
        let afterFirst = MockURLProtocol.capturedRequests.count
        XCTAssertGreaterThan(afterFirst, 0)

        await state.refreshAllIfStale(minInterval: 30)
        XCTAssertEqual(MockURLProtocol.capturedRequests.count, afterFirst, "A fresh list is not downloaded again")

        await state.refreshAllIfStale(minInterval: 0)
        XCTAssertGreaterThan(MockURLProtocol.capturedRequests.count, afterFirst, "A stale list is")
    }
}

private final class ExpiryFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    var isSet: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func mark() {
        lock.lock()
        defer { lock.unlock() }
        value = true
    }
}
