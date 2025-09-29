@testable import TheMovieDB

final class MockMovieDetailsDisplayLogic: MovieDetailsDisplayLogic {
    
    private(set) var displayLoadingCallCount = 0
    private(set) var displayViewModelCallCount = 0
    private(set) var displayErrorCallCount = 0
    
    private(set) var displayLoadingCalls: [Bool] = []
    private(set) var displayViewModelCalls: [MovieDetails.ViewModel] = []
    private(set) var displayErrorCalls: [String] = []
    
    func displayLoading(_ loading: Bool) {
        displayLoadingCallCount += 1
        displayLoadingCalls.append(loading)
    }
    
    func display(viewModel: MovieDetails.ViewModel) {
        displayViewModelCallCount += 1
        displayViewModelCalls.append(viewModel)
    }
    
    func displayError(_ message: String) {
        displayErrorCallCount += 1
        displayErrorCalls.append(message)
    }
}
