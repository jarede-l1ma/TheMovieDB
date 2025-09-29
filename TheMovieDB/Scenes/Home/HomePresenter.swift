import Foundation

/// Presenter for the Home feature.
/// Responsible for transforming data and forwarding it to the ViewModel.
final class HomePresenter: HomePresentationLogic {
    weak var view: HomeDisplayLogic?

    func presentInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool) {
        view?.displayInitial(title: title, items: items, isLoading: isLoading)
    }

    func presentAppend(items: [Home.ItemViewModel]) {
        view?.displayAppend(items: items)
    }

    func presentLoading(_ loading: Bool) {
        view?.displayLoading(loading)
    }

    func presentError(_ message: String) {
        view?.displayError(message)
    }
}
