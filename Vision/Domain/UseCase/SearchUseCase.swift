import Foundation

protocol SearchUseCaseProtocol {
    func search(query: String) async throws -> [ContentItem]
}

final class SearchUseCase: SearchUseCaseProtocol {
    private let filmix: FilmixProtocol
    
    init(filmix: FilmixProtocol) {
        self.filmix = filmix
    }
    
    func search(query: String) async throws -> [ContentItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let page = try await filmix.search(query: query)
        return page.items
    }
}
