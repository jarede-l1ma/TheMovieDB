import Foundation

/// Handles business logic and data loading for the Home screen.
final class HomeInteractor: HomeBusinessLogic {

    private let presenter: HomePresentationLogic
    private let api: APIClientProtocol

    private var page: Int = 1
    private var totalPages: Int = 1
    private var isRequesting: Bool = false

    private var currentLoadTask: Task<Void, Never>?

    /// Initializes the interactor with its dependencies.
    /// - Parameters:
    ///   - presenter: Object responsible for presenting data to the ViewModel.
    ///   - api: API client for requesting movie data.
    init(presenter: HomePresentationLogic, api: APIClientProtocol) {
        self.presenter = presenter
        self.api = api
    }

    deinit {
        currentLoadTask?.cancel()
    }

    /// Called when the view is loaded. Begins loading the first page of movies.
    func viewDidLoad() {
        currentLoadTask?.cancel()
        currentLoadTask = Task { await loadFirstPage() }
    }

    /// Loads more data if the user scrolls near the end of the list.
    func loadMoreIfNeeded(visibleIndex: Int, totalCount: Int) {
        guard !isRequesting, page < totalPages else { return }
        let threshold = 6
        if visibleIndex >= max(0, totalCount - threshold) {
            Task { await loadNextPage() }
        }
    }

    /// Resets paging variables to initial state.
    private func resetPaging() {
        page = 1
        totalPages = 1
    }

    /// Updates the loading state and notifies the presenter.
    private func setLoading(_ loading: Bool) {
        isRequesting = loading
        presenter.presentLoading(loading)
    }

    /// Maps raw Movie models to the view models displayed in the UI.
    private func mapMoviesToVM(_ movies: [Movie]) -> [Home.ItemViewModel] {
        movies.map {
            Home.ItemViewModel(
                id: $0.id,
                // Localized fallback for missing title
                title: $0.title ?? String(localized: "movie.noTitle"),
                subtitle: $0.releaseDate,
                posterPath: $0.posterPath
            )
        }
    }

    /// Loads the first page of movies.
    private func loadFirstPage() async {
        resetPaging()
        setLoading(true)
        defer { setLoading(false) }
        do {
            let response: PagedResponse<Movie> = try await api.request(.nowPlaying(page: 1))
            page = response.page
            totalPages = response.totalPages
            let items = mapMoviesToVM(response.results)
            // Localized title for the home screen
            presenter.presentInitial(title: String(localized: "home.title"), items: items, isLoading: false)
        } catch is CancellationError {
            return
        } catch {
            presenter.presentError(error.localizedDescription)
        }
    }

    /// Loads the next page of movies.
    private func loadNextPage() async {
        guard page < totalPages else { return }
        setLoading(true)
        defer { setLoading(false) }
        do {
            let next = page + 1
            let response: PagedResponse<Movie> = try await api.request(.nowPlaying(page: next))
            page = response.page
            totalPages = response.totalPages
            let items = mapMoviesToVM(response.results)
            presenter.presentAppend(items: items)
        } catch is CancellationError {
            return
        } catch {
            presenter.presentError(error.localizedDescription)
        }
    }
}
