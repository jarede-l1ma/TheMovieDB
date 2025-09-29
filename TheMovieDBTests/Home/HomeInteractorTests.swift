import XCTest
@testable import TheMovieDB

@MainActor
final class HomeInteractorTests: XCTestCase {
    
    private var sut: HomeInteractor!
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testViewDidLoad_success() async {
        let doubles = Doubles()
        let expectedMovies = doubles.createMockMovies()
        let expectedResponse = PagedResponse(page: 1, results: expectedMovies, totalPages: 5, totalResults: 100)
        doubles.api.mockResponse = expectedResponse
        sut = makeSUT(doubles: doubles)
        
        sut.viewDidLoad()
        await waitForAsync()
        
        assertLoadingStates(doubles.presenter, loading: 2, initial: 1, error: 0)
        assertInitialPresentation(doubles.presenter, title: "Em cartaz", itemsCount: 3, isLoading: false)
        assertFirstItemMapping(doubles.presenter, id: 1, title: "Movie 1", subtitle: "2024-01-01", posterPath: "/poster1.jpg")
    }
    
    func testViewDidLoad_withNilTitle_usesDefaultTitle() async {
        let doubles = Doubles()
        let movieWithNilTitle = Movie(id: 1, title: nil, overview: "Overview", posterPath: "/poster.jpg",
                                      backdropPath: "/backdrop.jpg", releaseDate: "2024-01-01", voteAverage: 7.5)
        let expectedResponse = PagedResponse(page: 1, results: [movieWithNilTitle], totalPages: 1, totalResults: 1)
        doubles.api.mockResponse = expectedResponse
        sut = makeSUT(doubles: doubles)
        
        sut.viewDidLoad()
        await waitForAsync()
        
        assertFirstItemTitle(doubles.presenter, expectedTitle: "Sem título")
    }
    
    func testViewDidLoad_apiError() async {
        let doubles = Doubles()
        doubles.configureForError(NSError(domain: "TestError", code: 500,
                                          userInfo: [NSLocalizedDescriptionKey: "Server Error"]))
        sut = makeSUT(doubles: doubles)
        
        sut.viewDidLoad()
        await waitForAsync()
        
        assertLoadingStates(doubles.presenter, loading: 2, initial: 0, error: 1)
        assertErrorMessage(doubles.presenter, expectedMessage: "Server Error")
    }
    
    func testViewDidLoad_cancellation() async {
        let doubles = Doubles()
        doubles.configureForDelay()
        sut = makeSUT(doubles: doubles)
        
        sut.viewDidLoad()
        sut.viewDidLoad()
        
        await waitForAsync(duration: 0.2)
        
        XCTAssertGreaterThanOrEqual(doubles.presenter.presentLoadingCallCount, 2)
    }
    
    func testLoadMoreIfNeeded_shouldLoadWhenNearEnd() async {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        await setupInitialPageState(doubles: doubles)
        doubles.presenter.resetCalls()
        
        let nextPageMovies = doubles.createMockMovies(startId: 4)
        let nextPageResponse = PagedResponse(page: 2, results: nextPageMovies, totalPages: 5, totalResults: 100)
        doubles.api.mockResponse = nextPageResponse
        
        sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
        await waitForAsync()
        
        assertLoadingStates(doubles.presenter, loading: 2, append: 1)
        assertAppendedItems(doubles.presenter, expectedCount: 3, firstItemId: 4)
    }
    
    func testLoadMoreIfNeeded_shouldNotLoadWhenNotNearEnd() async {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        await setupInitialPageState(doubles: doubles)
        doubles.presenter.resetCalls()
        
        sut.loadMoreIfNeeded(visibleIndex: 0, totalCount: 10)
        await waitForAsync()
        
        assertNoLoadingTriggered(doubles.presenter)
    }
    
