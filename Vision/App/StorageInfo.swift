import Foundation

// MARK: - StorageInfo

struct StorageInfo {
    let postersDisk:  Int64   // ~/Library/Caches/posters/ — реальный размер на диске
    let watchedDB:    Int64   // WatchedEpisode CoreData — оценка по количеству записей
    let coreDataFile: Int64   // .sqlite файл на диске
    let userDefaults: Int64   // .plist файл настроек

    var total: Int64 { postersDisk + watchedDB + coreDataFile + userDefaults }

    // MARK: - Async load

    static func load() async -> StorageInfo {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: calculate())
            }
        }
    }

    private static func calculate() -> StorageInfo {
        let fm  = FileManager.default
        let lib = fm.urls(for: .libraryDirectory,            in: .userDomainMask)[0]
        let caches = fm.urls(for: .cachesDirectory,          in: .userDomainMask)[0]
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

        // 1. Постеры на диске
        let postersDisk = directorySize(at: caches.appendingPathComponent("posters"))

        // 2. CoreData .sqlite (основной файл + wal + shm)
        var coreDataFile: Int64 = 0
        for ext in ["sqlite", "sqlite-wal", "sqlite-shm"] {
            coreDataFile += fileSize(at: appSupport.appendingPathComponent("VisionData.\(ext)"))
        }

        // 3. WatchedEpisode записи — ~80 байт каждая (id + 3 Int + Bool + Date)
        let watchedCount = Int64(WatchStore.shared.totalCount())
        let watchedDB = watchedCount * 80

        // 4. UserDefaults .plist
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let userDefaults = fileSize(at: lib.appendingPathComponent("Preferences/\(bundleId).plist"))

        return StorageInfo(
            postersDisk:  postersDisk,
            watchedDB:    watchedDB,
            coreDataFile: coreDataFile,
            userDefaults: userDefaults
        )
    }

    // MARK: - Helpers

    static func directorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            total += Int64((try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        return total
    }

    static func fileSize(at url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
    }

    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    func fraction(of bytes: Int64) -> Double {
        guard total > 0 else { return 0 }
        return Double(bytes) / Double(total)
    }
}
