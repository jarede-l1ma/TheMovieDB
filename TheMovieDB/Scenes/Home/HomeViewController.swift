import UIKit

/// Main ViewController responsible for displaying the list of movies on screen in VIPER architecture.
final class HomeViewController: UIViewController {
    // Opt out of the implicit isolated deinit: nested isolated deinits abort in the iOS 26.0/26.1 runtime.
    nonisolated deinit {}

    // MARK: - Properties
    private let interactor: HomeBusinessLogic
    private let router: HomeRouterLogic
    private let homeView = HomeView()
    
    /// Internal datasource items currently displayed in the collection view.
    private var items: [Home.ItemViewModel] = []
    
    // MARK: - Initialization

    /// Initializes the HomeViewController with VIPER business dependencies (SOLID Dependency Inversion Principle).
    /// - Parameters:
    ///   - interactor: Handles business logic for data fetching and state updates.
    ///   - router: Handles navigation from the Home screen.
    init(interactor: HomeBusinessLogic, router: HomeRouterLogic) {
        self.interactor = interactor
        self.router = router
        super.init(nibName: nil, bundle: nil)
        // Localized navigation bar title
        self.title = String(localized: "home.title")
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        interactor.viewDidLoad()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            // Update the collection view layout on orientation change
            self.homeView.collectionView.setCollectionViewLayout(HomeView.makeLayout(), animated: false)
            self.homeView.collectionView.collectionViewLayout.invalidateLayout()
            self.homeView.collectionView.layoutIfNeeded()
        })
    }
    
    // MARK: - Setup
    
    /// Sets up collection view delegate and dataSource.
    private func setupCollectionView() {
        homeView.collectionView.delegate = self
        homeView.collectionView.dataSource = self
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let vm = items[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.reuseId,
            for: indexPath
        ) as? PosterCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: vm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Optimized pagination trigger: evaluated only once per newly displayed cell instead of continuously during scroll
        interactor.loadMoreIfNeeded(visibleIndex: indexPath.item, totalCount: items.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < items.count else { return }
        let item = items[indexPath.item]
        router.routeToMovieDetails(movieID: item.id, title: item.title)
    }
}

// MARK: - HomeDisplayLogic
extension HomeViewController: HomeDisplayLogic {
    /// Displays the initial state of the screen with a loaded list of items.
    func displayInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool) {
        self.title = title
        self.items = items
        homeView.collectionView.reloadData()
        displayLoading(isLoading)
    }
    
    /// Appends new items to the current list for infinite scroll pagination.
    func displayAppend(items: [Home.ItemViewModel]) {
        let start = self.items.count
        let end = start + items.count
        self.items.append(contentsOf: items)
        let indexPaths = (start..<end).map { IndexPath(item: $0, section: 0) }
        
        homeView.collectionView.performBatchUpdates {
            homeView.collectionView.insertItems(at: indexPaths)
        }
    }
    
    /// Updates the loading state activity indicator.
    func displayLoading(_ loading: Bool) {
        if loading {
            homeView.activityIndicator.startAnimating()
        } else {
            homeView.activityIndicator.stopAnimating()
        }
    }
    
    /// Displays an error alert message to the user.
    func displayError(_ message: String) {
        let alert = UIAlertController(
            title: String(localized: "alert.error.title"),
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "alert.ok.button"), style: .default))
        present(alert, animated: true)
    }
}
