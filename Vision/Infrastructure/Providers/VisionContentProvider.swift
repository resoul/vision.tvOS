import Foundation
import VisionProvider
import Flux

final class VisionContentProvider: ContentProviderProtocol {
    private let manager: VisionProviderManagerProtocol
    private let providers: [ProviderType: ContentProviderProtocol]
    
    init(manager: VisionProviderManagerProtocol) {
        self.manager = manager
        self.providers = [
            .filmix: FilmixProvider(service: manager.filmix),
            .kinobase: KinobaseProvider(service: manager.kinobase),
            .seasonvar: SeasonvarProvider(service: manager.seasonvar)
        ]
    }
    
    var activeProvider: ContentProviderProtocol {
        let currentType = manager.activeProvider.value
        return providers[currentType] ?? providers[.filmix]!
    }
    
    var providerType: ProviderType {
        activeProvider.providerType
    }
    
    var availableCategories: [Category] {
        activeProvider.availableCategories
    }
    
    /// Resolves the specific provider for a content item based on its URL,
    /// falling back to the active provider.
    func provider(for item: ContentItem) -> ContentProviderProtocol {
        if item.movieURL.contains("kinobase.org") {
            return providers[.kinobase] ?? activeProvider
        } else if item.movieURL.contains("seasonvar.ru") {
            return providers[.seasonvar] ?? activeProvider
        } else if item.movieURL.contains("filmix") {
            return providers[.filmix] ?? activeProvider
        }
        return activeProvider
    }
    
    func fetchPage(url: URL?) async throws -> ContentPage {
        try await activeProvider.fetchPage(url: url)
    }
    
    func fetchDetail(item: ContentItem) async throws -> ContentDetail {
        try await provider(for: item).fetchDetail(item: item)
    }
    
    func fetchTranslations(item: ContentItem) async throws -> [Translation] {
        try await provider(for: item).fetchTranslations(item: item)
    }
    
    func search(query: String) async throws -> ContentPage {
        try await activeProvider.search(query: query)
    }
}
