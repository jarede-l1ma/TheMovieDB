import UIKit

/// ViewController responsible for displaying detailed movie information.
final class MovieDetailsViewController: UIViewController, MovieDetailsDisplayLogic {

    private let interactor: MovieDetailsBusinessLogic

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private lazy var responsiveStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private lazy var rightTextStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    private lazy var posterImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.backgroundColor = .secondarySystemBackground
        image.layer.cornerRadius = 8
        let aspect = image.heightAnchor.constraint(
            equalTo: image.widthAnchor,
            multiplier: 1.5
        )
        aspect.priority = .required
        aspect.isActive = true
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    private lazy var overviewLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return label
    }()
    private lazy var ratingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    private lazy var activity: UIActivityIndicatorView = {
        let ac = UIActivityIndicatorView(style: .large)
        ac.hidesWhenStopped = true
        ac.translatesAutoresizingMaskIntoConstraints = false
        return ac
    }()
    private var posterWidthConstraint: NSLayoutConstraint?

    /// Initializes the details screen with its business logic dependency.
    /// - Parameters:
    ///   - interactor: Business logic handler for movie details.
    ///   - title: The navigation bar title.
    init(interactor: MovieDetailsBusinessLogic, title: String) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        interactor.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLayout(for: view.bounds.size)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.updateLayout(for: size)
            self.view.layoutIfNeeded()
        })
    }

    /// Sets up the main view hierarchy and layout constraints.
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        view.addSubview(activity)

        rightTextStack.addArrangedSubview(titleLabel)
        rightTextStack.addArrangedSubview(subtitleLabel)
        rightTextStack.addArrangedSubview(ratingLabel)
        rightTextStack.addArrangedSubview(overviewLabel)

        responsiveStack.addArrangedSubview(posterImageView)
        responsiveStack.addArrangedSubview(rightTextStack)

        contentStack.addArrangedSubview(responsiveStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        posterWidthConstraint = posterImageView.widthAnchor.constraint(equalTo: contentStack.widthAnchor, multiplier: 0.4)
        posterWidthConstraint?.isActive = false
    }

    /// Updates the responsive layout (vertical/horizontal) depending on device orientation.
    /// - Parameter size: New size after transition.
    private func updateLayout(for size: CGSize) {
        let isLandscape = size.width > size.height

        if isLandscape {
            responsiveStack.axis = .horizontal
            responsiveStack.alignment = .top
            responsiveStack.spacing = 16
            posterWidthConstraint?.isActive = true
        } else {
            responsiveStack.axis = .vertical
            responsiveStack.alignment = .fill
            responsiveStack.spacing = 16
            posterWidthConstraint?.isActive = false
        }
    }

    // MARK: - MovieDetailsDisplayLogic

    /// Displays or hides the loading indicator.
    func displayLoading(_ loading: Bool) {
        if loading { activity.startAnimating() } else { activity.stopAnimating() }
    }

    /// Populates the UI with movie details.
    func display(viewModel: MovieDetails.ViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        // Localized rating prefix
        if let ratingText = viewModel.ratingText {
            ratingLabel.text = String(format: String(localized: "movie.rating.prefix"), ratingText)
        } else {
            ratingLabel.text = nil
        }
        overviewLabel.text = viewModel.overview

        Task {
            let image = await ImageLoader.shared.loadImage(from: viewModel.posterPath)
            await MainActor.run { self.posterImageView.image = image }
        }
    }

    /// Presents an error alert with localized strings.
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
