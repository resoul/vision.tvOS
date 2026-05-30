import Foundation

struct FilmixTranslationDTO {
    let studio: String
    let streams: [String: String]
    let seasons: [FilmixSeasonDTO]
    
    nonisolated init(studio: String, streams: [String: String], seasons: [FilmixSeasonDTO]) {
        self.studio = studio
        self.streams = streams
        self.seasons = seasons
    }
    
    var isSeries: Bool { !seasons.isEmpty }
    var sortedQualities: [String] {
        let order = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p"]
        let known   = order.filter { streams[$0] != nil }
        let unknown = streams.keys.filter { !order.contains($0) }.sorted()
        return known + unknown
    }

    public var bestQuality: String? { sortedQualities.first }
    public var bestURL: String?     { bestQuality.flatMap { streams[$0] } }
}
