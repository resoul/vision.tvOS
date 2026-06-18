import Foundation
import Combine

protocol WatchHistoryManagerProtocol {
    func touch(_ item: ContentItem)
    func remove(id: Int)
}

final class WatchHistoryManager: WatchHistoryManagerProtocol {
    private let userDefaults = UserDefaults.standard
    private let key = "v_watch_history"
    private let maxItems = 100
    
    func touch(_ item: ContentItem) {
        var history = load()
        history.removeAll { $0 == item.id }
        history.insert(item.id, at: 0)
        
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
        }
        
        save(history)
    }
    
    func remove(id: Int) {
        var history = load()
        history.removeAll { $0 == id }
        save(history)
    }
    
    private func load() -> [Int] {
        userDefaults.array(forKey: key) as? [Int] ?? []
    }
    
    private func save(_ history: [Int]) {
        userDefaults.set(history, forKey: key)
    }
}
