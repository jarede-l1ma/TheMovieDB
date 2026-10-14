import XCTest
@testable import TheMovieDB

@MainActor
final class HomeRouterTests: XCTestCase {

    func test_routeToMovieDetails_pushesDetailsScreenWithGivenTitle() async throws {
        let (sut, navigation) = makeSUT()

        sut.routeToMovieDetails(movieID: 99, title: "Inception")

        XCTAssertEqual(navigation.viewControllers.count, 2)
        let details = try XCTUnwrap(navigation.topViewController as? MovieDetailsViewController)
        XCTAssertEqual(details.title, "Inception")
    }

    func test_routeToMovieDetails_withoutViewController_doesNothing() async {
        let sut = HomeRouter()

        sut.routeToMovieDetails(movieID: 1, title: "Orphan")

        XCTAssertNil(sut.viewController)
    }

    func test_viewController_isHeldWeakly() async {
        let sut = HomeRouter()
        var viewController: UIViewController? = UIViewController()
        sut.viewController = viewController
        weak var weakViewController = viewController

        viewController = nil

        XCTAssertNil(weakViewController, "Router must hold its view controller weakly")
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: HomeRouter, navigation: UINavigationController) {
        let root = UIViewController()
        let navigation = UINavigationController(rootViewController: root)
        let sut = HomeRouter()
        sut.viewController = root
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(navigation, file: file, line: line)
        return (sut, navigation)
    }
}
