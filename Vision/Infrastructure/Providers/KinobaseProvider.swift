import Foundation
import VisionProvider

final class KinobaseProvider: ContentProviderProtocol {
    let providerType: ProviderType = .kinobase
    private let service: KinobaseService
    
    init(service: KinobaseService = KinobaseServiceImpl()) {
        self.service = service
    }
    
    var availableCategories: [Category] {
        [
            Category(
                id: "home",
                title: L10n.Tab.home,
                url: "https://kinobase.org/",
                icon: "house.fill",
                kind: .home
            ),
            Category(
                id: "movies",
                title: L10n.Tab.movies,
                url: "https://kinobase.org/films",
                icon: "film.fill",
                kind: .movies
            ),
            Category(
                id: "series",
                title: L10n.Tab.series,
                url: "https://kinobase.org/serials",
                icon: "tv.fill",
                kind: .series
            ),
            Category(
                id: "tv",
                title: L10n.Tab.tvShows,
                url: "https://kinobase.org/tv",
                icon: "play.tv.fill",
                kind: .tvShows
            ),
            Category(
                id: "cartoons",
                title: L10n.Tab.cartoons,
                url: "https://kinobase.org/animation",
                icon: "sparkles.tv.fill",
                kind: .cartoons
            ),
            Category(
                id: "favorites",
                title: L10n.Tab.favorites,
                url: "favorites://",
                icon: "star.fill",
                kind: .favorites
            ),
            Category(
                id: "history",
                title: L10n.Tab.watchHistory,
                url: "history://",
                icon: "play.circle.fill",
                kind: .watchHistory
            )
        ]
    }
    
    func fetchPage(url: URL?) async throws -> ContentPage {
        let dto = try await service.fetchCatalog(pageURL: url)
        return ContentPage(
            items: dto.movies.map { toContentItemEntity(dto: $0) },
            nextPageURL: dto.nextPageURL
        )
    }
    
    func fetchDetail(item: ContentItem) async throws -> ContentDetail {
        let path = item.movieURL.isEmpty ? "\(item.id)" : item.movieURL
        let dto = try await service.fetchDetail(urlOrId: path)
        return toDetailEntity(dto: dto)
    }
    
    func fetchTranslations(item: ContentItem) async throws -> [Translation] {
        let path = item.movieURL.isEmpty ? "\(item.id)" : item.movieURL
        let detail = try await service.fetchDetail(urlOrId: path)
        
        guard !detail.identifier.isEmpty else {
            return []
        }
        
        let dtoList = try await service.fetchStreams(
            movieId: detail.id,
            identifier: detail.identifier,
            referer: detail.movieURL
        )
        
        return dtoList.map { toTranslationEntity(dto: $0) }
    }
    
    func search(query: String) async throws -> ContentPage {
        let results = try await service.search(query: query)
        let items: [ContentItem] = results.map { dto in
            ContentItem(
                id: dto.movieId ?? 0,
                title: dto.value,
                year: dto.year.map(String.init) ?? "—",
                description: "",
                genre: dto.type ?? "",
                rating: dto.rating.map { String(format: "%.1f", $0) } ?? "—",
                duration: "",
                type: (dto.type?.contains("serial") == true || dto.type?.contains("tv") == true) ? .series(seasons: []) : .movie,
                translate: "",
                isAdIn: false,
                movieURL: dto.fullMovieURL,
                posterURL: dto.fullImageURL,
                actors: [],
                directors: [],
                genreList: [],
                lastAdded: nil
            )
        }
        return ContentPage(items: items, nextPageURL: nil)
    }
    
    // MARK: - Mappers
    
    private func toContentItemEntity(dto: KinobaseMovieDTO) -> ContentItem {
        ContentItem(
            id: dto.id,
            title: dto.title,
            year: dto.year.isEmpty ? "—" : dto.year,
            description: "",
            genre: "",
            rating: dto.rating.isEmpty ? "—" : dto.rating,
            duration: "",
            type: dto.isSeries ? .series(seasons: []) : .movie,
            translate: "",
            isAdIn: false,
            movieURL: dto.movieURL,
            posterURL: dto.posterURL,
            actors: [],
            directors: [],
            genreList: [],
            lastAdded: nil
        )
    }
    
    private func toDetailEntity(dto: KinobaseMovieDetailDTO) -> ContentDetail {
        ContentDetail(
            id: dto.id,
            title: dto.title,
            originalTitle: dto.originalTitle,
            year: dto.year,
            description: dto.description,
            posterFullURL: dto.posterFull,
            backdropURL: dto.frames.first?.fullURL ?? dto.posterFull,
            countries: dto.countries,
            genres: dto.genres,
            directors: dto.directors,
            actors: dto.actors,
            writers: dto.writers,
            producers: dto.producers,
            slogan: "",
            mpaa: "",
            duration: dto.durationFormatted,
            quality: "",
            date: "",
            kinopoiskRating: dto.kinopoiskRating,
            kinopoiskVotes: dto.kinopoiskVotes,
            imdbRating: dto.imdbRating,
            imdbVotes: dto.imdbVotes,
            userRating: dto.imdbRating.isEmpty ? dto.kinopoiskRating : dto.imdbRating,
            userLikes: 0,
            userDislikes: 0,
            isSeries: dto.isSeries,
            isNotMovie: false,
            lastAdded: nil,
            statusOnAir: nil
        )
    }
    
    private func toTranslationEntity(dto: KinobaseTranslationDTO) -> Translation {
        let cleanStreams = dto.streams.compactMapValues { $0.first }
        let cleanSeasons = dto.seasons.map { season in
            Season(
                title: season.title,
                episodes: season.episodes.map { ep in
                    Episode(
                        title: ep.title,
                        id: ep.id,
                        streams: ep.streams.compactMapValues { $0.first }
                    )
                }
            )
        }
        return Translation(
            studio: dto.studio,
            streams: cleanStreams,
            seasons: cleanSeasons
        )
    }
}
