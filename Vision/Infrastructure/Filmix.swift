import Foundation
import Filmix

protocol FilmixProtocol {
    func search(query: String) async throws -> ContentPage
    func fetchTranslations(postId: Int, isSeries: Bool) async throws -> [Translation]
    func fetchDetail(path: String) async throws -> ContentDetail
    func fetchPage(url: URL?) async throws -> ContentPage
}

final class Filmix: FilmixProtocol {
    private let service: FilmixService = FilmixServiceImpl()
    
    func fetchPage(url: URL?) async throws -> ContentPage {
        let dto = try await service.fetchPage(url: url)
        return ContentPage(items: dto.movies.map { toContentItemEntity(dto: $0) }, nextPageURL: dto.nextPageURL)
    }
    
    func fetchDetail(path: String) async throws -> ContentDetail {
        let dto = try await service.fetchDetail(path: path)
        return toDetailEntity(dto: dto)
    }
    
    func fetchTranslations(postId: Int, isSeries: Bool) async throws -> [Translation] {
        let dto = try await service.fetchTranslations(postId: postId, isSeries: isSeries)
        return dto.map { toTranslationEntity(dto: $0) }
    }
    
    func search(query: String) async throws -> ContentPage {
        let dto = try await service.search(query: query)
        return ContentPage(items: dto.movies.map { toContentItemEntity(dto: $0) }, nextPageURL: dto.nextPageURL)
    }
    
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
