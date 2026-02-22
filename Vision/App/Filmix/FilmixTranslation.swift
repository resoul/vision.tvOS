import Foundation

// MARK: - Models
struct FilmixTranslation {
    let studio: String
    let streams: [String: String]

    var sortedQualities: [String] {
        let order = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let known   = order.filter { streams[$0] != nil }
        let unknown = streams.keys.filter { !order.contains($0) }.sorted()
        return known + unknown
    }

    var bestQuality: String? { sortedQualities.first }
    var bestURL: String?     { bestQuality.flatMap { streams[$0] } }
}

// MARK: - Codable wrappers (private to service)

struct _FilmixPlayerResponse: nonisolated Codable {
    let type: String
    let message: _FilmixPlayerMessage
}

struct _FilmixPlayerMessage: Codable {
    let translations: _FilmixTranslations
}

struct _FilmixTranslations: Codable {
    let video: [String: String]
}
