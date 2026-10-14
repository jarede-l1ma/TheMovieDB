@testable import TheMovieDB
import Foundation

/// Stubs `APIClientProtocol` with queued results and records every requested endpoint.
///
/// By default requests complete immediately with the next queued result. Call `holdRequests()` to keep
/// them suspended until `releaseHeldRequests()`, which makes "request in flight" scenarios deterministic.
@MainActor
final class APIClientStub: APIClientProtocol {
    private(set) var requestedEndpoints = [APIClient.Endpoint]()
    var onRequest: (() -> Void)?

    private var results = [Result<Any, Error>]()
    private var isHolding = false
    private var heldRequests = [CheckedContinuation<Void, Never>]()

    func stub<T>(_ value: T) {
        results.append(.success(value))
    }

    func stub(error: Error) {
        results.append(.failure(error))
    }

    func holdRequests() {
        isHolding = true
    }

    func releaseHeldRequests() {
        isHolding = false
        let continuations = heldRequests
        heldRequests.removeAll()
        continuations.forEach { $0.resume() }
    }

    func request<T: Decodable>(_ endpoint: APIClient.Endpoint) async throws -> T {
        requestedEndpoints.append(endpoint)
        onRequest?()

        if isHolding {
            await withCheckedContinuation { heldRequests.append($0) }
        }
        try Task.checkCancellation()

        guard !results.isEmpty else {
            throw NSError(domain: "APIClientStub", code: -1, userInfo: [NSLocalizedDescriptionKey: "No stubbed result"])
        }

        switch results.removeFirst() {
        case let .success(value):
            guard let typed = value as? T else {
                throw NSError(domain: "APIClientStub", code: -2, userInfo: [NSLocalizedDescriptionKey: "Stubbed value is not a \(T.self)"])
            }
            return typed
        case let .failure(error):
            throw error
        }
    }
}
