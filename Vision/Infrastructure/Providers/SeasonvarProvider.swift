import Foundation
import VisionProvider

final class SeasonvarProvider: ContentProviderProtocol {
    let providerType: ProviderType = .seasonvar
    private let service: SeasonvarService
    
    init(service: SeasonvarService = SeasonvarServiceImpl()) {
        self.service = service
    }
    
    var availableCategories: [Category] {
        [
            Category(
                id: "home",
                title: L10n.Tab.home,
                url: "https://seasonvar.ru/",
                icon: "house.fill",
                kind: .home
            ),
            Category(
                id: "series",
                title: L10n.Tab.series,
                url: "https://seasonvar.ru/",
                icon: "tv.fill",
                kind: .series
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
        // Seasonvar provides search & autocomplete feed
        let query = url?.query ?? "2026"
        return try await search(query: query)
    }
    
    func fetchDetail(item: ContentItem) async throws -> ContentDetail {
        let dto = try await service.fetchDetail(urlOrPath: item.movieURL)
        return toDetailEntity(dto: dto)
    }
    
    func fetchTranslations(item: ContentItem) async throws -> [Translation] {
        let translations = try await service.fetchAllTranslationsWithEpisodes(urlOrPath: item.movieURL)
        return translations.map { trans in
            let episodes = trans.episodes.map { ep in
                Episode(
                    title: ep.title,
                    id: ep.id,
                    streams: ["HD": ep.videoURL]
                )
            }
            let season = Season(title: "Сезон 1", episodes: episodes)
            return Translation(
                studio: trans.studio,
                streams: [:],
                seasons: [season]
            )
        }
    }
    
    func search(query: String) async throws -> ContentPage {
        let results = try await service.search(query: query)
        let items: [ContentItem] = results.map { dto in
            let fullURL = dto.path.hasPrefix("http") ? dto.path : "https://seasonvar.ru\(dto.path)"
            return ContentItem(
                id: dto.id,
                title: dto.title,
                year: "—",
                description: "",
                genre: "Сериал",
                rating: dto.rating ?? "—",
                duration: "",
                type: .series(seasons: []),
                translate: "",
                isAdIn: false,
                movieURL: fullURL,
                posterURL: "",
                actors: [],
                directors: [],
                genreList: [],
                lastAdded: nil
            )
        }
        return ContentPage(items: items, nextPageURL: nil)
    }
    
    // MARK: - Mappers
    
    private func toDetailEntity(dto: SeasonvarMovieDetailDTO) -> ContentDetail {
        ContentDetail(
            id: dto.id,
            title: dto.title,
            originalTitle: dto.originalTitle,
            year: dto.year.isEmpty ? "—" : dto.year,
            description: dto.description,
            posterFullURL: dto.posterURL,
            backdropURL: dto.posterURL,
            countries: dto.country.isEmpty ? [] : [dto.country],
            genres: dto.genres,
            directors: dto.directors,
            actors: dto.actors,
            writers: [],
            producers: [],
            slogan: "",
            mpaa: "",
            duration: "",
            quality: "HD",
            date: "",
            kinopoiskRating: dto.ratingKP,
            kinopoiskVotes: "",
            imdbRating: dto.ratingIMDb,
            imdbVotes: "",
            userRating: dto.ratingIMDb.isEmpty ? dto.ratingKP : dto.ratingIMDb,
            userLikes: 0,
            userDislikes: 0,
            isSeries: true,
            isNotMovie: false,
            lastAdded: nil,
            statusOnAir: nil
        )
    }
}
