import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        guard let windowScene = application.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else {
            assertionFailure("Expected a UIWindowScene during app launch")
            return false
        }

        let container = Container()
        let module = ModuleFactory(container: container, windowScene: windowScene)
        let coordinator = module.makeApp()
        
        window = module.window
        self.coordinator = coordinator
        self.coordinator?.start()

        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        guard let deepLink = TopShelfDeepLink(url: url) else { return false }
        let item = ContentItem(
            id: deepLink.id,
            title: deepLink.title,
            year: "",
            description: "",
            genre: "",
            rating: "",
            duration: "",
            type: deepLink.type == "movie" ? .movie : .series(seasons: []),
            translate: "",
            isAdIn: false,
            movieURL: deepLink.movieURL,
            posterURL: deepLink.posterURL,
            actors: [],
            directors: [],
            genreList: [],
            lastAdded: nil
        )
        
        coordinator?.showDetail(for: item)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive", application)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground", application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("applicationWillEnterForeground", application)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("applicationDidBecomeActive", application)
    }
}
