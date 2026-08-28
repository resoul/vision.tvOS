import Foundation

protocol GetMovieDetailUseCaseProtocol {
    func fetchDetail(movie: ContentItem, isSeries: Bool) async throws -> (ContentDetail, [Translation])
}

final class GetMovieDetailUseCase: GetMovieDetailUseCaseProtocol {
    private let provider: ContentProviderProtocol
    
    init(provider: ContentProviderProtocol) {
        self.provider = provider
    }
    
    func fetchDetail(movie: ContentItem, isSeries: Bool) async throws -> (ContentDetail, [Translation]) {
        let detail = try await provider.fetchDetail(item: movie)
        guard !detail.isNotMovie else {
            return (detail, [])
        }

        let translations = try await provider.fetchTranslations(item: movie)
        return (detail, translations)
    }
}
