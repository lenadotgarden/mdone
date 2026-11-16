import XCTest
@testable import mDone

/// Completeness of the paged reads: a long account must arrive whole, whether
/// or not the server says how many pages there are.
final class APIClientPaginationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    private nonisolated static func pageNumber(of request: URLRequest) -> Int {
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems
        return Int(items?.first { $0.name == "page" }?.value ?? "1") ?? 1
    }

    private nonisolated static func tasks(_ range: ClosedRange<Int>) -> [[String: Any]] {
        range.map { ["id": $0, "title": "Task \($0)", "done": false, "priority": 0, "project_id": 1] as [String: Any] }
    }

    /// 120 tasks in pages of 50, with no `total_pages` in the envelope.
    func testAllPagesAreReadWhenTheServerGivesNoPageCount() async throws {
        let client = MockURLProtocol.mockClient()
        await client.configure(serverURL: "https://mock.vikunja.io", token: "test-token")
        MockURLProtocol.requestHandler = { request in
            let page = Self.pageNumber(of: request)
            let slices: [Int: ClosedRange<Int>] = [1: 1 ... 50, 2: 51 ... 100, 3: 101 ... 120]
            let items = slices[page].map { Self.tasks($0) } ?? []
            return (
                MockURLProtocol.makeResponse(statusCode: 200, url: request.url),
                MockURLProtocol.page(items, totalPages: nil)
            )
        }

        let tasks: [VTask] = try await TaskService(apiClient: client).fetchAllTasks(perPage: 200)

        XCTAssertEqual(tasks.count, 120)
        XCTAssertEqual(Set(tasks.map(\.id)).count, 120)
    }

    /// A server that ignores `page` must not loop: the repeated first item stops the walk.
    func testServerThatIgnoresThePageParameterDoesNotLoop() async throws {
        let client = MockURLProtocol.mockClient()
        await client.configure(serverURL: "https://mock.vikunja.io", token: "test-token")
        MockURLProtocol.requestHandler = { request in
            (
                MockURLProtocol.makeResponse(statusCode: 200, url: request.url),
                MockURLProtocol.page(Self.tasks(1 ... 50), totalPages: nil)
            )
        }

        let tasks: [VTask] = try await TaskService(apiClient: client).fetchAllTasks(perPage: 200)

        XCTAssertEqual(tasks.count, 50)
        XCTAssertLessThanOrEqual(MockURLProtocol.capturedRequests.count, 2)
    }

    /// With a page count, every page is read once, in order.
    func testCountedPagesAreAllRead() async throws {
        let client = MockURLProtocol.mockClient()
        await client.configure(serverURL: "https://mock.vikunja.io", token: "test-token")
        MockURLProtocol.requestHandler = { request in
            let page = Self.pageNumber(of: request)
            let start = (page - 1) * 50 + 1
            return (
                MockURLProtocol.makeResponse(statusCode: 200, url: request.url),
                MockURLProtocol.page(Self.tasks(start ... start + 49), totalPages: 4)
            )
        }

        let tasks: [VTask] = try await TaskService(apiClient: client).fetchAllTasks(perPage: 200)

        XCTAssertEqual(tasks.map(\.id), Array(1 ... 200).map { Int64($0) })
    }
}
