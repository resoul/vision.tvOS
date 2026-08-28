import Foundation
import VisionProvider
import Flux

@MainActor
final class AppViewModel {
    var onConfigureTabBar: ((TabBarConfiguration) -> Void)?
    var onUpdateTabBarHeight: ((Bool) -> Void)?

    private let coordinator: AppCoordinatorProtocol
    private let provider: ContentProviderProtocol
    private let providerManager: VisionProviderManagerProtocol
    private let bag = SubscriptionBag()
    private var categories: [Category] = []

    init(
        coordinator: AppCoordinatorProtocol,
        provider: ContentProviderProtocol,
        providerManager: VisionProviderManagerProtocol
    ) {
        self.coordinator = coordinator
        self.provider = provider
        self.providerManager = providerManager
        setupSubscriptions()
    }

    func onViewDidLoad() {
        reloadCategories()
        if let first = categories.first {
            let path = first.url.isEmpty ? nil : first.url
            coordinator.show(destination(for: first, path: path), animated: false)
        }
    }
    
    private func setupSubscriptions() {
        providerManager.activeProvider.flux
            .sinkOnMain { [weak self] _ in
                guard let self = self else { return }
                self.reloadCategories()
                if let first = self.categories.first {
                    let path = first.url.isEmpty ? nil : first.url
                    self.coordinator.show(self.destination(for: first, path: path), animated: true)
                }
            }
            .store(in: bag)
    }
    
    private func reloadCategories() {
        categories = provider.availableCategories
        onConfigureTabBar?(tabBarConfig(from: categories))
    }

    func didSelectItem(_ item: TabItem) {
        guard let category = category(forItemID: item.id) else { return }
        onUpdateTabBarHeight?(!category.genres.isEmpty)
        let path = category.url.isEmpty ? nil : category.url
        coordinator.show(destination(for: category, path: path), animated: true)
    }

    func didSelectGenre(_ genre: GenreItem, in item: TabItem) {
        guard let category = category(forItemID: item.id) else { return }
        coordinator.show(destination(for: category, path: genre.id), animated: true)
    }

    func didSelectSearch() {
        coordinator.showSearch()
    }

    func didSelectSettings() {
        coordinator.showSettings()
    }

    private func tabBarConfig(from categories: [Category]) -> TabBarConfiguration {
        let items = categories.map { category in
            TabItem(
                id: category.id,
                title: category.title,
                icon: category.icon,
                genres: category.genres.map { GenreItem(id: $0.url, title: $0.title) }
            )
        }
        
        return TabBarConfiguration(items: items)
    }

    private func destination(for category: Category, path: String?) -> TabDestination {
        switch category.kind {
        case .favorites:    return .favorites
        case .watchHistory: return .watchHistory
        case .home:         return .home
        case .movies:       return .movies(path: path)
        case .series:       return .series(path: path)
        case .cartoons:     return .cartoons(path: path)
        case .tvShows:      return .tvShows(path: path)
        }
    }

    private func category(forItemID id: String) -> Category? {
        categories.first { $0.id == id }
    }
}
