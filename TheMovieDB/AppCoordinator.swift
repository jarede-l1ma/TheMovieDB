import UIKit

final class AppCoordinator: Coordinator {
    // Opt out of the implicit isolated deinit: nested isolated deinits abort in the iOS 26.0/26.1 runtime.
    nonisolated deinit {}

    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let module = HomeModule.build()
        navigationController.setViewControllers([module.viewController], animated: false)
    }
}
