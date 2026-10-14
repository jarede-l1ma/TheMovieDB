import XCTest
@testable import TheMovieDB

@MainActor
final class EndpointTests: XCTestCase {

    private let baseURL = URL(string: "https://api.example.com/3")!

    func test_nowPlaying_buildsURLWithPageAndExplicitLanguage() throws {
        let request = try makeRequest(.nowPlaying(page: 2, language: "pt-BR"))

        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "api.example.com")
        XCTAssertEqual(components.path, "/3/movie/now_playing")
        XCTAssertEqual(components.queryItems, [
            URLQueryItem(name: "page", value: "2"),
            URLQueryItem(name: "language", value: "pt-BR")
        ])
    }

    func test_movieDetails_buildsPathWithMovieID() throws {
        let request = try makeRequest(.movieDetails(id: 42, language: "en-US"))

        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.path, "/3/movie/42")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "language", value: "en-US")])
    }

    func test_makeURLRequest_usesGETWithJSONAcceptAndBearerAuthorization() throws {
        let request = try makeRequest(.nowPlaying(page: 1, language: "en-US"), token: "secret-token")

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json;charset=utf-8")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
    }

    // MARK: - Language

    func test_language_explicitValueWinsOverDevicePreference() throws {
        let request = try makeRequest(.nowPlaying(page: 1, language: "en-US"), preferredLanguages: ["pt-BR"])

        XCTAssertEqual(language(of: request), "en-US")
    }

    func test_language_withoutExplicitValue_mapsAnyPortugueseLocaleToPtBR() throws {
        for preferred in ["pt-BR", "pt-PT", "pt"] {
            let request = try makeRequest(.nowPlaying(page: 1), preferredLanguages: [preferred, "en-US"])

            XCTAssertEqual(language(of: request), "pt-BR", "Preferred language: \(preferred)")
        }
    }

    func test_language_withoutExplicitValue_mapsEnglishAndUnsupportedLocalesToEnUS() throws {
        for preferred in ["en-GB", "en-US", "fr-FR", "ja-JP"] {
            let request = try makeRequest(.movieDetails(id: 1), preferredLanguages: [preferred])

            XCTAssertEqual(language(of: request), "en-US", "Preferred language: \(preferred)")
        }
    }

    func test_language_withoutAnyDevicePreference_fallsBackToEnUS() throws {
        let request = try makeRequest(.nowPlaying(page: 1), preferredLanguages: [])

        XCTAssertEqual(language(of: request), "en-US")
    }

    func test_language_emptyExplicitValue_fallsBackToDevicePreference() throws {
        let request = try makeRequest(.nowPlaying(page: 1, language: ""), preferredLanguages: ["pt-BR"])

        XCTAssertEqual(language(of: request), "pt-BR")
    }

    // MARK: - Helpers

    private func makeRequest(
        _ endpoint: APIClient.Endpoint,
        token: String = "token",
        preferredLanguages: [String] = ["en-US"]
    ) throws -> URLRequest {
        try endpoint.makeURLRequest(baseURL: baseURL, bearerToken: token, preferredLanguages: preferredLanguages)
    }

    private func language(of request: URLRequest) -> String? {
        guard let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        return components.queryItems?.first(where: { $0.name == "language" })?.value
    }
}
