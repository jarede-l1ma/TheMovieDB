import XCTest

// NOTE: tests that build `@MainActor` objects (presenters, view controllers, the interactors) are
// declared `async`. The app target uses MainActor default isolation, so those classes get an isolated
// deinit. When such an object is released inline at the end of a *synchronous* test method, the
// iOS 26.0 simulator runtime aborts in `swift_task_deinitOnExecutorMainActorBackDeploy`
// ("pointer being freed was not allocated"). Having a current Task avoids it.

extension XCTestCase {
    /// Fails the test if `instance` is still alive after the test finishes (a retain cycle or a leaked reference).
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
