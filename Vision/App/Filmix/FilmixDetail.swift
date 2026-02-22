import Foundation

struct FilmixDetail {

    // Identity
    let id: Int
    let movieURL: String          // /play/182347

    // Poster
    let posterThumb: String       // w220 thumbnail
    let posterFull: String        // original full-size

    // Titles
    let title: String
    let originalTitle: String     // alternate locale title (e.g. Ukrainian)

    // Classification
    let quality: String           // "WEB-DLRip 2160"
    let date: String              // "Вчера, 23:56"
    let dateISO: String           // "2026-02-21T23:56:17+02:00"
    let year: String              // "2026" or "2024 - 2026 (1 - 2 Сезон)"
    let durationMinutes: Int?     // 110 for movie, 51 for series episode
    let mpaa: String              // "18+" — movies only, empty for series
    let slogan: String            // movies only

    // Series-specific
    let statusOnAir: String?      // "В эфире" — nil for movies / finished series
    let statusHint: String?       // "Будет продолжение сериала" — from title attr
    let lastAdded: String?        // "2 серия (2 сезон) - ColdFilm"

    // People
    let directors: [String]
    let actors: [String]
    let writers: [String]
    let producers: [String]

    // Taxonomy
    let genres: [String]
    let countries: [String]
    let translate: String

    // Content
    let description: String
    let isAdIn: Bool

    // External ratings
    let kinopoiskRating: String   // "6.991"
    let kinopoiskVotes: String    // "12844"
    let imdbRating: String        // "7.6"
    let imdbVotes: String         // "46000"

    // User ratings
    let userPositivePercent: Int  // 63
    let userLikes: Int            // 357
    let userDislikes: Int         // 207

    // MARK: - Computed helpers

    var isSeries: Bool { statusOnAir != nil || lastAdded != nil || year.contains("Сезон") }

    var durationFormatted: String {
        guard let m = durationMinutes, m > 0 else { return quality }
        let h = m / 60, min = m % 60
        let base = h > 0 ? "\(h)ч \(min)м" : "\(min)м"
        return isSeries ? "\(base)/серия" : base
    }

    var userRating: String {
        let total = userLikes + userDislikes
        guard total > 0 else { return "—" }
        return String(format: "%.1f", Double(userLikes) / Double(total) * 10)
    }
}
