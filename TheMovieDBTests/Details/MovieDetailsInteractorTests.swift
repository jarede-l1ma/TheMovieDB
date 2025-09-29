import XCTest
@testable import TheMovieDB

@MainActor
final class MovieDetailsInteractorTests: XCTestCase {
    
    private var sut: MovieDetailsInteractor!
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testViewDidLoad_success() async {
        let doubles = Doubles()
        let mockMovie = doubles.createMockMovie()
        doubles.api.mockResponse = mockMovie
        sut = makeSUT(doubles: doubles)
        
        sut.viewDidLoad()
        await waitForAsync()
        
        assertLoadingStates(doubles.presenter, loading: 2, present: 1, error: 0)
        assertPresentedMovie(doubles.presenter, movie: mockMovie)
    }
    
    func testViewDidLoad_apiError() async {
        let doubles = Doubles()
        doubles.configureForError(NSError(domain: "TestError", code: 500, 
                                        userInfo: [NSLocalizedDescriptionKey: "Server Error"]))
        sut = makeSUT(doubles: doubles)
        
        sut.viewDidLoad()
        await waitForAsync()
        
        assertLoadingStates(doubles.presenter, loading: 2, present: 0, error: 1)
        assertErrorMessage(doubles.presenter, expectedMessage: "Server Error")
    }
}

extension MovieDetailsInteractorTests {
    
    func makeSUT(doubles: Doubles) -> MovieDetailsInteractor {
        return MovieDetailsInteractor(movieID: 123, presenter: doubles.presenter, api: doubles.api)
    }
    
    func waitForAsync(duration: Double = 0.1) async {
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }
    
    func assertLoadingStates(_ presenter: MockMovieDetailsPresentationLogic, loading: Int = 0, 
                           present: Int = 0, error: Int = 0) {
        XCTAssertEqual(presenter.presentLoadingCallCount, loading, "Loading call count mismatch")
        XCTAssertEqual(presenter.presentDetailsCallCount, present, "Present call count mismatch")
        XCTAssertEqual(presenter.presentErrorCallCount, error, "Error call count mismatch")
    }
    
    func assertPresentedMovie(_ presenter: MockMovieDetailsPresentationLogic, movie: Movie) {
        let presentedMovie = presenter.presentDetailsCalls.last
        XCTAssertEqual(presentedMovie?.id, movie.id, "Movie ID mismatch")
        XCTAssertEqual(presentedMovie?.title, movie.title, "Movie title mismatch")
    }
    
    func assertErrorMessage(_ presenter: MockMovieDetailsPresentationLogic, expectedMessage: String) {
        XCTAssertEqual(presenter.presentErrorCalls.last, expectedMessage, "Error message mismatch")
    }
    
    struct Doubles {
        let presenter: MockMovieDetailsPresentationLogic
        let api: MockAPIClient
        
        init() {
            self.presenter = MockMovieDetailsPresentationLogic()
            self.api = MockAPIClient()
            setupDefaultConfiguration()
        }
        
        private func setupDefaultConfiguration() {
            let defaultMovie = createMockMovie()
            api.mockResponse = defaultMovie
            api.shouldThrowError = false
        }
        
        func createMockMovie() -> Movie {
            return Movie(
                id: 123,
                title: "Test Movie",
                overview: "Test overview",
                posterPath: "/test_poster.jpg",
                backdropPath: "/test_backdrop.jpg",
                releaseDate: "2024-01-01",
                voteAverage: 8.5
            )
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
    }
}
