import UIKit

final class AppCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let module = HomeModule.build()
        navigationController.setViewControllers([module.viewController], animated: false)
    }
}
