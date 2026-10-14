import XCTest
@testable import TheMovieDB

@MainActor
final class HomePresenterTests: XCTestCase {

    func test_presentInitial_forwardsTitleItemsAndLoadingStateToView() async {
        let (sut, view) = makeSUT()
        let items = [Home.ItemViewModel].fixtures(ids: 1...2)

        sut.presentInitial(title: "Now Playing", items: items, isLoading: false)

        XCTAssertEqual(view.messages, [.initial(title: "Now Playing", items: items, isLoading: false)])
    }

    func test_presentAppend_forwardsItemsToView() async {
        let (sut, view) = makeSUT()
        let items = [Home.ItemViewModel].fixtures(ids: 4...5)

        sut.presentAppend(items: items)

        XCTAssertEqual(view.messages, [.append(items)])
    }

    func test_presentLoading_forwardsEachStateToViewInOrder() async {
        let (sut, view) = makeSUT()

        sut.presentLoading(true)
        sut.presentLoading(false)

        XCTAssertEqual(view.messages, [.loading(true), .loading(false)])
    }

    func test_presentError_forwardsMessageToView() async {
        let (sut, view) = makeSUT()

        sut.presentError("Network Error")

        XCTAssertEqual(view.messages, [.error("Network Error")])
    }

    func test_present_doesNotRetainView() async {
        let sut = HomePresenter()
        var view: HomeDisplaySpy? = HomeDisplaySpy()
        sut.view = view
        weak let weakView = view

        view = nil

        XCTAssertNil(weakView, "Presenter must hold its view weakly")
        sut.presentLoading(true)
        sut.presentError("ignored")
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: HomePresenter, view: HomeDisplaySpy) {
        let view = HomeDisplaySpy()
        let sut = HomePresenter()
        sut.view = view
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(view, file: file, line: line)
        return (sut, view)
    }
}
