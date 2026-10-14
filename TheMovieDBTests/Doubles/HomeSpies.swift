@testable import TheMovieDB
import Foundation

/// Spies record every message they receive, in order, so tests assert on the whole conversation at once.

@MainActor
final class HomePresenterSpy: HomePresentationLogic {
    enum Message: Equatable {
        case initial(title: String, items: [Home.ItemViewModel], isLoading: Bool)
        case append([Home.ItemViewModel])
        case loading(Bool)
        case error(String)
    }

    private(set) var messages = [Message]()
    var onMessage: (() -> Void)?

    func presentInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool) {
        record(.initial(title: title, items: items, isLoading: isLoading))
    }

    func presentAppend(items: [Home.ItemViewModel]) {
        record(.append(items))
    }

    func presentLoading(_ loading: Bool) {
        record(.loading(loading))
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
final class HomeDisplaySpy: HomeDisplayLogic {
    enum Message: Equatable {
        case initial(title: String, items: [Home.ItemViewModel], isLoading: Bool)
        case append([Home.ItemViewModel])
        case loading(Bool)
        case error(String)
    }

    private(set) var messages = [Message]()

    func displayInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool) {
        messages.append(.initial(title: title, items: items, isLoading: isLoading))
    }

    func displayAppend(items: [Home.ItemViewModel]) {
        messages.append(.append(items))
    }

    func displayLoading(_ loading: Bool) {
        messages.append(.loading(loading))
    }

    func displayError(_ message: String) {
        messages.append(.error(message))
    }
}

@MainActor
final class HomeInteractorSpy: HomeBusinessLogic {
    enum Message: Equatable {
        case viewDidLoad
        case loadMoreIfNeeded(visibleIndex: Int, totalCount: Int)
    }

    private(set) var messages = [Message]()

    func viewDidLoad() {
        messages.append(.viewDidLoad)
    }

    func loadMoreIfNeeded(visibleIndex: Int, totalCount: Int) {
        messages.append(.loadMoreIfNeeded(visibleIndex: visibleIndex, totalCount: totalCount))
    }
}

@MainActor
final class HomeRouterSpy: HomeRouterLogic {
    enum Message: Equatable {
        case routeToMovieDetails(movieID: Int, title: String)
    }

    private(set) var messages = [Message]()

    func routeToMovieDetails(movieID: Int, title: String) {
        messages.append(.routeToMovieDetails(movieID: movieID, title: title))
    }
}
