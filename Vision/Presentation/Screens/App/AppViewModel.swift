@MainActor
final class AppViewModel {
    var onConfigureTabBar: ((TabBarConfiguration) -> Void)?
    var onUpdateTabBarHeight: ((Bool) -> Void)?

    private let coordinator: AppCoordinatorProtocol
    private var categories: [Category] = []

    init(coordinator: AppCoordinatorProtocol) {
        self.coordinator = coordinator
    }

    func onViewDidLoad() {
        categories = Category.all
        onConfigureTabBar?(tabBarConfig(from: categories))

        if let first = categories.first {
            coordinator.show(destination(for: first, path: first.url), animated: false)
        }
    }

    func didSelectItem(_ item: TabItem) {
        guard let category = category(forItemID: item.id) else { return }
        onUpdateTabBarHeight?(!category.genres.isEmpty)
        coordinator.show(destination(for: category, path: category.url), animated: true)
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
        case .regular:
            if category.url.contains("/film/")  { return .movies(path: path) }
            if category.url.contains("/seria/") { return .series(path: path) }
            if category.url.contains("/mults/") { return .cartoons(path: path) }
            return .home
        }
    }

    private func category(forItemID id: String) -> Category? {
        categories.first { $0.id == id }
    }
}
