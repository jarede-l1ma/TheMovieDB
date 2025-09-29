import Foundation

/// Protocol defining the requirements for an API client capable of fetching Decodable models.
protocol APIClientProtocol {
    /// Executes a request for the given endpoint and decodes the response.
    func request<T: Decodable>(_ endpoint: APIClient.Endpoint) async throws -> T
}

/// Concrete API client for accessing the TMDb API.
struct APIClient: APIClientProtocol {
    /// Shared singleton instance for app-wide usage.
    static let shared = APIClient()

    /// The base URL for the TMDb API.
    private let baseURL = URL(string: "https://api.themoviedb.org/3")
    /// Bearer token for authentication (keep this secure in production).
    private let bearerToken = "YOUR-BEARER-TOKEN-HERE"

    /// Enum representing available API endpoints and their parameters.
    enum Endpoint {
        case nowPlaying(page: Int, language: String? = nil)
        case movieDetails(id: Int, language: String? = nil)

        /// Builds a URLRequest for the endpoint using the provided baseURL and bearer token.
        func makeURLRequest(baseURL: URL, bearerToken: String) throws -> URLRequest {
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + path
            components.queryItems = queryItems

            guard let url = components.url else { throw URLError(.badURL) }

            #if DEBUG
            print("[TMDBAPIClient] GET \(url.absoluteString)")
            #endif

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
        private var queryItems: [URLQueryItem] {
            switch self {
            case let .nowPlaying(page, language):
                return [
                    URLQueryItem(name: "page", value: String(page)),
                    URLQueryItem(name: "language", value: Self.resolveLanguage(language))
                ]
            case let .movieDetails(_, language):
                return [
                    URLQueryItem(name: "language", value: Self.resolveLanguage(language))
                ]
            }
        }

        /// Detects the preferred language based on the user's device or app settings.
        private static func resolveLanguage(_ language: String?) -> String {
            if let language, !language.isEmpty {
                return language
            }
            // Detect preferred language from system settings (e.g., "pt-BR", "en-US")
            let preferred = Locale.preferredLanguages.first ?? "en-US"
            if preferred.hasPrefix("pt") {
                return "pt-BR"
            } else if preferred.hasPrefix("en") {
                return "en-US"
            } else {
                return "en-US" // fallback
            }
        }
    }

    /// Executes an asynchronous HTTP request for a given endpoint and decodes the response.
    /// - Parameter endpoint: The API endpoint to request.
    /// - Returns: The decoded model of type `T`.
    /// - Throws: URLError or decoding errors.
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let baseURL else { throw URLError(.badURL) }
        let request = try endpoint.makeURLRequest(baseURL: baseURL, bearerToken: bearerToken)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        #if DEBUG
        print("[TMDBAPIClient] status=\(http.statusCode)")
        #endif

        guard (200..<300).contains(http.statusCode) else {
            let bodyPreview = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            #if DEBUG
            print("[TMDBAPIClient] error body: \(bodyPreview)")
            #endif
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
