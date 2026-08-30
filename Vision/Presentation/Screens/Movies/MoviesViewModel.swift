import Foundation

@MainActor
final class MoviesViewModel: ContentListViewModelProtocol {
    private let getContentUseCase: GetContentUseCaseProtocol
    var onLoadingChanged: ((Bool) -> Void)?
    var onMoviesChanged: (([ContentItem]) -> Void)?
    var onMoviesAppended: (([ContentItem]) -> Void)?
    var onError: ((String) -> Void)?
    var onPlayRequested: (([ContentItem], Int) -> Void)?
    var onDetailRequested: ((ContentItem) -> Void)?

    private let basePath: String
    private var movies: [ContentItem] = []
    private var isLoading = false

    init(basePath: String, getContentUseCase: GetContentUseCaseProtocol) {
        self.basePath = basePath
        self.getContentUseCase = getContentUseCase
    }

    func onViewDidLoad() {
        guard movies.isEmpty else { return }
        loadInitial()
    }

    func loadNextPageIfNeeded(currentIndex: Int) {
        guard !isLoading else { return }
        let threshold = max(0, movies.count - 10)
        guard currentIndex >= threshold else { return }
        loadNext()
    }

    func didSelectItem(at index: Int) {
        guard index < movies.count else { return }
        onDetailRequested?(movies[index])
    }
    
    private func loadInitial() {
        isLoading = true
        onLoadingChanged?(true)

        Task {
            do {
                let newMovies = try await getContentUseCase.fetchInitial(path: basePath)
                var seenIDs = Set<Int>()
                let uniqueMovies = newMovies.filter { seenIDs.insert($0.id).inserted }
                movies = uniqueMovies
                isLoading = false
                onLoadingChanged?(false)
                onMoviesChanged?(uniqueMovies)
            } catch {
                isLoading = false
                onLoadingChanged?(false)
                onError?(error.localizedDescription)
            }
        }
    }

    private func loadNext() {
        isLoading = true

        Task {
            do {
                let newMovies = try await getContentUseCase.fetchNextPage()
                guard !newMovies.isEmpty else {
                    isLoading = false
                    return
                }

                var existingIDs = Set(movies.map(\.id))
                let uniqueNewMovies = newMovies.filter { existingIDs.insert($0.id).inserted }

                guard !uniqueNewMovies.isEmpty else {
                    isLoading = false
                    return
                }

                movies.append(contentsOf: uniqueNewMovies)
                isLoading = false
                onMoviesAppended?(uniqueNewMovies)
            } catch {
                isLoading = false
                onError?(error.localizedDescription)
            }
        }
    }
}