    func testLoadMoreIfNeeded_shouldNotLoadWhenAlreadyRequesting() async {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        await setupInitialPageState(doubles: doubles)
        doubles.resetCalls()
        
        let nextPageMovies = doubles.createMockMovies(startId: 4)
        let nextPageResponse = PagedResponse(page: 2, results: nextPageMovies, totalPages: 5, totalResults: 100)
        doubles.api.mockResponse = nextPageResponse
        doubles.api.shouldDelay = true
        
        let initialRequestCount = doubles.api.requestCallCount
        
        sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
        await waitForAsync(duration: 0.05)
        
        let firstRequestCount = doubles.api.requestCallCount - initialRequestCount
        
        sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
        await waitForAsync(duration: 0.2)
        
        let totalNewRequests = doubles.api.requestCallCount - initialRequestCount
        
        XCTAssertEqual(firstRequestCount, 1, "First loadMore should trigger a request")
        XCTAssertEqual(totalNewRequests, 1, "Second loadMore should be ignored while first is in progress")
    }
    
    func testLoadMoreIfNeeded_shouldNotLoadWhenOnLastPage() async {
        let doubles = Doubles()
        doubles.configureForLastPage()
        sut = makeSUT(doubles: doubles)
        sut.viewDidLoad()
        await waitForAsync()
        doubles.presenter.resetCalls()
        
        sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
        await waitForAsync()
        
        assertNoLoadingTriggered(doubles.presenter)
    }
    
    func testLoadMoreIfNeeded_apiError() async {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        await setupInitialPageState(doubles: doubles)
        doubles.presenter.resetCalls()
        doubles.configureForError(NSError(domain: "TestError", code: 404,
                                          userInfo: [NSLocalizedDescriptionKey: "Not Found"]))
        
        sut.loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)
        await waitForAsync()
        
        assertLoadingStates(doubles.presenter, loading: 2, append: 0, error: 1)
        assertErrorMessage(doubles.presenter, expectedMessage: "Not Found")
    }
    
    func testThresholdCalculation() async {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        await setupInitialPageState(doubles: doubles)
        doubles.presenter.resetCalls()
        
        sut.loadMoreIfNeeded(visibleIndex: 3, totalCount: 10)
        await waitForAsync(duration: 0.05)
        
        assertNoLoadingTriggered(doubles.presenter)
        
        sut.loadMoreIfNeeded(visibleIndex: 4, totalCount: 10)
        await waitForAsync()
        
        XCTAssertGreaterThan(doubles.presenter.presentLoadingCallCount, 0)
    }
    
    func testDeinit_cancelsCurrentTask() {
        let doubles = Doubles()
        doubles.configureForDelay()
        sut = makeSUT(doubles: doubles)
        sut.viewDidLoad()
        
        sut = nil
    }
    
    private func setupInitialPageState(doubles: Doubles) async {
        let initialMovies = doubles.createMockMovies()
        let initialResponse = PagedResponse(page: 1, results: initialMovies, totalPages: 5, totalResults: 100)
        doubles.api.mockResponse = initialResponse
        sut.viewDidLoad()
        await waitForAsync()
    }
}

extension HomeInteractorTests {
    
    func makeSUT(doubles: Doubles) -> HomeInteractor {
        return HomeInteractor(presenter: doubles.presenter, api: doubles.api)
    }
    
