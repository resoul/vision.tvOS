import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        _ = CoreDataStack.shared
        CacheSettings.shared.apply()
        
        if UserDefaults.standard.string(forKey: "AppLanguageCode") == nil {
            UserDefaults.standard.set("en", forKey: "AppLanguageCode")
            UserDefaults.standard.synchronize()
        }
        
        let code = UserDefaults.standard.string(forKey: "AppLanguageCode")!
        UserDefaults.standard.set([code], forKey: "AppleLanguages")

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootController()
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}
