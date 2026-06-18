import Foundation
import Combine

@MainActor
final class FavoritesViewModel: ContentListViewModelProtocol {
    private let favoritesUseCase: FavoritesUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var onLoadingChanged: ((Bool) -> Void)?
    var onMoviesChanged: (([ContentItem]) -> Void)?
    var onMoviesAppended: (([ContentItem]) -> Void)?
    var onError: ((String) -> Void)?
    var onPlayRequested: (([ContentItem], Int) -> Void)?
    var onDetailRequested: ((ContentItem) -> Void)?
    
    private var movies: [ContentItem] = []
    
    init(favoritesUseCase: FavoritesUseCaseProtocol) {
        self.favoritesUseCase = favoritesUseCase
    }
    
    func onViewDidLoad() {
        bindUseCase()
        loadData()
    }
    
    func loadNextPageIfNeeded(currentIndex: Int) {
        // No pagination for local favorites for now
    }
    
    func didSelectItem(at index: Int) {
        guard index < movies.count else { return }
        onDetailRequested?(movies[index])
    }
    
    private func bindUseCase() {
        favoritesUseCase.favoritesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.movies = items
                self?.onMoviesChanged?(items)
            }
            .store(in: &cancellables)
    }
    
    private func loadData() {
        onLoadingChanged?(true)
        Task {
            do {
                let items = try await favoritesUseCase.getAll()
                self.movies = items
                onLoadingChanged?(false)
                onMoviesChanged?(items)
            } catch {
                onLoadingChanged?(false)
                onError?(error.localizedDescription)
            }
        }
    }
}
