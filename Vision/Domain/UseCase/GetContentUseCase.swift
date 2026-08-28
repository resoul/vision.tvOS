import Foundation

protocol GetContentUseCaseProtocol {
    func fetchInitial(path: String) async throws -> [ContentItem]
    func fetchNextPage() async throws -> [ContentItem]
}

final class GetContentUseCase: GetContentUseCaseProtocol {
    private let provider: ContentProviderProtocol
    
    private var basePath: String = ""
    private var nextPageURL: URL?
    private var hasMore: Bool = true
    
    init(provider: ContentProviderProtocol) {
        self.provider = provider
    }
    
    func fetchInitial(path: String) async throws -> [ContentItem] {
        self.basePath = path
        self.hasMore = true
        self.nextPageURL = nil
        
        let url = path.isEmpty ? nil : URL(string: path)
        let page = try await provider.fetchPage(url: url)
        self.nextPageURL = page.nextPageURL
        self.hasMore = page.nextPageURL != nil || !page.items.isEmpty
        return page.items
    }
    
    func fetchNextPage() async throws -> [ContentItem] {
        guard hasMore, let nextURL = nextPageURL else { return [] }
        
        let page = try await provider.fetchPage(url: nextURL)
        if page.items.isEmpty {
            hasMore = false
        } else {
            self.nextPageURL = page.nextPageURL
            if page.nextPageURL == nil {
                hasMore = false
            }
        }
        
        return page.items
    }
}
