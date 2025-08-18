import UIKit

final class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager: FileManager
    private let baseDirectory: URL

    private let CACHE_DIRECTORY_NAME = "com.example.cache"
    
    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        baseDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func loadData(from url: URL) async throws -> Data {
        let filename = url.lastPathComponent
        let fileURL = getCacheDirectory().appendingPathComponent(filename)

        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL) {
            return data
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        try? data.write(to: fileURL)
        
        return data
    }
    
    func loadImage(from url: URL) async throws -> UIImage {
        let data = try await loadData(from: url)
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "CacheManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        return image
    }
    
    func createCacheDirectory() {
        let folderURL = getCacheDirectory()
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("❌ Error when create folder: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ Folder exists: \(folderURL.path)")
        }
    }
    
    private func getCacheDirectory() -> URL {
        return baseDirectory.appendingPathComponent(CACHE_DIRECTORY_NAME)
    }
}
