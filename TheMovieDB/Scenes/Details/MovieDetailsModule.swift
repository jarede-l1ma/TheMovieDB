import UIKit

/// Factory responsible for building the movie details module and wiring dependencies.
enum MovieDetailsModule {
    /// Creates and configures the details screen for the given movie.
    /// - Parameters:
    ///   - movieID: The identifier of the movie to display.
    ///   - title: The navigation title for the details screen.
    /// - Returns: The fully configured details view controller.
    static func build(movieID: Int, title: String) -> UIViewController {
        let presenter = MovieDetailsPresenter()
        let interactor = MovieDetailsInteractor(movieID: movieID, presenter: presenter, api: APIClient.shared)
        let vc = MovieDetailsViewController(interactor: interactor, title: title)
        presenter.view = vc
        return vc
    }
}
