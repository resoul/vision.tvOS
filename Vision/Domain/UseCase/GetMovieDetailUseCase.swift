import Foundation

protocol GetMovieDetailUseCaseProtocol {
    func fetchDetail(movie: ContentItem, isSeries: Bool) async throws -> (ContentDetail, [Translation])
}

final class GetMovieDetailUseCase: GetMovieDetailUseCaseProtocol {
    private let filmix: FilmixProtocol
    
    init(filmix: FilmixProtocol) {
        self.filmix = filmix
    }
    
    func fetchDetail(movie: ContentItem, isSeries: Bool) async throws -> (ContentDetail, [Translation]) {
        let detail = try await filmix.fetchDetail(path: movie.movieURL)
        guard !detail.isNotMovie else {
            return (detail, [])
        }

        let translations = try await filmix.fetchTranslations(postId: movie.id, isSeries: isSeries)
        return (detail, translations)
    }
}
