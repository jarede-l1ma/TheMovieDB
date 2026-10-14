@testable import TheMovieDB
import Foundation

@MainActor
final class MovieDetailsPresenterSpy: MovieDetailsPresentationLogic {
    enum Message: Equatable {
        case loading(Bool)
        case details(Movie)
        case error(String)
    }

    private(set) var messages = [Message]()
    var onMessage: (() -> Void)?

    func presentLoading(_ loading: Bool) {
        record(.loading(loading))
    }

    func present(details: Movie) {
        record(.details(details))
    }

    func presentError(_ message: String) {
        record(.error(message))
    }

    private func record(_ message: Message) {
        messages.append(message)
        onMessage?()
    }
}

@MainActor
final class MovieDetailsDisplaySpy: MovieDetailsDisplayLogic {
    enum Message: Equatable {
        case loading(Bool)
        case viewModel(MovieDetails.ViewModel)
        case error(String)
    }

    private(set) var messages = [Message]()

    func displayLoading(_ loading: Bool) {
        messages.append(.loading(loading))
    }

    func display(viewModel: MovieDetails.ViewModel) {
        messages.append(.viewModel(viewModel))
    }

    func displayError(_ message: String) {
        messages.append(.error(message))
    }
}

@MainActor
final class MovieDetailsInteractorSpy: MovieDetailsBusinessLogic {
    enum Message: Equatable {
        case viewDidLoad
    }

    private(set) var messages = [Message]()

    func viewDidLoad() {
        messages.append(.viewDidLoad)
    }
}
