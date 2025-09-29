import Foundation

/// Handles business logic and data loading for the movie details screen.
final class MovieDetailsInteractor: MovieDetailsBusinessLogic {
    private let presenter: MovieDetailsPresentationLogic
    private let api: APIClientProtocol
    private let movieID: Int

    /// Initializes the interactor with its dependencies.
    /// - Parameters:
    ///   - movieID: The identifier for the movie whose details should be loaded.
    ///   - presenter: The presenter responsible for delivering UI-ready data.
    ///   - api: The API client for fetching movie data.
    init(movieID: Int, presenter: MovieDetailsPresentationLogic, api: APIClientProtocol) {
        self.movieID = movieID
        self.presenter = presenter
        self.api = api
    }

    /// Called when the details view is loaded. Begins loading movie details.
    func viewDidLoad() {
        Task { await load() }
    }

    /// Loads the movie details asynchronously and updates the presenter.
    @MainActor
    private func load() async {
        presenter.presentLoading(true)
        defer { presenter.presentLoading(false) }
        do {
            let movie: Movie = try await api.request(.movieDetails(id: movieID))
            presenter.present(details: movie)
        } catch {
            presenter.presentError(error.localizedDescription)
        }
    }
}