    func waitForAsync(duration: Double = 0.1) async {
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
    
    func assertLoadingStates(_ presenter: MockHomePresentationLogic, loading: Int = 0, initial: Int = 0,
                             append: Int = 0, error: Int = 0) {
        XCTAssertEqual(presenter.presentLoadingCallCount, loading, "Loading call count mismatch")
        XCTAssertEqual(presenter.presentInitialCallCount, initial, "Initial call count mismatch")
        XCTAssertEqual(presenter.presentAppendCallCount, append, "Append call count mismatch")
        XCTAssertEqual(presenter.presentErrorCallCount, error, "Error call count mismatch")
    }
    
    func assertInitialPresentation(_ presenter: MockHomePresentationLogic, title: String,
                                   itemsCount: Int, isLoading: Bool) {
        let lastInitialCall = presenter.presentInitialCalls.last
        XCTAssertEqual(lastInitialCall?.title, title, "Title mismatch")
        XCTAssertEqual(lastInitialCall?.items.count, itemsCount, "Items count mismatch")
        XCTAssertEqual(lastInitialCall?.isLoading, isLoading, "Loading state mismatch")
    }
    
    func assertFirstItemMapping(_ presenter: MockHomePresentationLogic, id: Int, title: String,
                                subtitle: String, posterPath: String) {
        let firstItem = presenter.presentInitialCalls.last?.items.first
        XCTAssertEqual(firstItem?.id, id, "Item ID mismatch")
        XCTAssertEqual(firstItem?.title, title, "Item title mismatch")
        XCTAssertEqual(firstItem?.subtitle, subtitle, "Item subtitle mismatch")
        XCTAssertEqual(firstItem?.posterPath, posterPath, "Item poster path mismatch")
    }
    
    func assertFirstItemTitle(_ presenter: MockHomePresentationLogic, expectedTitle: String) {
        let firstItem = presenter.presentInitialCalls.last?.items.first
        XCTAssertEqual(firstItem?.title, expectedTitle, "Item title mismatch")
    }
    
    func assertErrorMessage(_ presenter: MockHomePresentationLogic, expectedMessage: String) {
        XCTAssertEqual(presenter.presentErrorCalls.last, expectedMessage, "Error message mismatch")
    }
    
    func assertAppendedItems(_ presenter: MockHomePresentationLogic, expectedCount: Int, firstItemId: Int) {
        let appendedItems = presenter.presentAppendCalls.last
        XCTAssertEqual(appendedItems?.count, expectedCount, "Appended items count mismatch")
        XCTAssertEqual(appendedItems?.first?.id, firstItemId, "First appended item ID mismatch")
    }
    
    func assertNoLoadingTriggered(_ presenter: MockHomePresentationLogic) {
        XCTAssertEqual(presenter.presentLoadingCallCount, 0, "Loading should not be triggered")
        XCTAssertEqual(presenter.presentAppendCallCount, 0, "Append should not be triggered")
    }
    
    struct Doubles {
        let presenter: MockHomePresentationLogic
        let api: MockAPIClient
        
        init() {
            self.presenter = MockHomePresentationLogic()
            self.api = MockAPIClient()
            setupDefaultConfiguration()
        }
        
        private func setupDefaultConfiguration() {
            let defaultMovies = createMockMovies()
            let defaultResponse = PagedResponse(page: 1, results: defaultMovies, totalPages: 5, totalResults: 100)
            api.mockResponse = defaultResponse
            api.shouldThrowError = false
            api.shouldDelay = false
        }
        
        func createMockMovies(startId: Int = 1) -> [Movie] {
            return [
                Movie(id: startId, title: "Movie \(startId)", overview: "Overview \(startId)",
                      posterPath: "/poster\(startId).jpg", backdropPath: "/backdrop\(startId).jpg",
                      releaseDate: "2024-01-0\(min(startId, 9))", voteAverage: 7.0 + Double(startId)),
                Movie(id: startId + 1, title: "Movie \(startId + 1)", overview: "Overview \(startId + 1)",
                      posterPath: "/poster\(startId + 1).jpg", backdropPath: "/backdrop\(startId + 1).jpg",
                      releaseDate: "2024-01-0\(min(startId + 1, 9))", voteAverage: 7.0 + Double(startId + 1)),
                Movie(id: startId + 2, title: "Movie \(startId + 2)", overview: "Overview \(startId + 2)",
                      posterPath: "/poster\(startId + 2).jpg", backdropPath: "/backdrop\(startId + 2).jpg",
                      releaseDate: "2024-01-0\(min(startId + 2, 9))", voteAverage: 7.0 + Double(startId + 2))
            ]
        }
        
        func configureForError(_ error: Error? = nil) {
            api.shouldThrowError = true
            if let error = error {
                api.mockError = error
            } else {
                api.mockError = NSError(domain: "TestError", code: 500,
                                        userInfo: [NSLocalizedDescriptionKey: "Default Test Error"])
            }
        }
        
        func configureForDelay() {
            api.shouldDelay = true
        }
        
        func configureForLastPage() {
            let movies = createMockMovies()
            let response = PagedResponse(page: 5, results: movies, totalPages: 5, totalResults: 100)
            api.mockResponse = response
        }
        
        func configureForEmptyResponse() {
            let response = PagedResponse<Movie>(page: 1, results: [], totalPages: 1, totalResults: 0)
            api.mockResponse = response
        }
        
        func resetCalls() {
            presenter.resetCalls()
            api.resetCalls()
        }
    }
}
