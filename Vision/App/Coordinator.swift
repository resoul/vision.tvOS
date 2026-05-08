import UIKit
import Combine

protocol CoordinatorProtocol: AnyObject {
    func start()
}

protocol AppCoordinatorProtocol: AnyObject {
    func show(_ destination: TabDestination, animated: Bool)
    func showSearch()
    func showSettings()
    func showDetail(for item: ContentItem)
    func showPlayer(queue: [ContentItem], startIndex: Int, initialContext: PlaybackContext?)
}

final class AppCoordinator: CoordinatorProtocol {
    private let window: UIWindow
    private let factory: FactoryProtocol
    private let languageManager: LanguageManagerProtocol

    private weak var appController: AppController?
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow, factory: FactoryProtocol, languageManager: LanguageManagerProtocol) {
        self.window = window
        self.factory = factory
        self.languageManager = languageManager
    }

    func start() {
        bindLanguage()
        buildApp()
    }

    private func buildApp() {
        let controller = factory.makeAppController(coordinator: self)
        appController = controller
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }

    private func bindLanguage() {
        languageManager.currentLanguage
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.buildApp() }
            .store(in: &cancellables)
    }
}

extension AppCoordinator: AppCoordinatorProtocol {
    func show(_ destination: TabDestination, animated: Bool) {
        guard let controller = appController else { return }
        let content = factory.makeContentModule(for: destination, coordinator: self)
        controller.showContent(content, animated: animated)
    }

    func showSearch() {
        guard let controller = appController else { return }
        let searchVC = factory.makeSearchModule(coordinator: self)
        controller.presentModal(searchVC, onDismiss: nil)
    }


    func showSettings() {
        guard let controller = appController else { return }
        controller.presentModal(factory.makeSettingsModule(), onDismiss: nil)
    }

    func showDetail(for item: ContentItem) {
        guard let controller = appController else { return }
        let detailVC = factory.makeDetailModule(item: item, coordinator: self)
        controller.presentModal(detailVC, onDismiss: nil)
    }

    func showPlayer(queue: [ContentItem], startIndex: Int, initialContext: PlaybackContext? = nil) {
        guard let controller = appController else { return }
        let player = factory.makeVideoPlayerModule(queue: queue, startIndex: startIndex, initialContext: initialContext)
        controller.presentModal(player, onDismiss: nil)
    }
}
