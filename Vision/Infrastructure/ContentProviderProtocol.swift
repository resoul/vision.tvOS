import Foundation
import VisionProvider

/// Common interface for all content providers
protocol ContentProviderProtocol {
    var providerType: ProviderType { get }
    var availableCategories: [Category] { get }
    
    func fetchPage(url: URL?) async throws -> ContentPage
    func fetchDetail(item: ContentItem) async throws -> ContentDetail
    func fetchTranslations(item: ContentItem) async throws -> [Translation]
    func search(query: String) async throws -> ContentPage
}
