import UIKit

/// Main view for displaying the movie list using a collection view and loading indicator.
final class HomeView: UIView {
    
    // MARK: - UI Components
    
    /// The collection view for displaying movie poster cells.
    let collectionView: UICollectionView
    /// The activity indicator for loading state.
    let activityIndicator: UIActivityIndicatorView
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        let layout = HomeView.makeLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.activityIndicator = UIActivityIndicatorView(style: .large)
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    /// Configures view hierarchy and properties.
    private func setupViews() {
        backgroundColor = .systemBackground
        
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.isDirectionalLockEnabled = true
        
        collectionView.register(
            PosterCollectionViewCell.self, 
            forCellWithReuseIdentifier: PosterCollectionViewCell.reuseId
        )
        
        addSubview(collectionView)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
    }
    
    /// Sets up view constraints for collection view and activity indicator.
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - Layout
    
    /// Creates the compositional layout for the collection view.
    static func makeLayout() -> UICollectionViewLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { (_, environment) -> NSCollectionLayoutSection? in
            let size = environment.container.effectiveContentSize
            let isLandscape = size.width > size.height
            let columns = isLandscape ? 3 : 2

            let itemWidthFraction: CGFloat
            if #available(iOS 16.0, *) {
                itemWidthFraction = 1.0 / CGFloat(columns)
            } else {
                itemWidthFraction = 1.0
            }

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(itemWidthFraction),
                heightDimension: .estimated(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(320)
            )
            let group: NSCollectionLayoutGroup
            if #available(iOS 16.0, *) {
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: columns)
            } else {
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: columns)
            }

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
            section.orthogonalScrollingBehavior = .none
            return section
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .vertical

        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: configuration)
        return layout
    }
}
