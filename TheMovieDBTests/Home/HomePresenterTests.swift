import XCTest
@testable import TheMovieDB

final class HomePresenterTests: XCTestCase {
    
    private var sut: HomePresenter!
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testPresentInitial() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        let items = doubles.createMockItems()
        
        sut.presentInitial(title: "Test Title", items: items, isLoading: false)
        
        XCTAssertEqual(doubles.view.displayInitialCallCount, 1)
        let lastCall = doubles.view.displayInitialCalls.last
        XCTAssertEqual(lastCall?.title, "Test Title")
        XCTAssertEqual(lastCall?.items.count, 2)
        XCTAssertEqual(lastCall?.isLoading, false)
    }
    
    func testPresentAppend() {
        let doubles = Doubles()
        sut = makeSUT(doubles: doubles)
        let items = doubles.createMockItems()
        
        sut.presentAppend(items: items)
        
        XCTAssertEqual(doubles.view.displayAppendCallCount, 1)
        XCTAssertEqual(doubles.view.displayAppendCalls.last?.count, 2)
        XCTAssertEqual(doubles.view.displayAppendCalls.last?.first?.id, 1)
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
        
        sut.presentInitial(title: "Test", items: [], isLoading: false)
        sut.presentAppend(items: [])
        sut.presentLoading(true)
        sut.presentError("Test Error")
    }
}

extension HomePresenterTests {
    
    func makeSUT(doubles: Doubles) -> HomePresenter {
        let presenter = HomePresenter()
        presenter.view = doubles.view
        return presenter
    }
    
    struct Doubles {
        let view: MockHomeDisplayLogic
        
        init() {
            self.view = MockHomeDisplayLogic()
        }
        
        func createMockItems() -> [Home.ItemViewModel] {
            return [
                Home.ItemViewModel(id: 1, title: "Movie 1", subtitle: "2024-01-01", posterPath: "/poster1.jpg"),
                Home.ItemViewModel(id: 2, title: "Movie 2", subtitle: "2024-01-02", posterPath: "/poster2.jpg")
            ]
        }
    }
}
