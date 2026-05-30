import Foundation
import Combine

@MainActor
final class MovieDetailViewModel {
    private let movie: ContentItem
    private let useCase: GetMovieDetailUseCaseProtocol
    private let favoritesUseCase: FavoritesUseCase
    private let progressManager: PlaybackProgressManagerProtocol
    private let playerUseCase: PlayerUseCaseProtocol

    @Published var detail: ContentDetail?
    @Published var translations: [Translation] = []
    @Published var resolvedStreams: [String: (quality: String, url: String)] = [:]
    @Published var isLoading = false
    @Published var isFavorite = false
    @Published var isWatched = false

    private var cancellables = Set<AnyCancellable>()
    var onPlayRequested: ((Translation, String) -> Void)?

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
            let (detailData, translationsData) = try await useCase.fetchDetail(movie: movie, isSeries: false)
            self.detail = detailData
            self.translations = translationsData
            await resolveAllStreams(translationsData)
        } catch {
            print("Error loading movie detail: \(error)")
        }
    }
    
    private func resolveAllStreams(_ list: [Translation]) async {
        var result: [String: (quality: String, url: String)] = [:]
        for translation in list {
            if let resolved = await playerUseCase.resolvePreferredStream(from: translation.streams) {
                result[translation.studio] = resolved
            }
        }
        self.resolvedStreams = result
    }

    func refreshProgress() {
        isWatched = progressManager.isWatched(movieId: movie.id, season: 0, episode: 0)
    }

    func toggleFavorite() {
        Task {
            try? await favoritesUseCase.toggle(movie)
        }
    }
    
    func play(translation: Translation) {
        let stream = resolvedStreams[translation.studio]
        let url = stream?.url ?? translation.bestURL ?? ""
        guard !url.isEmpty else { return }
        onPlayRequested?(translation, url)
    }
    
    func displayQuality(for translation: Translation) -> String {
        resolvedStreams[translation.studio]?.quality ?? translation.bestQuality ?? ""
    }
}
