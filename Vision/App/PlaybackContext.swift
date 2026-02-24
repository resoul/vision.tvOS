import Foundation

// MARK: - PlaybackContext

enum PlaybackContext {

    case movie(
        movieId:   Int,
        studio:    String,
        quality:   String,
        streamURL: String
    )

    case episode(
        movieId:    Int,
        season:     Int,
        episode:    Int,
        studio:     String,
        quality:    String,
        streamURL:  String,
        title:      String,
        /// Индексы и folder следующего эпизода — nil если серия последняя в озвучке
        nextItem:   NextEpisodeItem?
    )
}

// MARK: - NextEpisodeItem

struct NextEpisodeItem {
    let seasonIndex:  Int   // 0-based
    let episodeIndex: Int   // 0-based
    let folder:       _FilmixPlayerFolder
    let studio:       String
    let quality:      String

    /// 1-based номера для отображения и сохранения прогресса
    var seasonNumber:  Int { seasonIndex + 1 }
    var episodeNumber: Int { episodeIndex + 1 }

    var title: String { "E\(episodeNumber) · \(folder.title)" }

    /// URL потока с учётом предпочитаемого качества
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

// MARK: - PlaybackContext helpers

extension PlaybackContext {

    var movieId: Int {
        switch self {
        case let .movie(id, _, _, _):       return id
        case let .episode(id, _, _, _, _, _, _, _): return id
        }
    }

    var displayTitle: String {
        switch self {
        case let .movie(_, studio, quality, _):
            return "\(studio) · \(quality)"
        case let .episode(_, _, _, studio, quality, _, title, _):
            return "\(title) · \(studio) · \(quality)"
        }
    }

    var streamURL: String {
        switch self {
        case let .movie(_, _, _, url):          return url
        case let .episode(_, _, _, _, _, url, _, _): return url
        }
    }

    var nextItem: NextEpisodeItem? {
        if case let .episode(_, _, _, _, _, _, _, next) = self { return next }
        return nil
    }

    /// Строит PlaybackContext для следующего эпизода
    func advancedContext() -> PlaybackContext? {
        guard case let .episode(movieId, _, _, _, _, _, _, nextItem) = self,
              let next = nextItem
        else { return nil }

        guard let stream = next.streamURL(preferredQuality: SeriesPickerStore.shared.globalPreferredQuality)
        else { return nil }

        return .episode(
            movieId:   movieId,
            season:    next.seasonNumber,
            episode:   next.episodeNumber,
            studio:    next.studio,
            quality:   stream.quality,
            streamURL: stream.url,
            title:     next.title,
            nextItem:  nil   // заполнится позже через SerieDetailViewController
        )
    }
}
