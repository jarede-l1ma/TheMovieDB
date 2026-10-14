import XCTest
import UIKit

extension UIView {
    /// Depth-first search for the first subview of the given type.
    func firstSubview<T: UIView>(ofType type: T.Type) -> T? {
        for subview in subviews {
            if let match = subview as? T ?? subview.firstSubview(ofType: type) { return match }
        }
        return nil
    }

    /// All subviews of the given type, depth-first.
    func allSubviews<T: UIView>(ofType type: T.Type) -> [T] {
        subviews.flatMap { subview -> [T] in
            let match = (subview as? T).map { [$0] } ?? []
            return match + subview.allSubviews(ofType: type)
        }
    }

    var allLabelTexts: [String] {
        allSubviews(ofType: UILabel.self).compactMap(\.text)
    }
}

/// Puts the controller in a key window so it can present other controllers (e.g. alerts).
/// Pair it with `await unhost(window)` at the end of the test, so UIKit lets go of the controller
/// before the leak checks run.
@MainActor
func host(_ viewController: UIViewController) -> UIWindow {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = viewController
    window.makeKeyAndVisible()
    return window
}

/// Dismisses anything presented, detaches the controller and lets UIKit finish releasing it.
@MainActor
func unhost(_ window: UIWindow) async {
    window.rootViewController?.dismiss(animated: false)
    window.rootViewController = nil
    window.isHidden = true
    // UIKit releases presented controllers and windows a few main-queue turns later.
    for _ in 0..<2 {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
