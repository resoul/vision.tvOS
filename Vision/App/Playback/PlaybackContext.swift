import Foundation

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
        nextItem:   NextEpisodeItem?
    )
}

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
            nextItem:  nil
        )
    }
}
