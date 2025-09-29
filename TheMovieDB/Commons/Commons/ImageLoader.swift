import UIKit

/// Singleton class for downloading and caching images asynchronously.
/// Handles image requests, in-memory caching, and avoids duplicate downloads.
final class ImageLoader {
    /// Shared singleton instance.
    static let shared = ImageLoader()

    /// In-memory image cache keyed by NSURL.
    private let cache = NSCache<NSURL, UIImage>()
    /// Tracks currently running image download tasks.
    private var runningTasks = [NSURL: URLSessionDataTask]()
    /// Lock for synchronizing access to runningTasks.
    private let lock = NSLock()

    /// Private initializer to enforce singleton usage.
    private init() { }

    /// Loads an image from the remote TMDb API, caching the result.
    /// - Parameters:
    ///   - path: The image path provided by the API.
    ///   - size: The desired image size (TMDb image size string).
    /// - Returns: The loaded UIImage or nil if the request fails.
    func loadImage(from path: String?, size: String = "w500") async -> UIImage? {
        guard let path, let url = URL(string: "https://image.tmdb.org/t/p/\(size)\(path)") else { return nil }
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

        // Download the image asynchronously and cache it.
        return await withCheckedContinuation { continuation in
            lock.lock()
            // Cancel any previous running task for this URL.
            if let task = runningTasks[nsURL] {
                task.cancel()
                runningTasks[nsURL] = nil
            }
            // Start a new data task for the image.
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                defer {
                    self?.lock.lock()
                    self?.runningTasks[nsURL] = nil
                    self?.lock.unlock()
                }
                guard let data, let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                self?.cache.setObject(image, forKey: nsURL)
                continuation.resume(returning: image)
            }
            runningTasks[nsURL] = task
            lock.unlock()
            task.resume()
        }
    }
}
