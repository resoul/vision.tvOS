import UIKit
import FontManager

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let launchManager = AppLaunchManager()
    let cacheManager = CacheManager.shared

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FontManager.registerFonts(fontFamily: Fonts.Montserrat.self)
        
        if launchManager.isFirstLaunch {
            cacheManager.createCacheDirectory()
        }
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootController()
//        window.rootViewController = UINavigationController(rootViewController: ViewController())
        
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}
