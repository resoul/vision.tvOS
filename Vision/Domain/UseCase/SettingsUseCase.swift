import Foundation
import Combine

protocol SettingsUseCaseProtocol {
    var settings: AnyPublisher<SettingsData, Never> { get }
    var storage: AnyPublisher<SettingsStorageData, Never> { get }
    
    func fetchSettings()
    func updateAutoplay(_ isEnabled: Bool)
    func updatePreferredQuality(_ quality: VideoQuality)
    func updateCacheSizeStep(_ step: Int)
    func refreshStorage() async
    func clearPosterCache() async throws
    func clearWatchHistory() async throws
    
    func getCacheSteps() -> [String]
    func getAppVersion() -> String
}

final class SettingsUseCase: SettingsUseCaseProtocol {
    private let repository: SettingsRepositoryProtocol
    private let themeManager: ThemeManagerProtocol
    private let languageManager: LanguageManagerProtocol
    private let imageRepository: ImageRepositoryProtocol
    private let favoritesUseCase: FavoritesUseCaseProtocol
    private let watchHistoryUseCase: WatchHistoryUseCaseProtocol
    
    private let settingsSubject = CurrentValueSubject<SettingsData, Never>(
        SettingsData(isAutoplayEnabled: true, preferredQuality: .auto, cacheSizeStep: 3)
    )
    
    private let storageSubject = CurrentValueSubject<SettingsStorageData, Never>(.empty)
    
    var settings: AnyPublisher<SettingsData, Never> {
        settingsSubject.eraseToAnyPublisher()
    }
    
    var storage: AnyPublisher<SettingsStorageData, Never> {
        storageSubject.eraseToAnyPublisher()
    }
    
    private let cacheSteps = [
        "256 MB", "512 MB", "1 GB", "2 GB", "4 GB", L10n.Settings.Cache.noLimit
    ]
    
    private let cacheBytes = [
        256 * 1024 * 1024,
        512 * 1024 * 1024,
        1024 * 1024 * 1024,
        2048 * 1024 * 1024,
        4096 * 1024 * 1024,
        0
    ]
    
    init(
        repository: SettingsRepositoryProtocol,
        themeManager: ThemeManagerProtocol,
        languageManager: LanguageManagerProtocol,
        imageRepository: ImageRepositoryProtocol,
        favoritesUseCase: FavoritesUseCaseProtocol,
        watchHistoryUseCase: WatchHistoryUseCaseProtocol
    ) {
        self.repository = repository
        self.themeManager = themeManager
        self.languageManager = languageManager
        self.imageRepository = imageRepository
        self.favoritesUseCase = favoritesUseCase
        self.watchHistoryUseCase = watchHistoryUseCase
    }
    
    func fetchSettings() {
        repository.fetchSettings { [weak self] result in
            if case .success(let data) = result {
                self?.settingsSubject.send(data)
                self?.applyCacheLimit(step: data.cacheSizeStep)
            }
        }
    }
    
    func updateAutoplay(_ isEnabled: Bool) {
        var current = settingsSubject.value
        current.isAutoplayEnabled = isEnabled
        settingsSubject.send(current)
        repository.saveAutoplay(isEnabled)
    }
    
    func updatePreferredQuality(_ quality: VideoQuality) {
        var current = settingsSubject.value
        current.preferredQuality = quality
        settingsSubject.send(current)
        repository.savePreferredQuality(quality)
    }
    
    func updateCacheSizeStep(_ step: Int) {
        var current = settingsSubject.value
        let validatedStep = max(0, min(step, cacheSteps.count - 1))
        current.cacheSizeStep = validatedStep
        settingsSubject.send(current)
        repository.saveCacheSizeStep(validatedStep)
        applyCacheLimit(step: validatedStep)
    }
    
    func getCacheSteps() -> [String] {
        return cacheSteps
    }
    
    func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
    
    func refreshStorage() async {
        let postersDiskBytes = imageRepository.diskCacheSizeBytes()
        
        let historyItems = (try? await watchHistoryUseCase.getHistory()) ?? []
        let favoritesItems = (try? await favoritesUseCase.getAll()) ?? []
        
        let watchHistoryBytes = estimatedBytes(for: historyItems)
        let favoritesBytes = estimatedBytes(for: favoritesItems)
        
        let coreDataFileBytes = coreDataStorageBytes()
        let userDefaultsBytes = userDefaultsStorageBytes()
        
        storageSubject.send(
            SettingsStorageData(
                postersDiskBytes: postersDiskBytes,
                watchHistoryBytes: watchHistoryBytes,
                favoritesBytes: favoritesBytes,
                coreDataFileBytes: coreDataFileBytes,
                userDefaultsBytes: userDefaultsBytes,
                watchHistoryCount: historyItems.count,
                favoritesCount: favoritesItems.count
            )
        )
    }
    
    func clearPosterCache() async throws {
        try imageRepository.clearDiskCache()
        await refreshStorage()
    }
    
    func clearWatchHistory() async throws {
        try await watchHistoryUseCase.clearAll()
        await refreshStorage()
    }
    
    private func applyCacheLimit(step: Int) {
        let bytes = cacheBytes[step]
        imageRepository.applyCacheLimit(bytes: bytes)
    }
    
    private func estimatedBytes(for items: [ContentItem]) -> Int64 {
        items.reduce(0) { partial, item in
            partial + estimatedBytes(for: item)
        }
    }
    
    private func estimatedBytes(for item: ContentItem) -> Int64 {
        var total: Int64 = 0
        total += 8 // id
        total += Int64(item.title.utf8.count)
        total += Int64(item.year.utf8.count)
        total += Int64(item.description.utf8.count)
        total += Int64(item.genre.utf8.count)
        total += Int64(item.rating.utf8.count)
        total += Int64(item.duration.utf8.count)
        total += Int64(item.translate.utf8.count)
        total += 1 // isAdIn
        total += Int64(item.movieURL.utf8.count)
        total += Int64(item.posterURL.utf8.count)
        total += Int64(item.lastAdded?.utf8.count ?? 0)
        total += Int64(item.actors.joined(separator: "|").utf8.count)
        total += Int64(item.directors.joined(separator: "|").utf8.count)
        total += Int64(item.genreList.joined(separator: "|").utf8.count)
        
        switch item.type {
        case .movie:
            total += 1
        case .series(let seasons):
            total += 1
            for season in seasons {
                total += Int64(season.title.utf8.count)
                for episode in season.episodes {
                    total += Int64(episode.title.utf8.count)
                    total += Int64(episode.id.utf8.count)
                    for (quality, url) in episode.streams {
                        total += Int64(quality.utf8.count + url.utf8.count)
                    }
                }
            }
        }
        
        return total
    }
    
    private func coreDataStorageBytes() -> Int64 {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let baseName = "Vision.sqlite"
        let sqliteURL = appSupport.appendingPathComponent(baseName)
        let walURL = appSupport.appendingPathComponent("\(baseName)-wal")
        let shmURL = appSupport.appendingPathComponent("\(baseName)-shm")
        return fileSize(at: sqliteURL) + fileSize(at: walURL) + fileSize(at: shmURL)
    }
    
    private func userDefaultsStorageBytes() -> Int64 {
        let fm = FileManager.default
        let lib = fm.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let prefsURL = lib.appendingPathComponent("Preferences/\(bundleId).plist")
        return fileSize(at: prefsURL)
    }
    
    private func fileSize(at url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
    }
}
