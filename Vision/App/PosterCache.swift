import UIKit

// MARK: - PosterCache

final class PosterCache {

    static let shared = PosterCache()
    private init() {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // ~/Library/Caches/posters/
    private let cacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("posters", isDirectory: true)
    }()

    // In-memory cache
    private let memCache = NSCache<NSString, UIImage>()

    // Active tasks — avoid duplicate downloads
    private var activeTasks: [String: URLSessionDataTask] = [:]
    private let lock = NSLock()

    // MARK: - Memory Limit

    /// Call from CacheSettings whenever the user changes the slider.
    func applyMemoryLimit(bytes: Int) {
        if bytes == 0 {
            // NSCache treats 0 as "no limit"
            memCache.totalCostLimit = 0
        } else {
            memCache.totalCostLimit = bytes
        }
    }

    // MARK: - Public API

    @discardableResult
    func image(for urlString: String,
               placeholder: UIImage?,
               completion: @escaping (UIImage) -> Void) -> UIImage? {

        guard !urlString.isEmpty, let url = URL(string: urlString) else { return nil }
        let key = cacheKey(for: urlString)

        // 1. Memory hit
        if let cached = memCache.object(forKey: key as NSString) {
            return cached
        }

        // 2. Disk hit (async read)
        let diskURL = cacheDir.appendingPathComponent(key)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if let data = try? Data(contentsOf: diskURL),
               let image = UIImage(data: data) {
                // Store with approximate byte cost
                let cost = data.count
                self.memCache.setObject(image, forKey: key as NSString, cost: cost)
                DispatchQueue.main.async { completion(image) }
                return
            }
            // 3. Network download
            self.download(url: url, key: key, diskURL: diskURL, completion: completion)
        }

        return nil
    }

    func prefetch(urlString: String) {
        guard !urlString.isEmpty else { return }
        image(for: urlString, placeholder: nil) { _ in }
    }

    func cancelTask(for urlString: String) {
        let key = cacheKey(for: urlString)
        lock.lock()
        activeTasks[key]?.cancel()
        activeTasks.removeValue(forKey: key)
        lock.unlock()
    }

    // MARK: - Private

    private func download(url: URL, key: String, diskURL: URL,
                          completion: @escaping (UIImage) -> Void) {
        lock.lock()
        if activeTasks[key] != nil { lock.unlock(); return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self else { return }

            self.lock.lock()
            self.activeTasks.removeValue(forKey: key)
            self.lock.unlock()

            guard let data, error == nil,
                  let image = UIImage(data: data) else { return }

            try? data.write(to: diskURL, options: .atomic)
            self.memCache.setObject(image, forKey: key as NSString, cost: data.count)

            DispatchQueue.main.async { completion(image) }
        }
        activeTasks[key] = task
        lock.unlock()

        task.resume()
    }

    private func cacheKey(for urlString: String) -> String {
        let safe = urlString
            .replacingOccurrences(of: "/",  with: "_")
            .replacingOccurrences(of: ":",  with: "_")
            .replacingOccurrences(of: "?",  with: "_")
            .replacingOccurrences(of: "=",  with: "_")
            .replacingOccurrences(of: "&",  with: "_")
        return String(safe.suffix(128))
    }
}
