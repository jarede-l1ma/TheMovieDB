import Foundation

/// Presenter for the movie details feature.
/// Responsible for transforming data and forwarding it to the view.
final class MovieDetailsPresenter: MovieDetailsPresentationLogic {
    weak var view: MovieDetailsDisplayLogic?

    /// Presents the loading state to the view.
    func presentLoading(_ loading: Bool) {
        view?.displayLoading(loading)
    }

    /// Presents the movie details, mapping raw model to view model.
    func present(details: Movie) {
        let vm = MovieDetails.ViewModel(
            // Localized fallback for missing title
            title: details.title ?? String(localized: "movie.noTitle"),
            subtitle: details.releaseDate,
            overview: details.overview,
            posterPath: details.posterPath,
            ratingText: details.voteAverage.map { String(format: "%.1f", $0) }
        )
        view?.display(viewModel: vm)
    }

    /// Presents an error message to the view.
    func presentError(_ message: String) {
        view?.displayError(message)
    }
}
