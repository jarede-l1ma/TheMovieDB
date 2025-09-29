import UIKit

/// Main ViewController responsible for displaying the list of movies on screen.
final class HomeViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: HomeViewModel
    private let homeView = HomeView()
    
    // MARK: - Initialization

    /// Initializes the HomeViewController with its ViewModel.
    /// - Parameter viewModel: The ViewModel managing the data for the screen.
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        // Localized navigation bar title
        self.title = String(localized: "home.title")
        self.navigationItem.largeTitleDisplayMode = .never
        setupBindings()
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
        viewModel.viewDidLoad()
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
    
    /// Binds ViewModel events to UI updates.
    private func setupBindings() {
        viewModel.onItemsUpdated = { [weak self] items in
            self?.homeView.collectionView.reloadData()
        }
        
        viewModel.onItemsAppended = { [weak self] items in
            guard let self = self else { return }
            let start = self.viewModel.items.count - items.count
            let end = self.viewModel.items.count
            var indexPaths: [IndexPath] = []
            for i in start..<end { indexPaths.append(IndexPath(item: i, section: 0)) }
            
            self.homeView.collectionView.performBatchUpdates {
                self.homeView.collectionView.insertItems(at: indexPaths)
            }
        }
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            if isLoading {
                self?.homeView.activityIndicator.startAnimating()
            } else {
                self?.homeView.activityIndicator.stopAnimating()
            }
        }
        
        viewModel.onErrorOccurred = { [weak self] message in
            // Localized alert title and button text
            let alert = UIAlertController(
                title: String(localized: "alert.error.title"),
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(localized: "alert.ok.button"), style: .default))
            self?.present(alert, animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let vm = viewModel.items[indexPath.item]
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.reuseId,
            for: indexPath
        ) as? PosterCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: vm)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleMax = homeView.collectionView.indexPathsForVisibleItems.map { $0.item }.max() ?? 0
        viewModel.loadMoreIfNeeded(visibleIndex: visibleMax, totalCount: viewModel.items.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelectItem(at: indexPath.item)
    }
}
