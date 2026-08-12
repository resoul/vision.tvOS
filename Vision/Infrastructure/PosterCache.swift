import UIKit

final class PosterCache {

    static let shared = PosterCache()
    private init() {
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    private let cacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("posters", isDirectory: true)
    }()

    private let memCache = NSCache<NSString, UIImage>()

    private var activeTasks: [String: URLSessionDataTask] = [:]
    private let lock = NSLock()

    func applyMemoryLimit(bytes: Int) {
        if bytes == 0 {

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

        if let cached = memCache.object(forKey: key as NSString) {
            return cached
        }

        let diskURL = cacheDir.appendingPathComponent(key)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if let data = try? Data(contentsOf: diskURL),
               let image = UIImage(data: data) {

                let cost = data.count
                self.memCache.setObject(image, forKey: key as NSString, cost: cost)
                DispatchQueue.main.async { completion(image) }
                return
            }

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

// MARK: - ImageRepositoryProtocol Conformance

extension PosterCache: ImageRepositoryProtocol {
    func loadImage(from url: String, completion: @escaping (UIImage) -> Void) -> UIImage? {
        image(for: url, placeholder: nil, completion: completion)
    }

    func prefetchImage(from url: String) {
        prefetch(urlString: url)
    }

    func cancelLoading(for url: String) {
        cancelTask(for: url)
    }

    func applyCacheLimit(bytes: Int) {
        applyMemoryLimit(bytes: bytes)
    }
    
    func diskCacheSizeBytes() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: cacheDir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            total += Int64((try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        return total
    }
    
    func clearDiskCache() throws {
        lock.lock()
        let tasks = activeTasks.values
        activeTasks.removeAll()
        lock.unlock()
        
        tasks.forEach { $0.cancel() }
        memCache.removeAllObjects()
        
        if FileManager.default.fileExists(atPath: cacheDir.path) {
            try FileManager.default.removeItem(at: cacheDir)
        }
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
}
