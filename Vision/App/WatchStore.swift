import Foundation
import CoreData

// MARK: - WatchStore
// Теперь делегирует всё в PlaybackStore.
// Оставлен для совместимости с существующими вызовами в коде.

final class WatchStore {
    static let shared = WatchStore()
    private init() {}

    func isWatched(movieId: Int, season: Int, episode: Int) -> Bool {
        PlaybackStore.shared.isEpisodeWatched(movieId: movieId, season: season, episode: episode)
    }

    func setWatched(_ watched: Bool, movieId: Int, season: Int, episode: Int) {
        PlaybackStore.shared.setEpisodeWatched(watched, movieId: movieId, season: season, episode: episode)
    }

    func totalCount() -> Int {
        PlaybackStore.shared.totalEpisodeCount()
    }

    func clearAll() {
        PlaybackStore.shared.clearAllEpisodes()
    }
}
