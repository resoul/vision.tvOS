import Foundation

final class SettingsService: SettingsRepositoryProtocol {
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let autoplay = "settings_autoplay"
        static let quality  = "settings_preferred_quality"
        static let cache    = "settings_cache_step"
    }
    
    func fetchSettings(completion: @escaping (Result<SettingsData, Error>) -> Void) {
        let isAutoplay = userDefaults.object(forKey: Keys.autoplay) as? Bool ?? true
        let qualityRaw = userDefaults.string(forKey: Keys.quality) ?? VideoQuality.auto.rawValue
        let quality = VideoQuality(rawValue: qualityRaw) ?? .auto
        let cacheStep = userDefaults.integer(forKey: Keys.cache)
        let finalCacheStep = userDefaults.object(forKey: Keys.cache) != nil ? cacheStep : 3
        
        let data = SettingsData(
            isAutoplayEnabled: isAutoplay,
            preferredQuality: quality,
            cacheSizeStep: finalCacheStep
        )
        completion(.success(data))
    }

    func saveAutoplay(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: Keys.autoplay)
    }
    
    func savePreferredQuality(_ quality: VideoQuality) {
        userDefaults.set(quality.rawValue, forKey: Keys.quality)
    }
    
    func saveCacheSizeStep(_ step: Int) {
        userDefaults.set(step, forKey: Keys.cache)
    }
}

