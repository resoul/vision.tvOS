
struct NextEpisodeItem {
    let seasonIndex:  Int
    let episodeIndex: Int
    let folder:       _FilmixPlayerFolder
    let studio:       String
    let quality:      String

    var seasonNumber:  Int { seasonIndex + 1 }
    var episodeNumber: Int { episodeIndex + 1 }

    var title: String { "E\(episodeNumber) · \(folder.title)" }

    func streamURL(preferredQuality: String?) -> (url: String, quality: String)? {
        let streams = folder.streams
        let order   = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]

        if let preferred = preferredQuality, let url = streams[preferred] {
            return (url, preferred)
        }
        if let best = order.first(where: { streams[$0] != nil }), let url = streams[best] {
            return (url, best)
        }
        return nil
    }
}
