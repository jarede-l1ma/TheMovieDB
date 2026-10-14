import XCTest
@testable import TheMovieDB

@MainActor
final class AppCoordinatorTests: XCTestCase {

    func test_start_setsHomeAsTheOnlyScreenWithoutAnimation() async {
        let navigation = UINavigationController()
        let sut = AppCoordinator(navigationController: navigation)
        trackForMemoryLeaks(sut)

        sut.start()

        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.viewControllers.first is HomeViewController)
    }

    func test_start_replacesAnyExistingStack() async {
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.pushViewController(UIViewController(), animated: false)
        let sut = AppCoordinator(navigationController: navigation)

        sut.start()

        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.viewControllers.first is HomeViewController)
    }
}
