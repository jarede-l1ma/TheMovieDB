import UIKit

/// Factory for building the Home feature's module and wiring dependencies.
enum HomeModule {
    /// Builds and returns the Home view controller and its business logic handler.
    static func build() -> (viewController: UIViewController, interactor: HomeBusinessLogic) {
        let presenter = HomePresenter()
        let interactor = HomeInteractor(presenter: presenter, api: APIClient.shared)
        let router = HomeRouter()
        let viewModel = HomeViewModel(
            interactor: interactor,
            router: router,
            presenter: presenter
        )
        let vc = HomeViewController(viewModel: viewModel)

        presenter.view = viewModel
        router.viewController = vc

        return (vc, interactor)
    }
}
