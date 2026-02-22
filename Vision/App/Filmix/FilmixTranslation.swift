import Foundation

struct FilmixTranslation {
    let studio: String
    let streams: [String: String]
    let seasons: [_FilmixPlayerSerial]

    var isSeries: Bool { !seasons.isEmpty }

    var sortedQualities: [String] {
        let order = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let known   = order.filter { streams[$0] != nil }
        let unknown = streams.keys.filter { !order.contains($0) }.sorted()
        return known + unknown
    }

    var bestQuality: String? { sortedQualities.first }
    var bestURL: String?     { bestQuality.flatMap { streams[$0] } }
}

struct _FilmixPlayerSerial: Codable {
    let title: String
    let folder: [_FilmixPlayerFolder]
}

struct _FilmixPlayerFolder: Codable {
    let title: String
    let id: String
    let file: String

    var streams: [String: String] {
        FilmixHelper.decodeString(list: file.split(separator: ",").map(String.init))
    }
}

// MARK: - Codable wrappers

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
