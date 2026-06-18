import Foundation
import Combine

@MainActor
final class WatchHistoryViewModel: ContentListViewModelProtocol {
    private let watchHistoryUseCase: WatchHistoryUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    var onLoadingChanged: ((Bool) -> Void)?
    var onMoviesChanged: (([ContentItem]) -> Void)?
    var onMoviesAppended: (([ContentItem]) -> Void)?
    var onError: ((String) -> Void)?
    var onPlayRequested: (([ContentItem], Int) -> Void)?
    var onDetailRequested: ((ContentItem) -> Void)?

    private var movies: [ContentItem] = []
    private var didLoadInitial = false

    init(watchHistoryUseCase: WatchHistoryUseCaseProtocol) {
        self.watchHistoryUseCase = watchHistoryUseCase
    }

    func onViewDidLoad() {
        bindPublisher()
        loadData()
    }

    func loadNextPageIfNeeded(currentIndex: Int) {}

    func didSelectItem(at index: Int) {
        guard index < movies.count else { return }
        onDetailRequested?(movies[index])
    }
    
    private func bindPublisher() {
        watchHistoryUseCase.historyPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.movies = items
                self.onMoviesChanged?(items)
            }
            .store(in: &cancellables)
    }

    private func loadData() {
        onLoadingChanged?(true)
        Task {
            do {
                let items = try await watchHistoryUseCase.getHistory()
                self.movies = items
                self.onLoadingChanged?(false)
                self.onMoviesChanged?(items)
            } catch {
                self.onLoadingChanged?(false)
                self.onError?(error.localizedDescription)
            }
        }
    }
}
