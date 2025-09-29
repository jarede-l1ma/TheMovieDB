@testable import TheMovieDB
import Foundation

final class MockAPIClient: APIClientProtocol {
    
    var shouldThrowError = false
    var shouldDelay = false
    var mockError: Error = NSError(domain: "MockError", code: 0, userInfo: nil)
    var mockResponse: Any?
    
    private(set) var requestCallCount = 0
    private(set) var requestCalls: [APIClient.Endpoint] = []
    
    func request<T: Decodable>(_ endpoint: APIClient.Endpoint) async throws -> T {
        requestCallCount += 1
        requestCalls.append(endpoint)
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        
        try Task.checkCancellation()
        
        if shouldThrowError {
            throw mockError
        }
        
        guard let response = mockResponse as? T else {
            throw NSError(domain: "MockAPIClient", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid mock response type"])
        }
        
        return response
    }
    
    func resetCalls() {
        requestCallCount = 0
        requestCalls.removeAll()
    }
}
