import XCTest
@testable import TheMovieDB

@MainActor
final class HomeInteractorTests: XCTestCase {

    // MARK: - init

    func test_init_doesNotRequestNorPresentAnything() async {
        let (_, presenter, api) = makeSUT()

        XCTAssertTrue(api.requestedEndpoints.isEmpty)
        XCTAssertTrue(presenter.messages.isEmpty)
    }

    // MARK: - viewDidLoad

    func test_viewDidLoad_requestsFirstPageOfNowPlaying() async {
        let (sut, presenter, api) = makeSUT()
        api.stub(PagedResponse<Movie>.fixture())

        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(api.requestedEndpoints, [.nowPlaying(page: 1)])
    }

    func test_viewDidLoad_deliversMappedItemsOnSuccess() async {
        let (sut, presenter, api) = makeSUT()
        api.stub(PagedResponse<Movie>.fixture(movies: Movie.fixtures(ids: 1...3)))

        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(presenter.messages, [
            .loading(true),
            .initial(title: String(localized: "home.title"), items: .fixtures(ids: 1...3), isLoading: false),
            .loading(false)
        ])
    }

    func test_viewDidLoad_usesLocalizedFallbackTitleForMovieWithoutTitle() async {
        let (sut, presenter, api) = makeSUT()
        api.stub(PagedResponse<Movie>.fixture(movies: [.fixture(id: 7, title: nil)]))

        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(initialItems(in: presenter).map(\.title), [String(localized: "movie.noTitle")])
    }

    func test_viewDidLoad_deliversErrorMessageOnFailure() async {
        let (sut, presenter, api) = makeSUT()
        api.stub(error: error(withMessage: "Server Error"))

        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(presenter.messages, [.loading(true), .error("Server Error"), .loading(false)])
    }

    func test_viewDidLoad_calledTwice_cancelsFirstLoadWithoutPresentingAnError() async {
        let (sut, presenter, api) = makeSUT()
        api.stub(PagedResponse<Movie>.fixture())
        api.holdRequests()

        await waitForRequests(count: 2, on: api) {
            sut.viewDidLoad()
            sut.viewDidLoad()
        }
        // Both loads already presented `loading(true)`; releasing yields the cancelled load's
        // `loading(false)`, plus the second load's `initial` and `loading(false)`.
        await perform({ api.releaseHeldRequests() }, untilPresenterReceives: 3, presenter)

        let errors = presenter.messages.filter { if case .error = $0 { return true } else { return false } }
        let initials = presenter.messages.filter { if case .initial = $0 { return true } else { return false } }
        XCTAssertTrue(errors.isEmpty, "A cancelled load must not surface as an error")
        XCTAssertEqual(initials.count, 1)
    }

    // MARK: - loadMoreIfNeeded

