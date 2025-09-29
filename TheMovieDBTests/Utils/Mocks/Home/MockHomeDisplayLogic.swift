@testable import TheMovieDB
import Foundation

final class MockHomeDisplayLogic: HomeDisplayLogic {
    
    private(set) var displayInitialCallCount = 0
    private(set) var displayAppendCallCount = 0
    private(set) var displayLoadingCallCount = 0
    private(set) var displayErrorCallCount = 0
    
    private(set) var displayInitialCalls: [(title: String, items: [Home.ItemViewModel], isLoading: Bool)] = []
    private(set) var displayAppendCalls: [[Home.ItemViewModel]] = []
    private(set) var displayLoadingCalls: [Bool] = []
    private(set) var displayErrorCalls: [String] = []
    
    func displayInitial(title: String, items: [Home.ItemViewModel], isLoading: Bool) {
        displayInitialCallCount += 1
        displayInitialCalls.append((title: title, items: items, isLoading: isLoading))
    }
    
    func displayAppend(items: [Home.ItemViewModel]) {
        displayAppendCallCount += 1
        displayAppendCalls.append(items)
    }
    
    func displayLoading(_ loading: Bool) {
        displayLoadingCallCount += 1
        displayLoadingCalls.append(loading)
    }
    
    func displayError(_ message: String) {
        displayErrorCallCount += 1
        displayErrorCalls.append(message)
    }
}
