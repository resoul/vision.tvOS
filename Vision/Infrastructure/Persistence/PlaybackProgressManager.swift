import Foundation

struct PlaybackProgress: Codable {
    let positionSeconds: Double
    let durationSeconds: Double
    let lastUpdated: Date
    
    var fraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return positionSeconds / durationSeconds
    }
}

protocol PlaybackProgressManagerProtocol {
    func saveProgress(movieId: Int, season: Int?, episode: Int?, position: Double, duration: Double)
    func getProgress(movieId: Int, season: Int?, episode: Int?) -> PlaybackProgress?
    func isWatched(movieId: Int, season: Int?, episode: Int?) -> Bool
    func setWatched(_ watched: Bool, movieId: Int, season: Int?, episode: Int?)
}

final class PlaybackProgressManager: PlaybackProgressManagerProtocol {
    private let userDefaults = UserDefaults.standard
    private let progressKey = "v_playback_progress"
    private let watchedKey = "v_watched_items"
    
    func saveProgress(movieId: Int, season: Int?, episode: Int?, position: Double, duration: Double) {
        let key = storageKey(movieId: movieId, season: season, episode: episode)
        let progress = PlaybackProgress(positionSeconds: position, durationSeconds: duration, lastUpdated: Date())
        
        var all = loadAllProgress()
        all[key] = progress
        saveAllProgress(all)
        
        if progress.fraction > 0.93 {
            setWatched(true, movieId: movieId, season: season, episode: episode)
        }
    }
    
    func getProgress(movieId: Int, season: Int?, episode: Int?) -> PlaybackProgress? {
        let key = storageKey(movieId: movieId, season: season, episode: episode)
        return loadAllProgress()[key]
    }
    
    func isWatched(movieId: Int, season: Int?, episode: Int?) -> Bool {
        let key = storageKey(movieId: movieId, season: season, episode: episode)
        return loadWatched().contains(key)
    }
    
    func setWatched(_ watched: Bool, movieId: Int, season: Int?, episode: Int?) {
        let key = storageKey(movieId: movieId, season: season, episode: episode)
        var all = loadWatched()
        if watched {
            all.insert(key)
        } else {
            all.remove(key)
        }
        saveWatched(all)
    }
    
    private func storageKey(movieId: Int, season: Int?, episode: Int?) -> String {
        if let s = season, let e = episode {
            return "\(movieId)_s\(s)_e\(e)"
        }
        return "\(movieId)"
    }
    
    private func loadAllProgress() -> [String: PlaybackProgress] {
        guard let data = userDefaults.data(forKey: progressKey),
              let decoded = try? JSONDecoder().decode([String: PlaybackProgress].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    private func saveAllProgress(_ all: [String: PlaybackProgress]) {
        if let data = try? JSONEncoder().encode(all) {
            userDefaults.set(data, forKey: progressKey)
        }
    }
    
    private func loadWatched() -> Set<String> {
        let array = userDefaults.array(forKey: watchedKey) as? [String] ?? []
        return Set(array)
    }
    
    private func saveWatched(_ all: Set<String>) {
        userDefaults.set(Array(all), forKey: watchedKey)
    }
}
