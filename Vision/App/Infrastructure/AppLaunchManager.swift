import Foundation

class AppLaunchManager {
    private let firstLaunchKey = "com.example.init"
    
    var isFirstLaunch: Bool {
        let defaults = UserDefaults.standard
        
        if defaults.bool(forKey: firstLaunchKey) {
            return false
        } else {
            defaults.set(true, forKey: firstLaunchKey)
            defaults.synchronize()
            return true
        }
    }
}
