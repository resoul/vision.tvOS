import UIKit

protocol FactoryProtocol {
    func makeApp() -> AppCoordinator
    func makeAppController(coordinator: AppCoordinatorProtocol) -> AppController
    func makeContentModule(for destination: TabDestination, coordinator: AppCoordinatorProtocol) -> UIViewController
    func makeSettingsModule() -> UIViewController
    func makeDetailModule(item: ContentItem, coordinator: AppCoordinatorProtocol) -> UIViewController
    func makeSearchModule(coordinator: AppCoordinatorProtocol) -> UIViewController
    func makeVideoPlayerModule(queue: [ContentItem], startIndex: Int, initialContext: PlaybackContext?) -> UIViewController
    func makeVideoModule() -> UIViewController
}

final class ModuleFactory: FactoryProtocol {
    let window: UIWindow
    private let container: ContainerProtocol

    init(container: ContainerProtocol, windowScene: UIWindowScene) {
        self.container = container
        window = UIWindow(windowScene: windowScene)
    }
    
    func makeApp() -> AppCoordinator {
        FontManager.registerFonts(fontFamily: Fonts.Amazon.self)
        FontManager.registerFonts(fontFamily: Fonts.Montserrat.self)
        FontManager.registerFonts(fontFamily: Fonts.Poppins.self)
        FontManager.registerFonts(fontFamily: Fonts.Roboto.self)
        FontManager.registerFonts(fontFamily: Fonts.Lato.self)

        (container.themeManager as? ThemeManager)?.apply(
            (container.themeManager as? ThemeManager)?.theme ?? .dark
        )
        
        return AppCoordinator(window: window, factory: self, languageManager: container.languageManager)
    }
    
    func makeAppController(coordinator: AppCoordinatorProtocol) -> AppController {
        AppController(viewModel: AppViewModel(coordinator: coordinator), themeManager: container.themeManager, languageManager: container.languageManager)
    }
    
    func makeContentModule(for destination: TabDestination, coordinator: AppCoordinatorProtocol) -> UIViewController {
        let basePath = "https://filmix.my/"
        let makeMovies: (String) -> UIViewController = { [weak coordinator] path in
            let viewModel = MoviesViewModel(basePath: path, getContentUseCase: self.container.getContentUseCase)
            viewModel.onPlayRequested = { movies, index in
                coordinator?.showPlayer(queue: movies, startIndex: index, initialContext: nil)
            }
            viewModel.onDetailRequested = { [weak coordinator] item in
                coordinator?.showDetail(for: item)
            }
            
            return MoviesController(viewModel: viewModel, themeManager: self.container.themeManager, languageManager: self.container.languageManager)
        }

        switch destination {
        case .home:
            return makeMovies(basePath)
        case .movies(path: let url):
            return makeMovies(url ?? basePath)
        case .series(path: let url):
            return makeMovies(url ?? basePath)
        case .cartoons(path: let url):
            return makeMovies(url ?? basePath)
        case .favorites:
            let viewModel = FavoritesViewModel(favoritesUseCase: container.favoritesUseCase)
            viewModel.onDetailRequested = { [weak coordinator] item in
                coordinator?.showDetail(for: item)
            }
            
            return MoviesController(viewModel: viewModel, themeManager: self.container.themeManager, languageManager: self.container.languageManager)
        case .watchHistory:
            let viewModel = WatchHistoryViewModel(watchHistoryUseCase: container.watchHistoryUseCase)
            viewModel.onDetailRequested = { [weak coordinator] item in
                coordinator?.showDetail(for: item)
            }
            
            return MoviesController(viewModel: viewModel, themeManager: self.container.themeManager, languageManager: self.container.languageManager)
        }
    }
    
    func makeSettingsModule() -> UIViewController {
        let viewModel = SettingsViewModel(
            settingsUseCase: container.settingsUseCase,
            themeManager: container.themeManager,
            languageManager: container.languageManager
        )
        return SettingsViewController(
            viewModel: viewModel,
            themeManager: container.themeManager,
            languageManager: container.languageManager
        )
    }


    func makeDetailModule(item: ContentItem, coordinator: AppCoordinatorProtocol) -> UIViewController {
        print("makeDetailModule", item)
        if item.type.isSeries {
            let vm = SerieDetailViewModel(
                movie: item,
                useCase: container.getMovieDetailUseCase,
                favoritesUseCase: container.favoritesUseCase,
                progressManager: container.progressManager,
                playerUseCase: container.playerUseCase
            )
            vm.onPlayRequested = { [weak coordinator] context in
                coordinator?.showPlayer(queue: [item], startIndex: 0, initialContext: context)
            }
            
            return SerieDetailViewController(viewModel: vm, themeManager: container.themeManager, languageManager: container.languageManager)
        } else {
            let vm = MovieDetailViewModel(
                movie: item,
                useCase: container.getMovieDetailUseCase,
                favoritesUseCase: container.favoritesUseCase,
                progressManager: container.progressManager,
                playerUseCase: container.playerUseCase
            )
            vm.onPlayRequested = { [weak coordinator] _, url in
                coordinator?.showPlayer(queue: [item], startIndex: 0, initialContext: nil)
            }
            
            return MovieDetailViewController(movie: item, viewModel: vm, themeManager: container.themeManager, languageManager: container.languageManager)
        }
    }
    
    func makeSearchModule(coordinator: AppCoordinatorProtocol) -> UIViewController {
        let viewModel = SearchViewModel(searchUseCase: container.searchUseCase)
        viewModel.onDetailRequested = { [weak coordinator] item in
            coordinator?.showDetail(for: item)
        }
        
        return SearchViewController(viewModel: viewModel, themeManager: container.themeManager, languageManager: container.languageManager)
    }

    func makeVideoPlayerModule(queue: [ContentItem], startIndex: Int, initialContext: PlaybackContext? = nil) -> UIViewController {
        print("makeVideoPlayerModule", queue)
        
        let viewModel = PlayerViewModel(
            queue: queue,
            startIndex: startIndex,
            initialContext: initialContext,
            playerUseCase: container.playerUseCase,
            watchHistoryUseCase: container.watchHistoryUseCase,
            progressManager: container.progressManager,
            settingsUseCase: container.settingsUseCase
        )
        
        return VideoPlayerViewController(viewModel: viewModel, themeManager: container.themeManager, languageManager: container.languageManager)
    }
    
    func makeVideoModule() -> UIViewController {
        let viewModel = VideoViewModel()
        return VideoController(viewModel: viewModel, themeManager: container.themeManager, languageManager: container.languageManager)
    }
}
