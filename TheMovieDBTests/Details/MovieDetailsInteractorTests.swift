import XCTest
@testable import TheMovieDB

@MainActor
final class MovieDetailsInteractorTests: XCTestCase {

    func test_init_doesNotRequestNorPresentAnything() async {
        let (_, presenter, api) = makeSUT()

        XCTAssertTrue(api.requestedEndpoints.isEmpty)
        XCTAssertTrue(presenter.messages.isEmpty)
    }

    func test_viewDidLoad_requestsDetailsOfTheGivenMovie() async {
        let (sut, presenter, api) = makeSUT(movieID: 42)
        api.stub(Movie.fixture(id: 42))

        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(api.requestedEndpoints, [.movieDetails(id: 42)])
    }

    func test_viewDidLoad_deliversMovieBetweenLoadingStatesOnSuccess() async {
        let movie = Movie.fixture(id: 42, title: "Heat")
        let (sut, presenter, api) = makeSUT(movieID: 42)
        api.stub(movie)

        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(presenter.messages, [.loading(true), .details(movie), .loading(false)])
    }

    func test_viewDidLoad_deliversErrorMessageBetweenLoadingStatesOnFailure() async {
        let (sut, presenter, api) = makeSUT()
        api.stub(error: NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server Error"]))

        await perform({ sut.viewDidLoad() }, untilPresenterReceives: 3, presenter)

        XCTAssertEqual(presenter.messages, [.loading(true), .error("Server Error"), .loading(false)])
    }

    // MARK: - Helpers

    private func makeSUT(
        movieID: Int = 123,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: MovieDetailsInteractor, presenter: MovieDetailsPresenterSpy, api: APIClientStub) {
        let presenter = MovieDetailsPresenterSpy()
        let api = APIClientStub()
        let sut = MovieDetailsInteractor(movieID: movieID, presenter: presenter, api: api)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(presenter, file: file, line: line)
        trackForMemoryLeaks(api, file: file, line: line)
        return (sut, presenter, api)
    }

    /// Runs `action` and suspends until the presenter has received `count` more messages.
    private func perform(
        _ action: () -> Void,
        untilPresenterReceives count: Int,
        _ presenter: MovieDetailsPresenterSpy
    ) async {
        let exp = expectation(description: "Wait for \(count) presenter messages")
        let target = presenter.messages.count + count
        presenter.onMessage = { if presenter.messages.count == target { exp.fulfill() } }

        action()

        await fulfillment(of: [exp], timeout: 1.0)
        presenter.onMessage = nil
    }
}
