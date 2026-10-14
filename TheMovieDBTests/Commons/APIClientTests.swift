import XCTest
@testable import TheMovieDB

@MainActor
final class APIClientTests: XCTestCase {

    // MARK: - Request

    func test_request_performsGETAgainstBaseURLWithAuthorizationHeader() async throws {
        let sut = makeSUT(token: "secret-token")
        var observedRequest: URLRequest?
        URLProtocolStub.stub(data: emptyPageJSON(), response: anyHTTPURLResponse()) { observedRequest = $0 }

        let _: PagedResponse<Movie> = try await sut.request(.nowPlaying(page: 2, language: "pt-BR"))

        let request = try XCTUnwrap(observedRequest)
        let components = try XCTUnwrap(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(components.host, "api.example.com")
        XCTAssertEqual(components.path, "/3/movie/now_playing")
        XCTAssertEqual(components.queryItems, [
            URLQueryItem(name: "page", value: "2"),
            URLQueryItem(name: "language", value: "pt-BR")
        ])
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
    }

    func test_request_readsTheBearerTokenOnEveryRequest() async throws {
        var tokens = ["first", "second"]
        let sut = makeSUT(token: { tokens.removeFirst() })
        var authorizations = [String?]()
        URLProtocolStub.stub(data: emptyPageJSON(), response: anyHTTPURLResponse()) {
            authorizations.append($0.value(forHTTPHeaderField: "Authorization"))
        }

        let _: PagedResponse<Movie> = try await sut.request(.nowPlaying(page: 1))
        let _: PagedResponse<Movie> = try await sut.request(.nowPlaying(page: 2))

        XCTAssertEqual(authorizations, ["Bearer first", "Bearer second"])
    }

    // MARK: - Success

    func test_request_on2xxWithValidJSON_decodesSnakeCasePayload() async throws {
        let sut = makeSUT()
        let json = """
        {"page":1,"results":[{"id":7,"title":"Heat","overview":"A heist.","poster_path":"/heat.jpg",
        "backdrop_path":"/heat_bg.jpg","release_date":"1995-12-15","vote_average":8.3}],
        "total_pages":3,"total_results":60}
        """
        URLProtocolStub.stub(data: Data(json.utf8), response: anyHTTPURLResponse(statusCode: 200))

        let response: PagedResponse<Movie> = try await sut.request(.nowPlaying(page: 1))

        XCTAssertEqual(response.page, 1)
        XCTAssertEqual(response.totalPages, 3)
        XCTAssertEqual(response.totalResults, 60)
        XCTAssertEqual(response.results, [
            Movie(id: 7, title: "Heat", overview: "A heist.", posterPath: "/heat.jpg",
                  backdropPath: "/heat_bg.jpg", releaseDate: "1995-12-15", voteAverage: 8.3)
        ])
    }

    func test_request_acceptsTheWholeSuccessRange() async throws {
        let sut = makeSUT()

        for statusCode in [200, 201, 299] {
            URLProtocolStub.stub(data: emptyPageJSON(), response: anyHTTPURLResponse(statusCode: statusCode))

            let response: PagedResponse<Movie> = try await sut.request(.nowPlaying(page: 1))

            XCTAssertEqual(response.page, 1, "Status code: \(statusCode)")
        }
    }

    // MARK: - Failure

    func test_request_onTransportError_throwsThatError() async {
        let sut = makeSUT()
        URLProtocolStub.stub(error: URLError(.notConnectedToInternet))

        let error = await requestError(from: sut)

        XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
    }

    func test_request_onNonHTTPResponse_throwsBadServerResponse() async {
        let sut = makeSUT()
        URLProtocolStub.stub(data: emptyPageJSON(), response: nonHTTPURLResponse())

        let error = await requestError(from: sut)

        XCTAssertEqual((error as? URLError)?.code, .badServerResponse)
    }

    func test_request_onNon2xxStatus_throwsTMDBErrorCarryingTheStatusCode() async {
        let sut = makeSUT()

        for statusCode in [199, 300, 301, 401, 404, 500] {
            URLProtocolStub.stub(data: Data("{}".utf8), response: anyHTTPURLResponse(statusCode: statusCode))

            let error = await requestError(from: sut) as NSError?

            XCTAssertEqual(error?.domain, "TMDBAPIClient", "Status code: \(statusCode)")
            XCTAssertEqual(error?.code, statusCode, "Status code: \(statusCode)")
        }
    }

    func test_request_onNon2xxStatus_doesNotTryToDecodeTheBody() async {
        let sut = makeSUT()
        URLProtocolStub.stub(data: emptyPageJSON(), response: anyHTTPURLResponse(statusCode: 500))

        let error = await requestError(from: sut)

        XCTAssertFalse(error is DecodingError)
    }

    func test_request_on2xxWithInvalidJSON_throwsDecodingError() async {
        let sut = makeSUT()
        URLProtocolStub.stub(data: anyData(), response: anyHTTPURLResponse())

        let error = await requestError(from: sut)

        XCTAssertTrue(error is DecodingError, "Expected DecodingError, got \(String(describing: error))")
    }

    // MARK: - Helpers

    private func makeSUT(token: String = "token", file: StaticString = #filePath, line: UInt = #line) -> APIClient {
        makeSUT(token: { token }, file: file, line: line)
    }

    private func makeSUT(token: @escaping () -> String, file: StaticString = #filePath, line: UInt = #line) -> APIClient {
        addTeardownBlock { URLProtocolStub.removeStub() }
        return APIClient(
            session: URLProtocolStub.session(),
            baseURL: URL(string: "https://api.example.com/3")!,
            bearerToken: token
        )
    }

    private func emptyPageJSON() -> Data {
        Data(#"{"page":1,"results":[],"total_pages":1,"total_results":0}"#.utf8)
    }

    private func requestError(from sut: APIClient, file: StaticString = #filePath, line: UInt = #line) async -> Error? {
        do {
            let _: PagedResponse<Movie> = try await sut.request(.nowPlaying(page: 1))
            XCTFail("Expected request to fail", file: file, line: line)
            return nil
        } catch {
            return error
        }
    }
}
