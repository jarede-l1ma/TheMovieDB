@testable import TheMovieDB

final class MockMovieDetailsPresentationLogic: MovieDetailsPresentationLogic {
    
    private(set) var presentLoadingCallCount = 0
    private(set) var presentDetailsCallCount = 0
    private(set) var presentErrorCallCount = 0
    
    private(set) var presentLoadingCalls: [Bool] = []
    private(set) var presentDetailsCalls: [Movie] = []
    private(set) var presentErrorCalls: [String] = []
    
    func presentLoading(_ loading: Bool) {
        presentLoadingCallCount += 1
        presentLoadingCalls.append(loading)
    }
    
    func present(details: Movie) {
        presentDetailsCallCount += 1
        presentDetailsCalls.append(details)
    }
    
    func presentError(_ message: String) {
        presentErrorCallCount += 1
        presentErrorCalls.append(message)
    }
}
