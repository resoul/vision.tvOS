import Foundation

protocol SearchUseCaseProtocol {
    func search(query: String) async throws -> [ContentItem]
}

final class SearchUseCase: SearchUseCaseProtocol {
    private let provider: ContentProviderProtocol
    
    init(provider: ContentProviderProtocol) {
        self.provider = provider
    }
    
    func search(query: String) async throws -> [ContentItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespaces)
        guard !cleanQuery.isEmpty else { return [] }
        let page = try await provider.search(query: cleanQuery)
        return page.items
    }
}
