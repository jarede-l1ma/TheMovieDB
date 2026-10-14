import XCTest
@testable import TheMovieDB

final class ImageLoaderTests: XCTestCase {

    // MARK: - URL building

    func test_loadImage_withNilPath_returnsNilWithoutRequesting() async {
        let (sut, recorder) = makeSUT()

        let image = await sut.loadImage(from: nil)

        XCTAssertNil(image)
        XCTAssertEqual(recorder.urls, [])
    }

    func test_loadImage_withEmptyPath_returnsNilWithoutRequesting() async {
        let (sut, recorder) = makeSUT()

        let image = await sut.loadImage(from: "")

        XCTAssertNil(image)
        XCTAssertEqual(recorder.urls, [])
    }

    func test_loadImage_requestsTMDBImageURLWithDefaultSize() async {
        let (sut, recorder) = makeSUT()
        URLProtocolStub.stub(data: makeImageData(), response: anyHTTPURLResponse(), observer: recorder.record)

        _ = await sut.loadImage(from: "/poster.jpg")

        XCTAssertEqual(recorder.urls, [URL(string: "https://image.tmdb.org/t/p/w500/poster.jpg")!])
    }

    func test_loadImage_requestsTMDBImageURLWithGivenSize() async {
        let (sut, recorder) = makeSUT()
        URLProtocolStub.stub(data: makeImageData(), response: anyHTTPURLResponse(), observer: recorder.record)

        _ = await sut.loadImage(from: "/poster.jpg", size: "w185")

        XCTAssertEqual(recorder.urls, [URL(string: "https://image.tmdb.org/t/p/w185/poster.jpg")!])
    }

    // MARK: - Result

    func test_loadImage_onValidImageData_deliversImage() async {
        let (sut, _) = makeSUT()
        URLProtocolStub.stub(data: makeImageData(size: 4), response: anyHTTPURLResponse())

        let image = await sut.loadImage(from: "/poster.jpg")

        XCTAssertEqual(image?.size, CGSize(width: 4, height: 4))
    }

    func test_loadImage_onTransportError_returnsNil() async {
        let (sut, _) = makeSUT()
        URLProtocolStub.stub(error: anyNSError())

        let image = await sut.loadImage(from: "/poster.jpg")

        XCTAssertNil(image)
    }

    func test_loadImage_onDataThatIsNotAnImage_returnsNil() async {
        let (sut, _) = makeSUT()
        URLProtocolStub.stub(data: anyData(), response: anyHTTPURLResponse())

        let image = await sut.loadImage(from: "/poster.jpg")

        XCTAssertNil(image)
    }

    // MARK: - Caching

    func test_loadImage_afterSuccess_servesSamePathFromCacheWithoutRequestingAgain() async {
        let (sut, recorder) = makeSUT()
        URLProtocolStub.stub(data: makeImageData(), response: anyHTTPURLResponse(), observer: recorder.record)
        let first = await sut.loadImage(from: "/poster.jpg")

        let second = await sut.loadImage(from: "/poster.jpg")

        XCTAssertNotNil(first)
        XCTAssertTrue(first === second, "Expected the cached instance")
        XCTAssertEqual(recorder.urls.count, 1)
    }

    func test_loadImage_afterFailure_doesNotCacheAndRetriesOnNextCall() async {
        let (sut, recorder) = makeSUT()
        URLProtocolStub.stub(error: anyNSError(), observer: recorder.record)
        let failed = await sut.loadImage(from: "/poster.jpg")
        URLProtocolStub.stub(data: makeImageData(), response: anyHTTPURLResponse(), observer: recorder.record)

        let retried = await sut.loadImage(from: "/poster.jpg")

        XCTAssertNil(failed)
        XCTAssertNotNil(retried)
        XCTAssertEqual(recorder.urls.count, 2)
    }

    func test_loadImage_concurrentCallsForSamePath_shareASingleDownload() async {
        let (sut, recorder) = makeSUT()
        URLProtocolStub.stub(data: makeImageData(), response: anyHTTPURLResponse(), observer: recorder.record)

        async let first = sut.loadImage(from: "/poster.jpg")
        async let second = sut.loadImage(from: "/poster.jpg")
        let images = await [first, second]

        XCTAssertNotNil(images[0])
        XCTAssertNotNil(images[1])
        XCTAssertEqual(recorder.urls.count, 1)
    }

    func test_loadImage_differentPaths_areDownloadedAndCachedIndependently() async {
        let (sut, recorder) = makeSUT()
        URLProtocolStub.stub(data: makeImageData(), response: anyHTTPURLResponse(), observer: recorder.record)

        _ = await sut.loadImage(from: "/a.jpg")
        _ = await sut.loadImage(from: "/b.jpg")
        _ = await sut.loadImage(from: "/a.jpg")

        XCTAssertEqual(recorder.urls.map(\.lastPathComponent), ["a.jpg", "b.jpg"])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: ImageLoader, recorder: RequestRecorder) {
        addTeardownBlock { URLProtocolStub.removeStub() }
        return (ImageLoader(session: URLProtocolStub.session()), RequestRecorder())
    }

    private func makeImageData(size: CGFloat = 2) -> Data {
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: rect.size, format: format).pngData { context in
            UIColor.red.setFill()
            context.fill(rect)
        }
    }
}

/// Collects requested URLs from the stub's background thread.
private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var _urls = [URL]()

    var urls: [URL] {
        lock.lock(); defer { lock.unlock() }
        return _urls
    }

    func record(_ request: URLRequest) {
        guard let url = request.url else { return }
        lock.lock(); defer { lock.unlock() }
        _urls.append(url)
    }
}
