import UIKit

/// Thread-safe actor singleton for downloading and caching images asynchronously.
/// Handles image requests, in-memory caching, and avoids duplicate downloads.
actor ImageLoader {
    /// Shared singleton instance.
    static let shared = ImageLoader()

    /// In-memory image cache keyed by NSURL with strict cost/count limits.
    private let cache: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.countLimit = 100
        c.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return c
    }()
    
    /// Tracks currently running image download tasks.
    private var runningTasks = [NSURL: Task<UIImage?, Never>]()

    private let session: URLSession

    /// - Parameter session: The session used to download images (inject a stubbed one in tests).
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Loads an image from the remote TMDb API, caching the result.
    /// - Parameters:
    ///   - path: The image path provided by the API.
    ///   - size: The desired image size (TMDb image size string).
    /// - Returns: The loaded UIImage or nil if the request fails.
    func loadImage(from path: String?, size: String = "w500") async -> UIImage? {
        guard let path, !path.isEmpty, let url = URL(string: "https://image.tmdb.org/t/p/\(size)\(path)") else { return nil }
        return await loadImage(from: url)
    }

    /// Loads an image from a URL, using cache if available.
    /// - Parameter url: The full image URL.
    /// - Returns: The loaded UIImage or nil if the request fails.
    func loadImage(from url: URL) async -> UIImage? {
        let nsURL = url as NSURL

        // Return image from cache if available.
        if let cached = cache.object(forKey: nsURL) {
            return cached
        }

        // If there is already a download task for this URL, await its result instead of starting a new one.
        if let existingTask = runningTasks[nsURL] {
            return await existingTask.value
        }

        // Create a new task to download the image.
        let task = Task<UIImage?, Never> {
            defer {
                Task {
                    removeTask(for: nsURL)
                }
            }
            do {
                let (data, _) = try await session.data(from: url)
                if let image = UIImage(data: data) {
                    self.cacheImage(image, for: nsURL)
                    return image
                }
            } catch {
                // Return nil on failure
            }
            return nil
        }
        
        runningTasks[nsURL] = task
        return await task.value
    }

    private func removeTask(for nsURL: NSURL) {
        runningTasks[nsURL] = nil
    }

    private func cacheImage(_ image: UIImage, for nsURL: NSURL) {
        // Decoded bitmap size: cheap to compute, unlike re-encoding the image as JPEG.
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: nsURL, cost: cost)
    }
}
