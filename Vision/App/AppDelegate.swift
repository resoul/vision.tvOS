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
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootController()
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}
