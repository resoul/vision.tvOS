import Foundation

struct FilmixDetail {
    let id: Int
    let movieURL: String
    let posterThumb: String
    let posterFull: String
    let title: String
    let originalTitle: String
    let quality: String
    let date: String
    let dateISO: String
    let year: String
    let durationMinutes: Int?
    let mpaa: String
    let slogan: String
    let statusOnAir: String?
    let statusHint: String?
    let lastAdded: String?
    let directors: [String]
    let actors: [String]
    let writers: [String]
    let producers: [String]
    let genres: [String]
    let countries: [String]
    let translate: String
    let description: String
    let isAdIn: Bool
    let kinopoiskRating: String
    let kinopoiskVotes: String
    let imdbRating: String
    let imdbVotes: String
    let userPositivePercent: Int
    let userLikes: Int
    let userDislikes: Int
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
