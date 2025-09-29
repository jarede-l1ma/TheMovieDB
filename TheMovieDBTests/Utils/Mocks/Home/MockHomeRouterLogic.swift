@testable import TheMovieDB
import Foundation

final class MockHomeRouterLogic: HomeRouterLogic {
    
    private(set) var routeToMovieDetailsCallCount = 0
    private(set) var routeToMovieDetailsCalls: [(movieID: Int, title: String)] = []
    
    func routeToMovieDetails(movieID: Int, title: String) {
        routeToMovieDetailsCallCount += 1
        routeToMovieDetailsCalls.append((movieID: movieID, title: title))
    }
}
