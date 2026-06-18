protocol ContainerProtocol {
    var settingsRepository: SettingsRepositoryProtocol { get }
    var settingsUseCase: SettingsUseCaseProtocol { get }
    var themeManager: ThemeManagerProtocol { get }
    var languageManager: LanguageManagerProtocol { get }
    var coreDataStack: CoreDataStack { get }
    var filmix: FilmixProtocol { get }
    var imageRepository: ImageRepositoryProtocol { get }
    var favoritesManager: FavoritesManagerProtocol { get }
    var historyManager: WatchHistoryManagerProtocol { get }
    var progressManager: PlaybackProgressManagerProtocol { get }
    var getContentUseCase: GetContentUseCaseProtocol { get }
    var getMovieDetailUseCase: GetMovieDetailUseCaseProtocol { get }
    var searchUseCase: SearchUseCaseProtocol { get }
    
    var favoritesUseCase: FavoritesUseCaseProtocol { get }
    var watchHistoryUseCase: WatchHistoryUseCaseProtocol { get }
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
    lazy var coreDataStack: CoreDataStack = CoreDataStack()
    
    lazy var filmix: FilmixProtocol = Filmix()
    lazy var imageRepository: ImageRepositoryProtocol = PosterCache.shared
    
    lazy var favoritesManager: FavoritesManagerProtocol = FavoritesManager()
    lazy var historyManager: WatchHistoryManagerProtocol = WatchHistoryManager()
    lazy var progressManager: PlaybackProgressManagerProtocol = PlaybackProgressManager()
    
    var getContentUseCase: GetContentUseCaseProtocol {
        GetContentUseCase(filmix: filmix)
    }
    
    lazy var getMovieDetailUseCase: GetMovieDetailUseCaseProtocol = GetMovieDetailUseCase(filmix: filmix)
    
    lazy var searchUseCase: SearchUseCaseProtocol = SearchUseCase(filmix: filmix)
    
    lazy var favoritesRepository: FavoritesRepository = CoreDataFavoritesRepository(stack: coreDataStack)
    lazy var watchHistoryRepository: WatchHistoryRepository = CoreDataWatchHistoryRepository(stack: coreDataStack)
    
    lazy var favoritesUseCase: FavoritesUseCaseProtocol = FavoritesUseCase(repository: favoritesRepository)
    lazy var watchHistoryUseCase: WatchHistoryUseCaseProtocol = WatchHistoryUseCase(repository: watchHistoryRepository)
    
    lazy var playbackStateRepository: PlaybackStateRepository = CoreDataPlaybackStateRepository(stack: coreDataStack)
    lazy var playerUseCase: PlayerUseCaseProtocol = PlayerUseCase(
        filmix: filmix,
        stateRepository: playbackStateRepository,
        settingsRepository: settingsRepository
    )
}
