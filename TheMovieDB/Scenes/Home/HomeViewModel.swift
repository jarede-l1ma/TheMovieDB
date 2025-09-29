import Foundation

/// ViewModel responsible for handling the state and actions of the Home screen.
final class HomeViewModel {
    
    // MARK: - Properties

    private let interactor: HomeBusinessLogic
    private let router: HomeRouterLogic
    private let presenter: HomePresentationLogic
    
    /// List of items representing the movies displayed.
    var items: [Home.ItemViewModel] = []
    /// Closure called when the list of items is updated (for full reload).
    var onItemsUpdated: (([Home.ItemViewModel]) -> Void)?
    /// Closure called when new items are appended (for incremental loading).
    var onItemsAppended: (([Home.ItemViewModel]) -> Void)?
    /// Closure called when the loading state changes.
    var onLoadingStateChanged: ((Bool) -> Void)?
    /// Closure called when an error occurs that should be displayed.
    var onErrorOccurred: ((String) -> Void)?
    
    // MARK: - Initialization
    
    /// Initializes the ViewModel with its business dependencies.
    /// - Parameters:
    ///   - interactor: Handles business logic for data fetching and updates.
    ///   - router: Handles navigation from the Home screen.
    ///   - presenter: Handles data formatting and presentation logic.
    init(interactor: HomeBusinessLogic, router: HomeRouterLogic, presenter: HomePresentationLogic) {
        self.interactor = interactor
        self.router = router
        self.presenter = presenter
    }
    
    // MARK: - Public Methods
    
    /// Should be called when the view is loaded to trigger initial data fetching.
    func viewDidLoad() {
        interactor.viewDidLoad()
    }
    
    /// Triggers loading more data if the user scrolls near the end of the list.
    /// - Parameters:
    ///   - visibleIndex: The index of the last visible item.
    ///   - totalCount: The current total number of items.
    func loadMoreIfNeeded(visibleIndex: Int, totalCount: Int) {
        interactor.loadMoreIfNeeded(visibleIndex: visibleIndex, totalCount: totalCount)
    }
    
    /// Handles selection of a movie item.
    /// - Parameter index: The index of the selected item.
    func didSelectItem(at index: Int) {
        guard index < items.count else { return }
        let item = items[index]
        router.routeToMovieDetails(movieID: item.id, title: item.title)
    }
}

// MARK: - HomeDisplayLogic
extension HomeViewModel: HomeDisplayLogic {
    /// Displays the initial state of the screen with a list of items.
    func displayInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool) {
        self.items = items
        onItemsUpdated?(items)
        onLoadingStateChanged?(isLoading)
    }
    
    /// Appends new items to the current list.
    func displayAppend(items: [Home.ItemViewModel]) {
        self.items.append(contentsOf: items)
        onItemsAppended?(items)
    }
    
    /// Updates the loading state.
    func displayLoading(_ loading: Bool) {
        onLoadingStateChanged?(loading)
    }
    
    /// Notifies the view of an error message.
    func displayError(_ message: String) {
        onErrorOccurred?(message)
    }
}
