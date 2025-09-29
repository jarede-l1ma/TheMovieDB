import Foundation

/// Protocol for business logic of the movie details feature.
protocol MovieDetailsBusinessLogic: AnyObject {
    func viewDidLoad()
}

/// Protocol for presenting data to the view controller or view model.
protocol MovieDetailsPresentationLogic: AnyObject {
    func presentLoading(_ loading: Bool)
    func present(details: Movie)
    func presentError(_ message: String)
}

/// Protocol for updating the UI with movie details data.
protocol MovieDetailsDisplayLogic: AnyObject {
    func displayLoading(_ loading: Bool)
    func display(viewModel: MovieDetails.ViewModel)
    func displayError(_ message: String)
}

/// Namespace for the details feature, including the view model.
enum MovieDetails {
    /// View model struct used to populate the details screen UI.
    struct ViewModel: Equatable {
        let title: String
        let subtitle: String?
        let overview: String?
        let posterPath: String?
        let ratingText: String?
    }
}
