import Foundation
import Combine
import AVFoundation

@MainActor
final class VideoViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var currentContext: PlaybackContext?
    @Published var translations: [Translation] = []
    private var initialContext: PlaybackContext?
    
    private let queue: [ContentItem]
    private var currentIndex: Int
    private let playerUseCase: PlayerUseCaseProtocol
    private let watchHistoryUseCase: WatchHistoryUseCase
    private let progressManager: PlaybackProgressManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        queue: [ContentItem],
        currentIndex: Int,
        initialContext: PlaybackContext?,
        playerUseCase: PlayerUseCaseProtocol,
        watchHistoryUseCase: WatchHistoryUseCase,
        progressManager: PlaybackProgressManagerProtocol
    ) {
        self.queue = queue
        self.currentIndex = currentIndex
        self.playerUseCase = playerUseCase
        self.initialContext = initialContext
        self.watchHistoryUseCase = watchHistoryUseCase
        self.progressManager = progressManager
    }
    
    func viewDidLoad() {}
    
    func loadCurrent() async {
        guard queue.indices.contains(currentIndex) else { return }
        let item = queue[currentIndex]
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("fetch")
            let translations = try await playerUseCase.fetchTranslations(for: item)
            self.translations = translations
            
            let context: PlaybackContext
            if let initialContext, initialContext.movieId == item.id {
                context = initialContext
                self.initialContext = nil
            } else {
                context = try await playerUseCase.resolveInitialContext(for: item)
            }
            
            self.currentContext = context
            try? await watchHistoryUseCase.touch(item)
            checkResumeStatus(for: context)
            print("fetch")
        } catch {
            print(error)
        }
    }
    
    private func checkResumeStatus(for context: PlaybackContext) {
        let season: Int?
        let episode: Int?
        switch context {
        case .movie:
            season = nil; episode = nil
        case .episode(_, let s, let e, _, _, _, _):
            season = s; episode = e
        }
        
        if let progress = progressManager.getProgress(movieId: context.movieId, season: season, episode: episode),
           progress.positionSeconds > 10 {
            guard progress.fraction < 0.93 else { return }
            let isStaleProgress = Date().timeIntervalSince(progress.lastUpdated) > 7 * 24 * 3600
            if isStaleProgress {
//                pendingResumeTime = progress.positionSeconds
//                resumePromptTime = progress.positionSeconds
                print(progress.positionSeconds)
            } else {
//                pendingAutoResumeTime = progress.positionSeconds
                
                print(progress.positionSeconds)
            }
        }
    }
}
