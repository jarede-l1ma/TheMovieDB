@testable import TheMovieDB
import XCTest

final class MovieDetailsPresenterTests: XCTestCase {
    
    private var sut: MovieDetailsPresenter!
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testPresentLoading() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        
        sut.presentLoading(true)
        
        XCTAssertEqual(doubles.view.displayLoadingCallCount, 1)
        XCTAssertEqual(doubles.view.displayLoadingCalls.last, true)
        
        sut.presentLoading(false)
        
        XCTAssertEqual(doubles.view.displayLoadingCallCount, 2)
        XCTAssertEqual(doubles.view.displayLoadingCalls.last, false)
    }
    
    func testPresentDetails() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        let movie = doubles.createMockMovie()
        
        sut.present(details: movie)
        
        XCTAssertEqual(doubles.view.displayViewModelCallCount, 1)
        let viewModel = doubles.view.displayViewModelCalls.last
        XCTAssertEqual(viewModel?.title, "Test Movie")
        XCTAssertEqual(viewModel?.subtitle, "2024-01-01")
        XCTAssertEqual(viewModel?.overview, "Test overview")
        XCTAssertEqual(viewModel?.posterPath, "/test_poster.jpg")
        XCTAssertEqual(viewModel?.ratingText, "8.5")
    }
    
    func testPresentDetails_withNilTitle() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        let movieWithNilTitle = Movie(id: 1, title: nil, overview: "Overview", 
                                     posterPath: "/poster.jpg", backdropPath: "/backdrop.jpg",
                                     releaseDate: "2024-01-01", voteAverage: 7.5)
        
        sut.present(details: movieWithNilTitle)
        
        let viewModel = doubles.view.displayViewModelCalls.last
        XCTAssertEqual(viewModel?.title, "Sem título")
    }
    
    func testPresentDetails_withNilVoteAverage() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        let movieWithNilRating = Movie(id: 1, title: "Movie", overview: "Overview",
                                      posterPath: "/poster.jpg", backdropPath: "/backdrop.jpg",
                                      releaseDate: "2024-01-01", voteAverage: nil)
        
        sut.present(details: movieWithNilRating)
        
        let viewModel = doubles.view.displayViewModelCalls.last
        XCTAssertNil(viewModel?.ratingText)
    }
    
    func testPresentError() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        
        sut.presentError("Network Error")
        
        XCTAssertEqual(doubles.view.displayErrorCallCount, 1)
        XCTAssertEqual(doubles.view.displayErrorCalls.last, "Network Error")
    }
    
    func testWeakViewReference() {
        var doubles: Doubles? = Doubles()
        sut = makeSUT(doubles: doubles!)
        
        doubles = nil
        
        sut.presentLoading(true)
        sut.present(details: Movie(id: 1, title: "Test", overview: nil, posterPath: nil, 
                                  backdropPath: nil, releaseDate: nil, voteAverage: nil))
        sut.presentError("Test Error")
    }
}

extension MovieDetailsPresenterTests {
    
    func makeSUT(doubles: Doubles) -> MovieDetailsPresenter {
        let presenter = MovieDetailsPresenter()
        presenter.view = doubles.view
        return presenter
    }
    
    struct Doubles {
        let view: MockMovieDetailsDisplayLogic
        
        init() {
            self.view = MockMovieDetailsDisplayLogic()
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
    }
}
