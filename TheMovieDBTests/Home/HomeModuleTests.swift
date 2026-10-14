import XCTest
@testable import TheMovieDB

/// Composition tests: they only build the module and never load its view, so nothing reaches the network.
@MainActor
final class HomeModuleTests: XCTestCase {

    func test_build_composesHomeViewController() async {
        let module = HomeModule.build()

        XCTAssertTrue(module.viewController is HomeViewController)
        XCTAssertTrue(module.interactor is HomeInteractor)
    }

    func test_build_wiresRouterToTheBuiltViewController() async throws {
        let module = HomeModule.build()
        let navigation = UINavigationController(rootViewController: module.viewController)
        let home = try XCTUnwrap(module.viewController as? HomeViewController)

        // Selecting an item goes view -> router -> navigation stack of the built view controller.
        home.displayInitial(title: "Movies", items: [.fixture(id: 5, title: "Heat")], isLoading: false)
        home.collectionView(
            (home.view as! HomeView).collectionView,
            didSelectItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertEqual(navigation.topViewController?.title, "Heat")
    }
}
