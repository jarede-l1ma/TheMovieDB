import UIKit

/// UICollectionViewCell subclass that displays a movie poster and its title.
final class PosterCollectionViewCell: UICollectionViewCell {
    /// Reuse identifier for the cell.
    static let reuseId = "PosterCollectionViewCell"
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.backgroundColor = .secondarySystemBackground
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var activity: UIActivityIndicatorView = {
        let ac = UIActivityIndicatorView(style: .medium)
        ac.hidesWhenStopped = true
        ac.translatesAutoresizingMaskIntoConstraints = false
        return ac
    }()
    
    private var imageTask: Task<Void, Never>?
    private var currentPosterPath: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    /// Configures the view hierarchy and constraints.
    private func setupViews() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.addSubview(activity)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.5),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 6),
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 4),
            titleLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            activity.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        currentPosterPath = nil
        imageView.image = nil
        activity.stopAnimating()
        titleLabel.text = nil
    }
    
    /// Configures the cell with the given view model.
    /// - Parameter vm: The view model containing title and poster path.
    func configure(with vm: Home.ItemViewModel) {
        titleLabel.text = vm.title
        
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        currentPosterPath = vm.posterPath
        
        guard let path = vm.posterPath, !path.isEmpty else {
            activity.stopAnimating()
            return
        }
        
        activity.startAnimating()
        
        imageTask = Task { [weak self] in
            guard let self else { return }
            let image = await ImageLoader.shared.loadImage(from: path)
            guard !Task.isCancelled, self.currentPosterPath == path else { return }
            await MainActor.run {
                self.activity.stopAnimating()
                UIView.transition(with: self.imageView, duration: 0.25, options: .transitionCrossDissolve) {
                    self.imageView.image = image
                }
            }
        }
    }
}
