import Foundation
import VisionProvider

final class FilmixProvider: ContentProviderProtocol {
    let providerType: ProviderType = .filmix
    private let service: FilmixService
    
    init(service: FilmixService = FilmixServiceImpl()) {
        self.service = service
    }
    
    var availableCategories: [Category] {
        [
            Category(
                id: "home",
                title: L10n.Tab.home,
                url: "https://filmix.my/",
                icon: "house.fill",
                kind: .home
            ),
            Category(
                id: "movies",
                title: L10n.Tab.movies,
                url: "https://filmix.my/film/",
                icon: "film.fill",
                kind: .movies,
                genres: Genre.movies
            ),
            Category(
                id: "series",
                title: L10n.Tab.series,
                url: "https://filmix.my/seria/",
                icon: "tv.fill",
                kind: .series,
                genres: Genre.series
            ),
            Category(
                id: "cartoons",
                title: L10n.Tab.cartoons,
                url: "https://filmix.my/mults/",
                icon: "sparkles.tv.fill",
                kind: .cartoons,
                genres: Genre.cartoons
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
        let dto = try await service.fetchPage(url: url)
        return ContentPage(
            items: dto.movies.map { toContentItemEntity(dto: $0) },
            nextPageURL: dto.nextPageURL
        )
    }
    
    func fetchDetail(item: ContentItem) async throws -> ContentDetail {
        let dto = try await service.fetchDetail(path: item.movieURL)
        return toDetailEntity(dto: dto)
    }
    
    func fetchTranslations(item: ContentItem) async throws -> [Translation] {
        let dto = try await service.fetchTranslations(postId: item.id, isSeries: item.type.isSeries)
        return dto.map { toTranslationEntity(dto: $0) }
    }
    
    func search(query: String) async throws -> ContentPage {
        let dto = try await service.search(query: query)
        return ContentPage(
            items: dto.movies.map { toContentItemEntity(dto: $0) },
            nextPageURL: dto.nextPageURL
        )
    }
    
    // MARK: - Mappers
    
    private func toContentItemEntity(dto: FilmixMovieDTO) -> ContentItem {
        ContentItem(
            id: dto.id,
            title: dto.title,
            year: dto.year,
            description: dto.description,
            genre: dto.genre,
            rating: dto.rating,
            duration: dto.duration,
            type: toContentTypeEntity(dto: dto.type),
            translate: dto.translate,
            isAdIn: dto.isAdIn,
            movieURL: dto.movieURL,
            posterURL: dto.posterURL,
            actors: dto.actors,
            directors: dto.directors,
            genreList: dto.genreList,
            lastAdded: dto.lastAdded
        )
    }
    
    private func toContentTypeEntity(dto: FilmixMovieDTO.ContentType) -> ContentItem.ContentType {
        switch dto {
        case .movie:
            return .movie
        case .series(let seasons):
            return .series(seasons: seasons.map { toSeasonEntity(dto: $0) })
        }
    }
    
    private func toSeasonEntity(dto: FilmixSeasonDTO) -> Season {
        Season(
            title: dto.title,
            episodes: dto.episodes.map { toEpisodeEntity(dto: $0) }
        )
    }
    
    private func toEpisodeEntity(dto: FilmixEpisodeDTO) -> Episode {
        Episode(
            title: dto.title,
            id: dto.id,
            streams: dto.streams
        )
    }
    
    private func toDetailEntity(dto: FilmixMovieDetailDTO) -> ContentDetail {
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
            slogan: dto.slogan,
            mpaa: dto.mpaa,
            duration: dto.durationFormatted,
            quality: dto.quality,
            date: dto.date,
            kinopoiskRating: dto.kinopoiskRating,
            kinopoiskVotes: dto.kinopoiskVotes,
            imdbRating: dto.imdbRating,
            imdbVotes: dto.imdbVotes,
            userRating: dto.userRating,
            userLikes: dto.userLikes,
            userDislikes: dto.userDislikes,
            isSeries: dto.isSeries,
            isNotMovie: dto.isNotMovie,
            lastAdded: dto.lastAdded,
            statusOnAir: dto.statusOnAir
        )
    }
    
    private func toTranslationEntity(dto: FilmixTranslationDTO) -> Translation {
        Translation(
            studio: dto.studio,
            streams: dto.streams,
            seasons: dto.seasons.map { toSeasonEntity(dto: $0) }
        )
    }
}
