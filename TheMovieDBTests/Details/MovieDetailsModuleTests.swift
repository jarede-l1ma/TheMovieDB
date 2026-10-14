import XCTest
@testable import TheMovieDB

/// Composition test: it only builds the module and never loads its view, so nothing reaches the network.
@MainActor
final class MovieDetailsModuleTests: XCTestCase {

    func test_build_composesDetailsViewControllerWithGivenTitle() async {
        let viewController = MovieDetailsModule.build(movieID: 1, title: "Heat")

        XCTAssertTrue(viewController is MovieDetailsViewController)
        XCTAssertEqual(viewController.title, "Heat")
    }
}
