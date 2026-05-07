protocol ContainerProtocol {
    var settingsRepository: SettingsRepositoryProtocol { get }
    var settingsUseCase: SettingsUseCaseProtocol { get }
    var themeManager: ThemeManagerProtocol { get }
    var languageManager: LanguageManagerProtocol { get }
    var filmixClient: FilmixNetworkClient { get }
    var filmixRepository: FilmixMovieRepositoryProtocol { get }
    var imageRepository: ImageRepositoryProtocol { get }
    var favoritesManager: FavoritesManagerProtocol { get }
    var historyManager: WatchHistoryManagerProtocol { get }
    var progressManager: PlaybackProgressManagerProtocol { get }
    var getContentUseCase: GetContentUseCaseProtocol { get }
    var getMovieDetailUseCase: GetMovieDetailUseCaseProtocol { get }
    var searchUseCase: SearchUseCaseProtocol { get }
    
    var favoritesUseCase: FavoritesUseCase { get }
    var watchHistoryUseCase: WatchHistoryUseCase { get }
    var playerUseCase: PlayerUseCaseProtocol { get }
}

final class Container: ContainerProtocol {
    lazy var settingsRepository: SettingsRepositoryProtocol = SettingsService()
    lazy var settingsUseCase: SettingsUseCaseProtocol = SettingsUseCase(
        repository: settingsRepository,
        themeManager: themeManager,
        languageManager: languageManager,
        imageRepository: imageRepository,
        favoritesUseCase: favoritesUseCase,
        watchHistoryUseCase: watchHistoryUseCase
    )
    lazy var themeManager: ThemeManagerProtocol = ThemeManager()
    lazy var languageManager: LanguageManagerProtocol = LanguageManager()
    
    lazy var filmixClient: FilmixNetworkClient = FilmixNetworkClient()
    lazy var filmixRepository: FilmixMovieRepositoryProtocol = FilmixMovieRepository(client: filmixClient)
    lazy var imageRepository: ImageRepositoryProtocol = PosterCache.shared
    
    lazy var favoritesManager: FavoritesManagerProtocol = FavoritesManager.shared
    lazy var historyManager: WatchHistoryManagerProtocol = WatchHistoryManager.shared
    lazy var progressManager: PlaybackProgressManagerProtocol = PlaybackProgressManager.shared
    
    var getContentUseCase: GetContentUseCaseProtocol {
        GetContentUseCase(repository: filmixRepository)
    }
    
    lazy var getMovieDetailUseCase: GetMovieDetailUseCaseProtocol = GetMovieDetailUseCase(repository: filmixRepository)
    
    lazy var searchUseCase: SearchUseCaseProtocol = SearchUseCase(repository: filmixRepository)
    
    lazy var favoritesRepository: FavoritesRepository = CoreDataFavoritesRepository()
    lazy var watchHistoryRepository: WatchHistoryRepository = CoreDataWatchHistoryRepository()
    
    lazy var favoritesUseCase: FavoritesUseCase = FavoritesUseCase(repository: favoritesRepository)
    lazy var watchHistoryUseCase: WatchHistoryUseCase = WatchHistoryUseCase(repository: watchHistoryRepository)
    
    lazy var playbackStateRepository: PlaybackStateRepository = CoreDataPlaybackStateRepository()
    lazy var playerUseCase: PlayerUseCaseProtocol = PlayerUseCase(
        movieRepository: filmixRepository,
        stateRepository: playbackStateRepository,
        settingsRepository: settingsRepository
    )
}
