import Foundation
import os

/// Protocol defining the requirements for an API client capable of fetching Decodable models.
protocol APIClientProtocol {
    /// Executes a request for the given endpoint and decodes the response.
    func request<T: Decodable>(_ endpoint: APIClient.Endpoint) async throws -> T
}

/// Concrete API client for accessing the TMDb API.
struct APIClient: APIClientProtocol {
    /// Shared singleton instance for app-wide usage.
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    /// Resolved on every request so the token can be provisioned after launch.
    private let bearerToken: () -> String

    /// - Parameters:
    ///   - session: The session used to perform requests (inject a stubbed one in tests).
    ///   - baseURL: The base URL for the TMDb API.
    ///   - bearerToken: Provider of the bearer token, loaded from the environment configuration by default.
    init(
        session: URLSession = .shared,
        baseURL: URL = EnvironmentConfig.shared.apiBaseURL,
        bearerToken: @escaping () -> String = { EnvironmentConfig.shared.apiBearerToken }
    ) {
        self.session = session
        self.baseURL = baseURL
        self.bearerToken = bearerToken
    }

    /// Enum representing available API endpoints and their parameters.
    enum Endpoint: Equatable {
        case nowPlaying(page: Int, language: String? = nil)
        case movieDetails(id: Int, language: String? = nil)

        /// Builds a URLRequest for the endpoint using the provided baseURL and bearer token.
        /// - Parameter preferredLanguages: Languages used when the endpoint has no explicit `language`.
        func makeURLRequest(
            baseURL: URL,
            bearerToken: String,
            preferredLanguages: [String] = Locale.preferredLanguages
        ) throws -> URLRequest {
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + path
            components.queryItems = queryItems(preferredLanguages: preferredLanguages)

            guard let url = components.url else { throw URLError(.badURL) }

            AppLogger.api.debug("GET \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
            return request
        }

        /// The path component for each endpoint.
        private var path: String {
            switch self {
            case .nowPlaying:
                return "/movie/now_playing"
            case .movieDetails(let id, _):
                return "/movie/\(id)"
            }
        }

        /// The query parameters for each endpoint.
        private func queryItems(preferredLanguages: [String]) -> [URLQueryItem] {
            switch self {
            case let .nowPlaying(page, language):
                return [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "language", value: Self.resolveLanguage(language, preferredLanguages))
                ]
            case let .movieDetails(_, language):
                return [
                    URLQueryItem(name: "language", value: Self.resolveLanguage(language, preferredLanguages))
                ]
            }
        }

        /// Detects the preferred language based on the user's device or app settings.
        private static func resolveLanguage(_ language: String?, _ preferredLanguages: [String]) -> String {
            if let language, !language.isEmpty {
                return language
            }
            // Detect preferred language from system settings (e.g., "pt-BR", "en-US")
            let preferred = preferredLanguages.first ?? "en-US"
            return preferred.hasPrefix("pt") ? "pt-BR" : "en-US"
        }
    }

    /// Executes an asynchronous HTTP request for a given endpoint and decodes the response.
    /// - Parameter endpoint: The API endpoint to request.
    /// - Returns: The decoded model of type `T`.
    /// - Throws: URLError or decoding errors.
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try endpoint.makeURLRequest(baseURL: baseURL, bearerToken: bearerToken())
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        AppLogger.api.debug("HTTP status=\(http.statusCode)")

        guard (200..<300).contains(http.statusCode) else {
            let bodyPreview = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            AppLogger.api.error("HTTP request failed (\(http.statusCode)): \(bodyPreview)")
            // Localized error message for request failures
            throw NSError(
                domain: "TMDBAPIClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: String(localized: "api.error.requestFailed", defaultValue: "Request failed (\(http.statusCode))")]
            )
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
