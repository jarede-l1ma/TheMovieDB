import XCTest
@testable import TheMovieDB

@MainActor
final class HomeViewControllerTests: XCTestCase {

    // MARK: - Lifecycle

    func test_init_doesNotMessageInteractorBeforeViewLoads() async {
        let (_, interactor, router) = makeSUT()

        XCTAssertTrue(interactor.messages.isEmpty)
        XCTAssertTrue(router.messages.isEmpty)
    }

    func test_viewDidLoad_asksInteractorToLoadExactlyOnce() async {
        let (sut, interactor, _) = makeSUT()

        sut.loadViewIfNeeded()
        sut.loadViewIfNeeded()

        XCTAssertEqual(interactor.messages, [.viewDidLoad])
    }

    func test_init_setsLocalizedTitle() async {
        let (sut, _, _) = makeSUT()

        XCTAssertEqual(sut.title, String(localized: "home.title"))
    }

    // MARK: - Display

    func test_displayInitial_setsTitleAndRendersItems() async {
        let (sut, _, _) = makeSUT()
        sut.loadViewIfNeeded()

        sut.displayInitial(title: "Movies", items: .fixtures(ids: 1...2), isLoading: false)

        XCTAssertEqual(sut.title, "Movies")
        XCTAssertEqual(numberOfItems(in: sut), 2)
    }

    func test_displayInitial_replacesPreviouslyDisplayedItems() async {
        let (sut, _, _) = makeSUT()
        sut.loadViewIfNeeded()
        sut.displayInitial(title: "Movies", items: .fixtures(ids: 1...5), isLoading: false)

        sut.displayInitial(title: "Movies", items: .fixtures(ids: 1...2), isLoading: false)

        XCTAssertEqual(numberOfItems(in: sut), 2)
    }

    func test_displayAppend_addsItemsAfterTheExistingOnes() async {
        let (sut, _, _) = makeSUT(tracksLeaks: false)
        let window = host(sut)
        sut.displayInitial(title: "Movies", items: .fixtures(ids: 1...3), isLoading: false)
        homeView(of: sut).collectionView.layoutIfNeeded()

        sut.displayAppend(items: .fixtures(ids: 4...5))

        XCTAssertEqual(numberOfItems(in: sut), 5)
        await unhost(window)
    }

    func test_displayLoading_togglesActivityIndicator() async {
        let (sut, _, _) = makeSUT()
        sut.loadViewIfNeeded()

        sut.displayLoading(true)
        XCTAssertTrue(homeView(of: sut).activityIndicator.isAnimating)

        sut.displayLoading(false)
        XCTAssertFalse(homeView(of: sut).activityIndicator.isAnimating)
    }

    func test_displayError_presentsLocalizedAlertWithMessage() async throws {
        let (sut, _, _) = makeSUT(tracksLeaks: false)
        sut.loadViewIfNeeded()
        let window = host(sut)

        sut.displayError("Something went wrong")

        let alert = try XCTUnwrap(sut.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.title, String(localized: "alert.error.title"))
        XCTAssertEqual(alert.message, "Something went wrong")
        XCTAssertEqual(alert.actions.map(\.title), [String(localized: "alert.ok.button")])
        await unhost(window)
    }

    // MARK: - Cells

    func test_cellForItem_configuresAccessibilityLabelWithTitleAndSubtitle() async throws {
        let (sut, _, _) = makeSUT()
        sut.loadViewIfNeeded()
        sut.displayInitial(
            title: "Movies",
            items: [.fixture(id: 1, title: "Inception", subtitle: "2010-07-16", posterPath: nil)],
            isLoading: false
        )

        let cell = try XCTUnwrap(cell(at: 0, in: sut) as? PosterCollectionViewCell)

        XCTAssertEqual(cell.accessibilityLabel, "Inception, 2010-07-16")
    }

    func test_cellForItem_withoutSubtitle_usesOnlyTheTitleAsAccessibilityLabel() async throws {
        let (sut, _, _) = makeSUT()
        sut.loadViewIfNeeded()
        sut.displayInitial(
            title: "Movies",
            items: [.fixture(id: 1, title: "Inception", subtitle: nil, posterPath: nil)],
            isLoading: false
        )

        let cell = try XCTUnwrap(cell(at: 0, in: sut) as? PosterCollectionViewCell)

        XCTAssertEqual(cell.accessibilityLabel, "Inception")
    }

    // MARK: - Interaction

    func test_willDisplayCell_asksInteractorToLoadMoreWithIndexAndTotalCount() async {
        let (sut, interactor, _) = makeSUT()
        sut.loadViewIfNeeded()
        sut.displayInitial(title: "Movies", items: .fixtures(ids: 1...3), isLoading: false)

        sut.collectionView(homeView(of: sut).collectionView, willDisplay: UICollectionViewCell(), forItemAt: IndexPath(item: 2, section: 0))

        XCTAssertEqual(interactor.messages, [.viewDidLoad, .loadMoreIfNeeded(visibleIndex: 2, totalCount: 3)])
    }

    func test_didSelectItem_routesToDetailsOfSelectedMovie() async {
        let (sut, _, router) = makeSUT()
        sut.loadViewIfNeeded()
        sut.displayInitial(
            title: "Movies",
            items: [.fixture(id: 1), .fixture(id: 99, title: "Inception")],
            isLoading: false
        )

        sut.collectionView(homeView(of: sut).collectionView, didSelectItemAt: IndexPath(item: 1, section: 0))

        XCTAssertEqual(router.messages, [.routeToMovieDetails(movieID: 99, title: "Inception")])
    }

    func test_didSelectItem_outsideOfBounds_doesNotRoute() async {
        let (sut, _, router) = makeSUT()
        sut.loadViewIfNeeded()
        sut.displayInitial(title: "Movies", items: [.fixture()], isLoading: false)

        sut.collectionView(homeView(of: sut).collectionView, didSelectItemAt: IndexPath(item: 5, section: 0))

        XCTAssertTrue(router.messages.isEmpty)
    }

    // MARK: - Helpers

    /// - Parameter tracksLeaks: Pass `false` for tests that host the controller in a window: UIKit keeps
    ///   hosted/presenting controllers alive past the test on the iOS 26.0 runtime, which is not a leak of ours.
    private func makeSUT(
        tracksLeaks: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: HomeViewController, interactor: HomeInteractorSpy, router: HomeRouterSpy) {
        let interactor = HomeInteractorSpy()
        let router = HomeRouterSpy()
        let sut = HomeViewController(interactor: interactor, router: router)
        if tracksLeaks {
            trackForMemoryLeaks(sut, file: file, line: line)
            trackForMemoryLeaks(interactor, file: file, line: line)
            trackForMemoryLeaks(router, file: file, line: line)
        }
        return (sut, interactor, router)
    }

    private func homeView(of sut: HomeViewController) -> HomeView {
        sut.view as! HomeView
    }

    private func numberOfItems(in sut: HomeViewController) -> Int {
        sut.collectionView(homeView(of: sut).collectionView, numberOfItemsInSection: 0)
    }

    private func cell(at item: Int, in sut: HomeViewController) -> UICollectionViewCell {
        sut.collectionView(homeView(of: sut).collectionView, cellForItemAt: IndexPath(item: item, section: 0))
    }
}
