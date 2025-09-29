@testable import TheMovieDB
import Foundation

final class MockHomePresentationLogic: HomePresentationLogic {
    
    private(set) var presentInitialCallCount = 0
    private(set) var presentAppendCallCount = 0
    private(set) var presentLoadingCallCount = 0
    private(set) var presentErrorCallCount = 0
    
    private(set) var presentInitialCalls: [(title: String, items: [Home.ItemViewModel], isLoading: Bool)] = []
    private(set) var presentAppendCalls: [[Home.ItemViewModel]] = []
    private(set) var presentLoadingCalls: [Bool] = []
    private(set) var presentErrorCalls: [String] = []
    
    func presentInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool) {
        presentInitialCallCount += 1
        presentInitialCalls.append((title: title, items: items, isLoading: isLoading))
    }
    
    func presentAppend(items: [Home.ItemViewModel]) {
        presentAppendCallCount += 1
        presentAppendCalls.append(items)
    }
    
    func presentLoading(_ loading: Bool) {
        presentLoadingCallCount += 1
        presentLoadingCalls.append(loading)
    }
    
    func presentError(_ message: String) {
        presentErrorCallCount += 1
        presentErrorCalls.append(message)
    }
    
    func resetCalls() {
        presentInitialCallCount = 0
        presentAppendCallCount = 0
        presentLoadingCallCount = 0
        presentErrorCallCount = 0
        
        presentInitialCalls.removeAll()
        presentAppendCalls.removeAll()
        presentLoadingCalls.removeAll()
        presentErrorCalls.removeAll()
    }
}
