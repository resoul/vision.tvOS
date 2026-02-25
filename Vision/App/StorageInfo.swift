import Foundation
import CoreData

// MARK: - StorageInfo

struct StorageInfo {
    let postersDisk:  Int64   // ~/Library/Caches/posters/
    let watchedDB:    Int64   // WatchedEpisode + MovieProgress + SeriesLastPlayed — реальный объём данных
    let favoritesDB:  Int64   // FavoriteMovie — реальный объём данных
    let coreDataFile: Int64   // весь .sqlite на диске (wal + shm включены)
    let userDefaults: Int64   // .plist настройки

    // watchedDB и favoritesDB — логические срезы coreDataFile,
    // поэтому в total они не суммируются дважды
    var total: Int64 { postersDisk + coreDataFile + userDefaults }

    // MARK: - Async load

    static func load() async -> StorageInfo {
        // Работаем на MainActor — NSManagedObjectContext не thread-safe
        await MainActor.run { calculate() }
    }

    @MainActor
    private static func calculate() -> StorageInfo {
        let fm         = FileManager.default
        let lib        = fm.urls(for: .libraryDirectory,            in: .userDomainMask)[0]
        let caches     = fm.urls(for: .cachesDirectory,             in: .userDomainMask)[0]
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

        // 1. Постеры на диске
        let postersDisk = directorySize(at: caches.appendingPathComponent("posters"))

        // 2. CoreData — реальные файлы на диске
        var coreDataFile: Int64 = 0
        for ext in ["sqlite", "sqlite-wal", "sqlite-shm"] {
            coreDataFile += fileSize(at: appSupport.appendingPathComponent("VisionData.\(ext)"))
        }

        // 3. Реальный объём данных строк по сущностям
        let ctx = CoreDataStack.shared.context
        let watchedDB   = rowBytes(ctx: ctx, entities: ["WatchedEpisode", "MovieProgress", "SeriesLastPlayed"])
        let favoritesDB = rowBytes(ctx: ctx, entities: ["FavoriteMovie"])

        // 4. UserDefaults .plist
        let bundleId     = Bundle.main.bundleIdentifier ?? ""
        let userDefaults = fileSize(at: lib.appendingPathComponent("Preferences/\(bundleId).plist"))

        return StorageInfo(
            postersDisk:  postersDisk,
            watchedDB:    watchedDB,
            favoritesDB:  favoritesDB,
            coreDataFile: coreDataFile,
            userDefaults: userDefaults
        )
    }

    // MARK: - Row bytes
    //
    // Итерируем реальные значения атрибутов объектов и суммируем их байтовые размеры.
    // Это не точный размер SQLite-страниц, но отражает реальный объём хранимых данных
    // в отличие от грубой оценки "count × N".
    @MainActor
    private static func rowBytes(ctx: NSManagedObjectContext, entities: [String]) -> Int64 {
        var total: Int64 = 0
        for name in entities {
            let req = NSFetchRequest<NSManagedObject>(entityName: name)
            req.includesPropertyValues = true
            guard let objects = try? ctx.fetch(req) else { continue }
            for obj in objects {
                for (key, attr) in obj.entity.attributesByName {
                    if let value = obj.value(forKey: key) {
                        total += attributeBytes(value: value, type: attr.attributeType)
                    }
                }
                total += 40 // overhead: objectID, versionStamp, row pointer, meta
            }
        }
        return total
    }

    private static func attributeBytes(value: Any, type: NSAttributeType) -> Int64 {
        switch type {
        case .integer16AttributeType:    return 2
        case .integer32AttributeType:    return 4
        case .integer64AttributeType:    return 8
        case .doubleAttributeType:       return 8
        case .floatAttributeType:        return 4
        case .booleanAttributeType:      return 1
        case .dateAttributeType:         return 8
        case .stringAttributeType:
            return Int64((value as? String)?.utf8.count ?? 0)
        case .binaryDataAttributeType:
            return Int64((value as? Data)?.count ?? 0)
        default:
            return 8
        }
    }

    // MARK: - File helpers

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
