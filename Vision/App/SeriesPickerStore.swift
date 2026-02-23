import UIKit

final class SeriesPickerStore {
    static let shared = SeriesPickerStore()
    private let defaults = UserDefaults.standard
    private static let globalQualityKey = "globalPreferredStreamQuality"

    var globalPreferredQuality: String? {
        get { UserDefaults.standard.string(forKey: Self.globalQualityKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.globalQualityKey) }
    }

    private func key(_ movieId: Int, _ suffix: String) -> String { "series_picker_\(movieId)_\(suffix)" }

    func season(movieId: Int) -> Int      { defaults.integer(forKey: key(movieId, "season")) }
    func episode(movieId: Int) -> Int     { defaults.integer(forKey: key(movieId, "episode")) }
    func quality(movieId: Int) -> String? { defaults.string(forKey: key(movieId, "quality")) }
    func studio(movieId: Int) -> String?  { defaults.string(forKey: key(movieId, "studio")) }

    func save(movieId: Int, season: Int, episode: Int, quality: String, studio: String) {
        defaults.set(season,  forKey: key(movieId, "season"))
        defaults.set(episode, forKey: key(movieId, "episode"))
        defaults.set(quality, forKey: key(movieId, "quality"))
        defaults.set(studio,  forKey: key(movieId, "studio"))
    }
}
