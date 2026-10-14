import XCTest
@testable import TheMovieDB

@MainActor
final class MovieDetailsPresenterTests: XCTestCase {

    func test_presentLoading_forwardsEachStateToViewInOrder() async {
        let (sut, view) = makeSUT()

        sut.presentLoading(true)
        sut.presentLoading(false)

        XCTAssertEqual(view.messages, [.loading(true), .loading(false)])
    }

    func test_presentDetails_mapsMovieToViewModel() async {
        let (sut, view) = makeSUT()
        let movie = Movie.fixture(
            title: "Test Movie",
            overview: "Test overview",
            posterPath: "/test_poster.jpg",
            releaseDate: "2024-01-01",
            voteAverage: 8.5
        )

        sut.present(details: movie)

        XCTAssertEqual(view.messages, [
            .viewModel(MovieDetails.ViewModel(
                title: "Test Movie",
                subtitle: "2024-01-01",
                overview: "Test overview",
                posterPath: "/test_poster.jpg",
                ratingText: "8.5"
            ))
        ])
    }

    func test_presentDetails_withoutTitle_usesLocalizedFallback() async {
        let (sut, view) = makeSUT()

        sut.present(details: .fixture(title: nil))

        XCTAssertEqual(viewModel(in: view)?.title, String(localized: "movie.noTitle"))
    }

    func test_presentDetails_withoutVoteAverage_hasNoRatingText() async {
        let (sut, view) = makeSUT()

        sut.present(details: .fixture(voteAverage: nil))

        XCTAssertNil(viewModel(in: view)?.ratingText)
    }

    func test_presentDetails_formatsRatingWithOneDecimalPlace() async {
        let (sut, view) = makeSUT()

        sut.present(details: .fixture(voteAverage: 7))
        sut.present(details: .fixture(voteAverage: 7.456))

        XCTAssertEqual(viewModels(in: view).map(\.ratingText), ["7.0", "7.5"])
    }

    func test_presentError_forwardsMessageToView() async {
        let (sut, view) = makeSUT()

        sut.presentError("Network Error")

        XCTAssertEqual(view.messages, [.error("Network Error")])
    }

    func test_present_doesNotRetainView() async {
        let sut = MovieDetailsPresenter()
        var view: MovieDetailsDisplaySpy? = MovieDetailsDisplaySpy()
        sut.view = view
        weak var weakView = view

        view = nil

        XCTAssertNil(weakView, "Presenter must hold its view weakly")
        sut.presentLoading(true)
        sut.presentError("ignored")
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: MovieDetailsPresenter, view: MovieDetailsDisplaySpy) {
        let view = MovieDetailsDisplaySpy()
        let sut = MovieDetailsPresenter()
        sut.view = view
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(view, file: file, line: line)
        return (sut, view)
    }

    private func viewModels(in view: MovieDetailsDisplaySpy) -> [MovieDetails.ViewModel] {
        view.messages.compactMap { if case let .viewModel(viewModel) = $0 { viewModel } else { nil } }
    }

    private func viewModel(in view: MovieDetailsDisplaySpy) -> MovieDetails.ViewModel? {
        viewModels(in: view).last
    }
}
