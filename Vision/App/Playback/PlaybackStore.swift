import Foundation
import CoreData

final class PlaybackStore {

    static let shared = PlaybackStore()
    private var ctx: NSManagedObjectContext { CoreDataStack.shared.context }

    private init() {}

    // MARK: - Episode API

    func episodeProgress(movieId: Int, season: Int, episode: Int) -> PlaybackProgress? {
        guard let e = fetchEpisode(movieId: movieId, season: season, episode: episode),
              e.durationSeconds > 0
        else { return nil }
        return PlaybackProgress(
            positionSeconds: e.positionSeconds,
            durationSeconds: e.durationSeconds,
            studio: nil, quality: nil, streamURL: nil
        )
    }

    func saveEpisodeProgress(movieId: Int, season: Int, episode: Int,
                              position: Double, duration: Double) {
        let entry = fetchEpisode(movieId: movieId, season: season, episode: episode)
                    ?? WatchedEpisode(context: ctx)
        entry.movieId          = Int64(movieId)
        entry.season           = Int32(season)
        entry.episode          = Int32(episode)
        entry.positionSeconds  = position
        entry.durationSeconds  = duration
        entry.watched          = (duration > 0 && position / duration >= 0.93)
        entry.updatedAt        = Date()
        CoreDataStack.shared.save()
    }

    func isEpisodeWatched(movieId: Int, season: Int, episode: Int) -> Bool {
        fetchEpisode(movieId: movieId, season: season, episode: episode)?.watched ?? false
    }

    func setEpisodeWatched(_ watched: Bool, movieId: Int, season: Int, episode: Int) {
        let entry = fetchEpisode(movieId: movieId, season: season, episode: episode)
                    ?? WatchedEpisode(context: ctx)
        entry.movieId   = Int64(movieId)
        entry.season    = Int32(season)
        entry.episode   = Int32(episode)
        entry.watched   = watched
        entry.updatedAt = Date()
        CoreDataStack.shared.save()
    }

    func totalEpisodeCount() -> Int {
        (try? ctx.count(for: NSFetchRequest<WatchedEpisode>(entityName: "WatchedEpisode"))) ?? 0
    }

    func clearAllEpisodes() {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "WatchedEpisode")
        _ = try? ctx.execute(NSBatchDeleteRequest(fetchRequest: req))
        CoreDataStack.shared.save()
    }

    // MARK: - Movie API

    func movieProgress(movieId: Int) -> PlaybackProgress? {
        guard let m = fetchMovie(movieId: movieId), m.durationSeconds > 0 else { return nil }
        return PlaybackProgress(
            positionSeconds: m.positionSeconds,
            durationSeconds: m.durationSeconds,
            studio:    m.studio,
            quality:   m.quality,
            streamURL: m.streamURL
        )
    }

    func isMovieWatched(movieId: Int) -> Bool {
        fetchMovie(movieId: movieId)?.watched ?? false
    }

    func saveMovieProgress(movieId: Int,
                            position: Double, duration: Double,
                            studio: String, quality: String, streamURL: String) {
        let entry = fetchMovie(movieId: movieId) ?? MovieProgress(context: ctx)
        let isWatched = duration > 0 && position / duration >= 0.88
        entry.movieId         = Int64(movieId)
        entry.positionSeconds = position
        entry.durationSeconds = duration
        entry.watched         = isWatched
        entry.studio          = studio
        entry.quality         = quality
        entry.streamURL       = streamURL
        entry.updatedAt       = Date()
        CoreDataStack.shared.save()
    }

    func clearMovieProgress(movieId: Int) {
        guard let m = fetchMovie(movieId: movieId) else { return }
        ctx.delete(m)
        CoreDataStack.shared.save()
    }

    // MARK: - Private fetch helpers

    private func fetchEpisode(movieId: Int, season: Int, episode: Int) -> WatchedEpisode? {
        let req = NSFetchRequest<WatchedEpisode>(entityName: "WatchedEpisode")
        req.predicate = NSPredicate(
            format: "movieId == %lld AND season == %d AND episode == %d",
            Int64(movieId), Int32(season), Int32(episode)
        )
        req.fetchLimit = 1
        return try? ctx.fetch(req).first
    }

    private func fetchMovie(movieId: Int) -> MovieProgress? {
        let req = NSFetchRequest<MovieProgress>(entityName: "MovieProgress")
        req.predicate = NSPredicate(format: "movieId == %lld", Int64(movieId))
        req.fetchLimit = 1
        return try? ctx.fetch(req).first
    }
}
