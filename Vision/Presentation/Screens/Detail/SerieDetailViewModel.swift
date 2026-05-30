import Foundation
import Combine

@MainActor
final class SerieDetailViewModel {
    private let movie: ContentItem
    private let useCase: GetMovieDetailUseCaseProtocol
    private let favoritesUseCase: FavoritesUseCase
    private let progressManager: PlaybackProgressManagerProtocol
    private let playerUseCase: PlayerUseCaseProtocol

    @Published var detail: ContentDetail?
    @Published var translations: [Translation] = []
    @Published var activeTranslation: Translation?
    @Published var activeSeasonIndex = 0
    @Published var isLoading = false
    @Published var isFavorite = false
    @Published var progressUpdated = UUID()
    @Published var resolvedTranslationQualities: [String: String] = [:]

    private var cancellables = Set<AnyCancellable>()
    var onPlayRequested: ((PlaybackContext) -> Void)?

    init(
        movie: ContentItem,
        useCase: GetMovieDetailUseCaseProtocol,
        favoritesUseCase: FavoritesUseCase,
        progressManager: PlaybackProgressManagerProtocol,
        playerUseCase: PlayerUseCaseProtocol
    ) {
        self.movie = movie
        self.useCase = useCase
        self.favoritesUseCase = favoritesUseCase
        self.progressManager = progressManager
        self.playerUseCase = playerUseCase
        setupBindings()
    }

    private func setupBindings() {
        favoritesUseCase.favoritesPublisher
            .map { [weak self] favorites in
                favorites.contains { $0.id == self?.movie.id }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$isFavorite)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let (detailData, translationsData) = try await useCase.fetchDetail(movie: movie, isSeries: true)
            let savedState = try? await playerUseCase.savedPlaybackState(movieId: movie.id)
            let selectedTranslation = Self.selectedTranslation(from: translationsData, savedState: savedState)
            let selectedSeasonIndex = Self.selectedSeasonIndex(for: selectedTranslation, savedState: savedState)

            self.detail = detailData
            self.translations = translationsData
            self.activeTranslation = selectedTranslation
            self.activeSeasonIndex = selectedSeasonIndex
            await resolveTranslationQualities(translationsData)
        } catch {
            print("Error loading series detail: \(error)")
        }
    }
    
    private func resolveTranslationQualities(_ list: [Translation]) async {
        var result: [String: String] = [:]
        for translation in list {
            let sampleStreams: [String: String]
            if let firstEpisode = translation.seasons.first?.episodes.first {
                sampleStreams = firstEpisode.streams
            } else {
                sampleStreams = translation.streams
            }

            if let resolved = await playerUseCase.resolvePreferredStream(from: sampleStreams) {
                result[translation.studio] = resolved.quality
            } else if let best = translation.bestQuality {
                result[translation.studio] = best
            }
        }
        
        self.resolvedTranslationQualities = result
    }
    
    func displayQuality(for translation: Translation) -> String {
        if let resolved = resolvedTranslationQualities[translation.studio] {
            return resolved
        }
        
        if let firstEpisode = translation.seasons.first?.episodes.first {
            return Translation(studio: translation.studio,
                               streams: firstEpisode.streams,
                               seasons: []).bestQuality ?? ""
        }
        return translation.bestQuality ?? ""
    }
    
    func toggleFavorite() {
        Task { try? await favoritesUseCase.toggle(movie) }
    }

    func selectSeason(index: Int) {
        activeSeasonIndex = index
    }

    func refreshProgress() {
        progressUpdated = UUID()
    }

    func selectTranslation(index: Int) {
        guard let translation = translations[safe: index] else { return }
        activeTranslation = translation
        activeSeasonIndex = 0
        saveSelectedTranslation(translation)
    }

    func play(episode: Episode) {
        guard let translation = activeTranslation,
              let season = translation.seasons[safe: activeSeasonIndex],
              let episodeIndex = season.episodes.firstIndex(where: { $0.id == episode.id }) else { return }

        Task {
            guard let stream = await playerUseCase.resolvePreferredStream(from: episode.streams) else { return }

            let context = PlaybackContext.episode(
                id: movie.id,
                season: activeSeasonIndex + 1,
                episode: episodeIndex + 1,
                studio: translation.studio,
                quality: stream.quality,
                url: stream.url,
                title: episode.title
            )
            onPlayRequested?(context)
        }
    }

    func getProgress(episodeIndex: Int) -> Double? {
        progressManager.getProgress(
            movieId: movie.id,
            season: activeSeasonIndex + 1,
            episode: episodeIndex + 1
        )?.fraction
    }

    func isWatched(episodeIndex: Int) -> Bool {
        progressManager.isWatched(
            movieId: movie.id,
            season: activeSeasonIndex + 1,
            episode: episodeIndex + 1
        )
    }

    private func saveSelectedTranslation(_ translation: Translation) {
        let quality = displayQuality(for: translation)
        Task {
            try? await playerUseCase.saveSelectedTranslation(
                movieId: movie.id,
                studio: translation.studio,
                quality: quality,
                season: 1,
                episode: 1
            )
        }
    }

    private static func selectedTranslation(from translations: [Translation], savedState: PlaybackState?) -> Translation? {
        guard let savedState,
              let savedTranslation = translations.first(where: { $0.studio == savedState.studio }) else {
            return translations.first
        }

        return savedTranslation
    }

    private static func selectedSeasonIndex(for translation: Translation?, savedState: PlaybackState?) -> Int {
        guard let translation,
              let savedState,
              savedState.season > 0 else {
            return 0
        }

        let index = savedState.season - 1
        return translation.seasons.indices.contains(index) ? index : 0
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
