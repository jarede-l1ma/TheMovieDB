import UIKit

/// Protocol to define the Coordinator pattern for flow and navigation management.
/// Any coordinator must hold a navigationController and implement the start() method.
protocol Coordinator: AnyObject {
    /// The main navigation controller managed by this coordinator.
    var navigationController: UINavigationController { get }

    /// Starts the flow managed by this coordinator.
    func start()
}
