import XCTest
@testable import TheMovieDB

@MainActor
final class MovieDetailsViewControllerTests: XCTestCase {

    func test_init_setsGivenTitleAndDoesNotMessageInteractor() async {
        let (sut, interactor) = makeSUT(title: "Heat")

        XCTAssertEqual(sut.title, "Heat")
        XCTAssertTrue(interactor.messages.isEmpty)
    }

    func test_viewDidLoad_asksInteractorToLoadExactlyOnce() async {
        let (sut, interactor) = makeSUT()

        sut.loadViewIfNeeded()
        sut.loadViewIfNeeded()

        XCTAssertEqual(interactor.messages, [.viewDidLoad])
    }

    func test_displayLoading_togglesActivityIndicator() async throws {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        let activity = try XCTUnwrap(sut.view.firstSubview(ofType: UIActivityIndicatorView.self))

        sut.displayLoading(true)
        XCTAssertTrue(activity.isAnimating)

        sut.displayLoading(false)
        XCTAssertFalse(activity.isAnimating)
    }

    func test_displayViewModel_rendersTitleSubtitleAndOverview() async {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()

        sut.display(viewModel: .init(title: "Heat", subtitle: "1995-12-15", overview: "A heist.", posterPath: nil, ratingText: nil))

        let texts = sut.view.allLabelTexts
        XCTAssertTrue(texts.contains("Heat"), "Missing title in \(texts)")
        XCTAssertTrue(texts.contains("1995-12-15"), "Missing subtitle in \(texts)")
        XCTAssertTrue(texts.contains("A heist."), "Missing overview in \(texts)")
    }

    func test_displayViewModel_rendersLocalizedRating() async {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()

        sut.display(viewModel: .init(title: "Heat", subtitle: nil, overview: nil, posterPath: nil, ratingText: "8.3"))

        let expected = String(format: String(localized: "movie.rating.prefix"), "8.3")
        XCTAssertTrue(sut.view.allLabelTexts.contains(expected), "Missing rating in \(sut.view.allLabelTexts)")
    }

    func test_displayViewModel_withoutRating_hidesRatingText() async {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        sut.display(viewModel: .init(title: "Heat", subtitle: nil, overview: nil, posterPath: nil, ratingText: "8.3"))

        sut.display(viewModel: .init(title: "Heat", subtitle: nil, overview: nil, posterPath: nil, ratingText: nil))

        let rating = String(format: String(localized: "movie.rating.prefix"), "8.3")
        XCTAssertFalse(sut.view.allLabelTexts.contains(rating))
    }

    func test_displayError_presentsLocalizedAlertWithMessage() async throws {
        let (sut, _) = makeSUT(tracksLeaks: false)
        sut.loadViewIfNeeded()
        let window = host(sut)

        sut.displayError("Something went wrong")

        let alert = try XCTUnwrap(sut.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.title, String(localized: "alert.error.title"))
        XCTAssertEqual(alert.message, "Something went wrong")
        XCTAssertEqual(alert.actions.map(\.title), [String(localized: "alert.ok.button")])
        await unhost(window)
    }

    // MARK: - Helpers

    /// - Parameter tracksLeaks: Pass `false` for tests that host the controller in a window: UIKit keeps
    ///   hosted/presenting controllers alive past the test on the iOS 26.0 runtime, which is not a leak of ours.
    private func makeSUT(
        title: String = "Movie",
        tracksLeaks: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: MovieDetailsViewController, interactor: MovieDetailsInteractorSpy) {
        let interactor = MovieDetailsInteractorSpy()
        let sut = MovieDetailsViewController(interactor: interactor, title: title)
        if tracksLeaks {
            trackForMemoryLeaks(sut, file: file, line: line)
            trackForMemoryLeaks(interactor, file: file, line: line)
        }
        return (sut, interactor)
    }
}
