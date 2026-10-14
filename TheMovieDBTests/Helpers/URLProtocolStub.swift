import Foundation

/// Intercepts requests of a `URLSession` built with `URLProtocolStub.session()`, so no test touches the network.
final class URLProtocolStub: URLProtocol {
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
        let requestObserver: ((URLRequest) -> Void)?
    }

    private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
    nonisolated(unsafe) private static var _stub: Stub?

    private static var stub: Stub? {
        get { queue.sync { _stub } }
        set { queue.sync { _stub = newValue } }
    }

    /// A session that routes every request through this stub and never caches.
    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    /// - Parameter observer: Called with each request right before the stubbed outcome is delivered.
    static func stub(
        data: Data? = nil,
        response: URLResponse? = nil,
        error: Error? = nil,
        observer: ((URLRequest) -> Void)? = nil
    ) {
        stub = Stub(data: data, response: response, error: error, requestObserver: observer)
    }

    static func removeStub() {
        stub = nil
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = URLProtocolStub.stub else {
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
            return
        }

        stub.requestObserver?(request)

        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }

        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
