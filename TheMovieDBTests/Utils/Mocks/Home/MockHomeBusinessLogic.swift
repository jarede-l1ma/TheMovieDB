@testable import TheMovieDB
import Foundation

final class MockHomeBusinessLogic: HomeBusinessLogic {
    
    private(set) var viewDidLoadCallCount = 0
    private(set) var loadMoreCallCount = 0
    private(set) var loadMoreCalls: [(visibleIndex: Int, totalCount: Int)] = []
    
    func viewDidLoad() {
        viewDidLoadCallCount += 1
    }
    
    func loadMoreIfNeeded(visibleIndex: Int, totalCount: Int) {
        loadMoreCallCount += 1
        loadMoreCalls.append((visibleIndex: visibleIndex, totalCount: totalCount))
    }
}
