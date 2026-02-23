import UIKit

// MARK: - CodableMovie (lightweight Codable wrapper for Movie)

struct CodableMovie: Codable {
    let id: Int
    let title: String
    let year: String
    let description: String
    let imageName: String
    let genre: String
    let rating: String
    let duration: String
    let isSeries: Bool
    let translate: String
    let isAdIn: Bool
    let movieURL: String
    let posterURL: String
    let actors: [String]
    let directors: [String]
    let genreList: [String]
    let lastAdded: String?

    init(movie: Movie) {
        id          = movie.id
        title       = movie.title
        year        = movie.year
        description = movie.description
        imageName   = movie.imageName
        genre       = movie.genre
        rating      = movie.rating
        duration    = movie.duration
        isSeries    = movie.type.isSeries
        translate   = movie.translate
        isAdIn      = movie.isAdIn
        movieURL    = movie.movieURL
        posterURL   = movie.posterURL
        actors      = movie.actors
        directors   = movie.directors
        genreList   = movie.genreList
        lastAdded   = movie.lastAdded
    }

    func toMovie() -> Movie {
        Movie(
            id: id, title: title, year: year,
            description: description, imageName: imageName,
            genre: genre, rating: rating, duration: duration,
            type: isSeries ? .series(seasons: []) : .movie,
            translate: translate, isAdIn: isAdIn,
            movieURL: movieURL, posterURL: posterURL,
            actors: actors, directors: directors,
            genreList: genreList, lastAdded: lastAdded
        )
    }
}

// MARK: - FavoritesStore

final class FavoritesStore {

    static let shared = FavoritesStore()
    private init() {}

    private let key = "favorites_v1"
    private let defaults = UserDefaults.standard

    // In-memory cache to avoid repeated decodes
    private var cache: [CodableMovie]? = nil

    // MARK: - Public API

    func all() -> [Movie] {
        load().reversed().map { $0.toMovie() }   // newest first
    }

    func isFavorite(id: Int) -> Bool {
        load().contains { $0.id == id }
    }

    func add(_ movie: Movie) {
        var list = load()
        guard !list.contains(where: { $0.id == movie.id }) else { return }
        list.append(CodableMovie(movie: movie))
        save(list)
    }

    func remove(id: Int) {
        var list = load()
        list.removeAll { $0.id == id }
        save(list)
    }

    func toggle(_ movie: Movie) {
        isFavorite(id: movie.id) ? remove(id: movie.id) : add(movie)
    }

    // MARK: - Private

    private func load() -> [CodableMovie] {
        if let cached = cache { return cached }
        guard
            let data  = defaults.data(forKey: key),
            let list  = try? JSONDecoder().decode([CodableMovie].self, from: data)
        else { return [] }
        cache = list
        return list
    }

    private func save(_ list: [CodableMovie]) {
        cache = list
        if let data = try? JSONEncoder().encode(list) {
            defaults.set(data, forKey: key)
        }
    }
}
