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
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
}
