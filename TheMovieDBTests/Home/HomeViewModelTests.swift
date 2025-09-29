import XCTest
@testable import TheMovieDB

final class HomeViewModelTests: XCTestCase {
    
    private var sut: HomeViewModel!
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testViewDidLoad() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        
        sut.viewDidLoad()
        
        XCTAssertEqual(doubles.interactor.viewDidLoadCallCount, 1)
    }
    
    func testLoadMoreIfNeeded() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        
        sut.loadMoreIfNeeded(visibleIndex: 5, totalCount: 10)
        
        XCTAssertEqual(doubles.interactor.loadMoreCallCount, 1)
        let lastCall = doubles.interactor.loadMoreCalls.last
        XCTAssertEqual(lastCall?.visibleIndex, 5)
        XCTAssertEqual(lastCall?.totalCount, 10)
    }
    
    func testDidSelectItem_validIndex() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        sut.items = doubles.createMockItems()
        
        sut.didSelectItem(at: 0)
        
        XCTAssertEqual(doubles.router.routeToMovieDetailsCallCount, 1)
        let lastCall = doubles.router.routeToMovieDetailsCalls.last
        XCTAssertEqual(lastCall?.movieID, 1)
        XCTAssertEqual(lastCall?.title, "Item 1")
    }
    
    func testDidSelectItem_invalidIndex() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        sut.items = doubles.createMockItems()
        
        sut.didSelectItem(at: 10)
        
        XCTAssertEqual(doubles.router.routeToMovieDetailsCallCount, 0)
    }
    
    func testDisplayInitial() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        let items = doubles.createMockItems()
        var updatedItems: [Home.ItemViewModel]?
        var loadingState: Bool?
        
        sut.onItemsUpdated = { updatedItems = $0 }
        sut.onLoadingStateChanged = { loadingState = $0 }
        
        sut.displayInitial(title: "Test Title", items: items, isLoading: true)
        
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertEqual(updatedItems?.count, 2)
        XCTAssertEqual(loadingState, true)
    }
    
    func testDisplayAppend() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        sut.items = [doubles.createMockItems().first!]
        let newItems = [doubles.createMockItems().last!]
        var appendedItems: [Home.ItemViewModel]?
        
        sut.onItemsAppended = { appendedItems = $0 }
        
        sut.displayAppend(items: newItems)
        
        XCTAssertEqual(sut.items.count, 2)
        XCTAssertEqual(appendedItems?.count, 1)
        XCTAssertEqual(appendedItems?.first?.id, 2)
    }
    
    func testDisplayLoading() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        var loadingState: Bool?
        
        sut.onLoadingStateChanged = { loadingState = $0 }
        
        sut.displayLoading(true)
        
        XCTAssertEqual(loadingState, true)
    }
    
    func testDisplayError() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        var errorMessage: String?
        
        sut.onErrorOccurred = { errorMessage = $0 }
        
        sut.displayError("Test Error")
        
        XCTAssertEqual(errorMessage, "Test Error")
    }
}

extension HomeViewModelTests {
    
    func makeSUT(doubles: Doubles) -> HomeViewModel {
        return HomeViewModel(
            interactor: doubles.interactor,
            router: doubles.router,
            presenter: doubles.presenter
        )
    }
    
    struct Doubles {
        let interactor: MockHomeBusinessLogic
        let router: MockHomeRouterLogic
        let presenter: MockHomePresentationLogic
        
        init() {
            self.interactor = MockHomeBusinessLogic()
            self.router = MockHomeRouterLogic()
            self.presenter = MockHomePresentationLogic()
        }
        
        func createMockItems() -> [Home.ItemViewModel] {
            return [
                Home.ItemViewModel(id: 1, title: "Item 1", subtitle: "Subtitle 1", posterPath: "/poster1.jpg"),
                Home.ItemViewModel(id: 2, title: "Item 2", subtitle: "Subtitle 2", posterPath: "/poster2.jpg")
            ]
        }
    }
}
