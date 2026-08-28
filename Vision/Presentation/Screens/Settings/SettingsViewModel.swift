import Combine
import Foundation
import VisionProvider
import Flux

final class SettingsViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(SettingsData)
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var currentTheme: Theme = .dark
    @Published private(set) var currentStyle: ThemeStyle = Theme.dark.style
    @Published private(set) var currentLanguage: AppLanguage = .russian
    @Published private(set) var currentProvider: ProviderType = .filmix
    @Published private(set) var storageData: SettingsStorageData = .empty
    @Published private(set) var storageError: String?

    // MARK: - Dependencies

    private let settingsUseCase: SettingsUseCaseProtocol
    private let themeManager: ThemeManagerProtocol
    private let languageManager: LanguageManagerProtocol
    private let providerManager: VisionProviderManagerProtocol
    private let bag = SubscriptionBag()
    private var cancellables = Set<AnyCancellable>()
    private var currentSettingsData = SettingsData(
        isAutoplayEnabled: true,
        preferredQuality: .auto,
        cacheSizeStep: 3
    )

    init(
        settingsUseCase: SettingsUseCaseProtocol,
        themeManager: ThemeManagerProtocol,
        languageManager: LanguageManagerProtocol,
        providerManager: VisionProviderManagerProtocol
    ) {
        self.settingsUseCase = settingsUseCase
        self.themeManager = themeManager
        self.languageManager = languageManager
        self.providerManager = providerManager
        bindUseCase()
        bindManagers()
    }

    // MARK: - Actions (UDF)

    func viewDidLoad() {
        state = .loading
        settingsUseCase.fetchSettings()
        Task { [weak self] in
            await self?.settingsUseCase.refreshStorage()
        }
    }

    func didSelectProvider(_ provider: ProviderType) {
        Task { [weak self] in
            await self?.providerManager.setProvider(provider)
        }
    }

    func didToggleAutoplay(_ isOn: Bool) {
        settingsUseCase.updateAutoplay(isOn)
    }
    
    func toggleAutoplay() {
        didToggleAutoplay(!currentSettingsData.isAutoplayEnabled)
    }

    func didSelectQuality(_ quality: VideoQuality) {
        settingsUseCase.updatePreferredQuality(quality)
    }

    func didUpdateCacheStep(_ step: Int) {
        settingsUseCase.updateCacheSizeStep(step)
    }

    func didSelectTheme(_ theme: Theme) {
        themeManager.apply(theme)
    }

    func didSelectLanguage(_ language: AppLanguage) {
        languageManager.select(language)
    }
    
    func getCacheSteps() -> [String] {
        settingsUseCase.getCacheSteps()
    }
    
    func getVersionString() -> String {
        settingsUseCase.getAppVersion()
    }
    
    func refreshStorage() {
        Task { [weak self] in
            await self?.settingsUseCase.refreshStorage()
        }
    }
    
    func clearPosterCache() {
        storageError = nil
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.settingsUseCase.clearPosterCache()
            } catch {
                self.storageError = error.localizedDescription
            }
        }
    }
    
    func clearWatchHistory() {
        storageError = nil
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.settingsUseCase.clearWatchHistory()
            } catch {
                self.storageError = error.localizedDescription
            }
        }
    }

    // MARK: - Private

    private func bindUseCase() {
        settingsUseCase.settings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.currentSettingsData = data
                self?.state = .loaded(data)
            }
            .store(in: &cancellables)
        
        settingsUseCase.storage
            .receive(on: DispatchQueue.main)
            .assign(to: &$storageData)
    }

    private func bindManagers() {
        themeManager.currentTheme
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTheme)

        themeManager.currentStyle
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentStyle)

        languageManager.currentLanguage
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentLanguage)

        providerManager.activeProvider.flux
            .sinkOnMain { [weak self] provider in
                self?.currentProvider = provider
            }
            .store(in: bag)
    }
}
