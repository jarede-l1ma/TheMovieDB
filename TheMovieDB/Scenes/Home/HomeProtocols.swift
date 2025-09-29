import Foundation

/// Protocol for business logic of the Home feature.
protocol HomeBusinessLogic: AnyObject {
    func viewDidLoad()
    func loadMoreIfNeeded(visibleIndex: Int, totalCount: Int)
}

/// Protocol for presenting data to the ViewModel.
protocol HomePresentationLogic: AnyObject {
    func presentInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool)
    func presentAppend(items: [Home.ItemViewModel])
    func presentLoading(_ loading: Bool)
    func presentError(_ message: String)
}

/// Protocol for updating the view with UI data.
protocol HomeDisplayLogic: AnyObject {
    func displayInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool)
    func displayAppend(items: [Home.ItemViewModel])
    func displayLoading(_ loading: Bool)
    func displayError(_ message: String)
}

/// Protocol for navigation from the Home screen.
protocol HomeRouterLogic: AnyObject {
     func routeToMovieDetails(movieID: Int, title: String)
}