    func test_loadMoreIfNeeded_requestsNextPageAndAppendsItemsWhenNearEnd() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 5)
        api.stub(PagedResponse<Movie>.fixture(page: 2, movies: Movie.fixtures(ids: 4...6)))

        await perform({ sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3) }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(api.requestedEndpoints, [.nowPlaying(page: 1), .nowPlaying(page: 2)])
        XCTAssertEqual(presenter.messages.dropFirst(3), [.loading(true), .append(.fixtures(ids: 4...6)), .loading(false)])
    }

    func test_loadMoreIfNeeded_requestsConsecutivePages() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 5)
        api.stub(PagedResponse<Movie>.fixture(page: 2, movies: Movie.fixtures(ids: 4...6)))
        api.stub(PagedResponse<Movie>.fixture(page: 3, movies: Movie.fixtures(ids: 7...9)))

        await perform({ sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3) }, untilPresenterReceives: 3, presenter)
        await perform({ sut.loadMoreIfNeeded(visibleIndex: 5, totalCount: 6) }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(api.requestedEndpoints, [.nowPlaying(page: 1), .nowPlaying(page: 2), .nowPlaying(page: 3)])
    }

    func test_loadMoreIfNeeded_doesNotRequestWhenFarFromTheEnd() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 5)

        await expectNoRequest(on: api) { sut.loadMoreIfNeeded(visibleIndex: 3, totalCount: 10) }
    }

    func test_loadMoreIfNeeded_requestsRightAtThePrefetchThreshold() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 5)
        api.stub(PagedResponse<Movie>.fixture(page: 2, movies: Movie.fixtures(ids: 4...6)))

        await perform({ sut.loadMoreIfNeeded(visibleIndex: 4, totalCount: 10) }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(api.requestedEndpoints.last, .nowPlaying(page: 2))
    }

    func test_loadMoreIfNeeded_doesNotRequestWhenAlreadyOnLastPage() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 1)

        await expectNoRequest(on: api) { sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3) }
    }

    func test_loadMoreIfNeeded_calledRepeatedlyWhileRequestIsInFlight_requestsNextPageOnlyOnce() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 5)
        api.stub(PagedResponse<Movie>.fixture(page: 2, movies: Movie.fixtures(ids: 4...6)))
        api.holdRequests()

        // `willDisplay` fires for several cells in a row, all before the first request completes.
        await waitForRequests(count: 2, on: api) {
            sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
            sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
            sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
        }
        await expectNoRequest(on: api) {}
        // `loading(true)` was already presented; releasing yields `append` and `loading(false)`.
        await perform({ api.releaseHeldRequests() }, untilPresenterReceives: 2, presenter)

        XCTAssertEqual(api.requestedEndpoints, [.nowPlaying(page: 1), .nowPlaying(page: 2)])
    }

    func test_loadMoreIfNeeded_deliversErrorMessageWhenNextPageFails() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 5)
        api.stub(error: error(withMessage: "Not Found"))

        await perform({ sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3) }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(presenter.messages.dropFirst(3), [.loading(true), .error("Not Found"), .loading(false)])
    }

    func test_loadMoreIfNeeded_afterFailure_retriesTheSameNextPage() async {
        let (sut, presenter, api) = makeSUT()
        await loadFirstPage(sut, presenter, api, totalPages: 5)
        api.stub(error: anyNSError())
        api.stub(PagedResponse<Movie>.fixture(page: 2, movies: Movie.fixtures(ids: 4...6)))

        await perform({ sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3) }, untilPresenterReceives: 3, presenter)
        await perform({ sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3) }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(api.requestedEndpoints, [.nowPlaying(page: 1), .nowPlaying(page: 2), .nowPlaying(page: 2)])
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: HomeInteractor, presenter: HomePresenterSpy, api: APIClientStub) {
        let presenter = HomePresenterSpy()
        let api = APIClientStub()
        let sut = HomeInteractor(presenter: presenter, api: api)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        trackForMemoryLeaks(api, file: file, line: line)
        return (sut, presenter, api)
    }

    private func error(withMessage message: String) -> NSError {
        NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func initialItems(in presenter: HomePresenterSpy) -> [Home.ItemViewModel] {
        for case let .initial(_, items, _) in presenter.messages { return items }
        return []
    }

    /// Loads page 1 (3 items) and waits for its 3 presenter messages.
    private func loadFirstPage(
        _ sut: HomeInteractor,
        _ presenter: HomePresenterSpy,
        _ api: APIClientStub,
        totalPages: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        api.stub(PagedResponse<Movie>.fixture(page: 1, movies: Movie.fixtures(ids: 1...3), totalPages: totalPages))
        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter, file: file, line: line)
    }

    /// Runs `action` and suspends until the presenter has received `count` more messages.
    private func perform(
        _ action: () -> Void,
        untilPresenterReceives count: Int,
        _ presenter: HomePresenterSpy,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let exp = expectation(description: "Wait for \(count) presenter messages")
        let target = presenter.messages.count + count
        presenter.onMessage = { if presenter.messages.count == target { exp.fulfill() } }

        action()

        await fulfillment(of: [exp], timeout: 1.0)
        presenter.onMessage = nil
    }

    /// Runs `action` and suspends until the API has received `count` requests in total.
    private func waitForRequests(count: Int, on api: APIClientStub, when action: () -> Void) async {
        let exp = expectation(description: "Wait for \(count) requests")
        api.onRequest = { if api.requestedEndpoints.count == count { exp.fulfill() } }

        action()

        await fulfillment(of: [exp], timeout: 1.0)
        api.onRequest = nil
    }

    /// Runs `action` and asserts the API gets no request shortly after.
    private func expectNoRequest(
        on api: APIClientStub,
        file: StaticString = #filePath,
        line: UInt = #line,
        when action: () -> Void
    ) async {
        let exp = expectation(description: "No request expected")
        exp.isInverted = true
        api.onRequest = { exp.fulfill() }

        action()

        await fulfillment(of: [exp], timeout: 0.1)
        api.onRequest = nil
    }
}
