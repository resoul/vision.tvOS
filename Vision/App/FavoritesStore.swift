import UIKit
import CoreData

final class FavoritesStore {

    static let shared = FavoritesStore()
    private var ctx: NSManagedObjectContext { CoreDataStack.shared.context }

    private init() {}

    // MARK: - Public API

    func all() -> [Movie] {
        let req = NSFetchRequest<FavoriteMovie>(entityName: "FavoriteMovie")
        req.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
        let results = (try? ctx.fetch(req)) ?? []
        return results.map { toMovie($0) }
    }

    func isFavorite(id: Int) -> Bool {
        fetch(id: id) != nil
    }

    func add(_ movie: Movie) {
        guard fetch(id: movie.id) == nil else { return }
        let entry = FavoriteMovie(context: ctx)
        fill(entry, from: movie)
        entry.addedAt = Date()
        CoreDataStack.shared.save()
    }

    func remove(id: Int) {
        guard let entry = fetch(id: id) else { return }
        ctx.delete(entry)
        CoreDataStack.shared.save()
    }

    func toggle(_ movie: Movie) {
        isFavorite(id: movie.id) ? remove(id: movie.id) : add(movie)
    }

    // MARK: - Private

    private func fetch(id: Int) -> FavoriteMovie? {
        let req = NSFetchRequest<FavoriteMovie>(entityName: "FavoriteMovie")
        req.predicate  = NSPredicate(format: "movieId == %lld", Int64(id))
        req.fetchLimit = 1
        return try? ctx.fetch(req).first
    }

    private func fill(_ entry: FavoriteMovie, from movie: Movie) {
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

    private func toMovie(_ entry: FavoriteMovie) -> Movie {
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
