import UIKit
import CoreData

final class WatchHistoryStore {

    static let shared = WatchHistoryStore()
    private var ctx: NSManagedObjectContext { CoreDataStack.shared.context }

    private init() {}

    // MARK: - Public API

    func active() -> [Movie] {
        let req = NSFetchRequest<WatchHistoryEntry>(entityName: "WatchHistoryEntry")
        req.sortDescriptors = [NSSortDescriptor(key: "lastWatchedAt", ascending: false)]
        let results = (try? ctx.fetch(req)) ?? []

        return results.compactMap { entry -> Movie? in
            let movieId = Int(entry.movieId)
            if entry.isSeries {
                return isSeriesInProgress(movieId: movieId) ? toMovie(entry) : nil
            } else {
                guard let progress = PlaybackStore.shared.movieProgress(movieId: movieId),
                      progress.hasProgress
                else { return nil }
                return toMovie(entry)
            }
        }
    }

    func all() -> [Movie] {
        let req = NSFetchRequest<WatchHistoryEntry>(entityName: "WatchHistoryEntry")
        req.sortDescriptors = [NSSortDescriptor(key: "lastWatchedAt", ascending: false)]
        let results = (try? ctx.fetch(req)) ?? []
        return results.map { toMovie($0) }
    }

    func touch(_ movie: Movie) {
        let entry = fetch(id: movie.id) ?? WatchHistoryEntry(context: ctx)
        fill(entry, from: movie)
        entry.lastWatchedAt = Date()
        CoreDataStack.shared.save()
    }

    func remove(id: Int) {
        guard let entry = fetch(id: id) else { return }
        ctx.delete(entry)
        CoreDataStack.shared.save()
    }

    func contains(id: Int) -> Bool {
        fetch(id: id) != nil
    }

    func clearAll() {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "WatchHistoryEntry")
        _ = try? ctx.execute(NSBatchDeleteRequest(fetchRequest: req))
        CoreDataStack.shared.save()
    }

    // MARK: - Progress helpers

    func progressFraction(for movie: Movie) -> Double? {
        guard !movie.type.isSeries else { return nil }
        return PlaybackStore.shared.movieProgress(movieId: movie.id)?.fraction
    }

    /// Сериал "в процессе" — есть хотя бы один начатый, но не завершённый эпизод
    func isSeriesInProgress(movieId: Int) -> Bool {
        let req = NSFetchRequest<WatchedEpisode>(entityName: "WatchedEpisode")
        req.predicate = NSPredicate(
            format: "movieId == %lld AND positionSeconds > 5 AND watched == NO",
            Int64(movieId)
        )
        req.fetchLimit = 1
        let count = (try? ctx.count(for: req)) ?? 0
        return count > 0
    }

    // MARK: - Private

    private func fetch(id: Int) -> WatchHistoryEntry? {
        let req = NSFetchRequest<WatchHistoryEntry>(entityName: "WatchHistoryEntry")
        req.predicate  = NSPredicate(format: "movieId == %lld", Int64(id))
        req.fetchLimit = 1
        return try? ctx.fetch(req).first
    }

    private func fill(_ entry: WatchHistoryEntry, from movie: Movie) {
        entry.movieId          = Int64(movie.id)
        entry.title            = movie.title
        entry.year             = movie.year
        entry.movieDescription = movie.description
        entry.imageName        = movie.imageName
        entry.genre            = movie.genre
        entry.rating           = movie.rating
        entry.duration         = movie.duration
        entry.isSeries         = movie.type.isSeries
        entry.translate        = movie.translate
        entry.isAdIn           = movie.isAdIn
        entry.movieURL         = movie.movieURL
        entry.posterURL        = movie.posterURL
        entry.lastAdded        = movie.lastAdded
        entry.actorsJSON       = encode(movie.actors)
        entry.directorsJSON    = encode(movie.directors)
        entry.genreListJSON    = encode(movie.genreList)
    }

    private func toMovie(_ entry: WatchHistoryEntry) -> Movie {
        Movie(
            id:          Int(entry.movieId),
            title:       entry.title,
            year:        entry.year             ?? "—",
            description: entry.movieDescription ?? "",
            imageName:   entry.imageName        ?? "",
            genre:       entry.genre            ?? "—",
            rating:      entry.rating           ?? "—",
            duration:    entry.duration         ?? "—",
            type:        entry.isSeries ? .series(seasons: []) : .movie,
            translate:   entry.translate        ?? "",
            isAdIn:      entry.isAdIn,
            movieURL:    entry.movieURL         ?? "",
            posterURL:   entry.posterURL        ?? "",
            actors:      decode(entry.actorsJSON),
            directors:   decode(entry.directorsJSON),
            genreList:   decode(entry.genreListJSON),
            lastAdded:   entry.lastAdded
        )
    }

    private func encode(_ array: [String]) -> String? {
        guard let data = try? JSONEncoder().encode(array) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decode(_ json: String?) -> [String] {
        guard let json,
              let data  = json.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return array
    }
}
