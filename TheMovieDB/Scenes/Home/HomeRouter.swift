import UIKit

/// Router responsible for navigation from the Home screen.
final class HomeRouter: HomeRouterLogic {
    weak var viewController: UIViewController?

    /// Navigates to the movie details screen for the selected movie.
    func routeToMovieDetails(movieID: Int, title: String) {
        let vc = MovieDetailsModule.build(movieID: movieID, title: title)
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }
}
