import Foundation
import Combine
import AVFoundation

@MainActor
final class VideoViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var currentContext: PlaybackContext?
    @Published var translations: [Translation] = []
    @Published var shouldDismiss = false
    @Published var error: Error?
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var resumePromptTime: Double?
    
    private var initialContext: PlaybackContext?
    private var isAutoplayEnabled = true
    
    private let queue: [ContentItem]
    private var currentIndex: Int
    private let playerUseCase: PlayerUseCaseProtocol
    private let watchHistoryUseCase: WatchHistoryUseCase
    private let progressManager: PlaybackProgressManagerProtocol
    private let settingsUseCase: SettingsUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var lastAutosavedSecond: Double = -1
    private let initialHistoryThresholdSeconds: Double = 5
    private let periodicSaveStepSeconds: Double = 15
    private var pendingResumeTime: Double?
    private var pendingAutoResumeTime: Double?
    
    var isAwaitingResumeDecision: Bool {
        pendingResumeTime != nil
    }
    
    init(
        queue: [ContentItem],
        currentIndex: Int,
        initialContext: PlaybackContext?,
        playerUseCase: PlayerUseCaseProtocol,
        watchHistoryUseCase: WatchHistoryUseCase,
        progressManager: PlaybackProgressManagerProtocol,
        settingsUseCase: SettingsUseCaseProtocol
    ) {
        self.queue = queue
        self.currentIndex = currentIndex
        self.playerUseCase = playerUseCase
        self.initialContext = initialContext
        self.watchHistoryUseCase = watchHistoryUseCase
        self.progressManager = progressManager
        self.settingsUseCase = settingsUseCase
        
        setupSettingsBinding()
    }
    
    func viewDidLoad() {}
    
    func resume() {
        if pendingResumeTime != nil {
            pendingResumeTime = nil
            resumePromptTime = nil
        }
    }
    
    func restart() {
        pendingResumeTime = nil
        resumePromptTime = nil
    }
    
    func consumeAutoResumeTime() -> Double? {
        let value = pendingAutoResumeTime
        pendingAutoResumeTime = nil
        return value
    }
    
    func loadCurrent() async {
        guard queue.indices.contains(currentIndex) else { return }
        let item = queue[currentIndex]
        
        pendingResumeTime = nil
        pendingAutoResumeTime = nil
        resumePromptTime = nil
        
        isLoading = true
        defer { isLoading = false }
        do {
            let translations = try await playerUseCase.fetchTranslations(for: item)
            self.translations = translations
            
            let context: PlaybackContext
            if let initialContext, initialContext.movieId == item.id {
                context = initialContext
                self.initialContext = nil
            } else {
                context = try await playerUseCase.resolveInitialContext(for: item)
            }
            
            try? await watchHistoryUseCase.touch(item)
            checkResumeStatus(for: context)
            self.currentContext = context
        } catch {
            self.error = error
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
        
        if let progress = progressManager.getProgress(movieId: context.movieId, season: season, episode: episode), progress.positionSeconds > 10 {
            guard progress.fraction < 0.93 else { return }
            let isStaleProgress = Date().timeIntervalSince(progress.lastUpdated) > 7 * 24 * 3600
            if isStaleProgress {
                pendingResumeTime = progress.positionSeconds
                resumePromptTime = progress.positionSeconds
            } else {
                pendingAutoResumeTime = progress.positionSeconds
            }
        }
    }
    
    func updateProgress(currentTime: Double, duration: Double) {
        self.currentTime = currentTime
        self.duration = duration
        
        guard currentTime.isFinite, duration.isFinite, duration > 0 else { return }
        guard currentTime > 0 else { return }
        let shouldDoInitialSave = lastAutosavedSecond < 0 && currentTime >= initialHistoryThresholdSeconds
        let shouldDoPeriodicSave = abs(currentTime - lastAutosavedSecond) >= periodicSaveStepSeconds
        guard shouldDoInitialSave || shouldDoPeriodicSave else { return }
        guard let context = currentContext else { return }
        
        lastAutosavedSecond = currentTime
        
        let season: Int?
        let episode: Int?
        switch context {
        case .movie:
            season = nil
            episode = nil
        case .episode(_, let s, let e, _, _, _, _):
            season = s
            episode = e
        }
        
        progressManager.saveProgress(
            movieId: context.movieId,
            season: season,
            episode: episode,
            position: currentTime,
            duration: duration
        )
        
        if let item = queue[safe: currentIndex] {
            let fraction = duration > 0 ? currentTime / duration : 0
            let watched = fraction > 0.93
            let episodeId = episode.map { "\(season ?? 0)x\($0)" }
            Task {
                try? await watchHistoryUseCase.saveProgress(
                    item,
                    episodeId: episodeId,
                    position: currentTime,
                    watched: watched
                )
            }
        }
    }
    
    func saveState() async {
        guard let context = currentContext else { return }
        try? await playerUseCase.savePlaybackState(movieId: context.movieId, context: context)
        
        if let item = queue[safe: currentIndex] {
            let season: Int?
            let episode: Int?
            let epId: String?
            
            switch context {
            case .episode(_, let s, let e, _, _, _, _):
                season = s; episode = e; epId = "\(s)x\(e)"
            case .movie:
                season = nil; episode = nil; epId = nil
            }
            
            try? await watchHistoryUseCase.saveProgress(item, episodeId: epId, position: currentTime, watched: currentTime > duration * 0.93)
            progressManager.saveProgress(movieId: context.movieId, season: season, episode: episode, position: currentTime, duration: duration)
        }
    }

    // MARK: - Playback navigation

    func playNext() async {
        guard let target = resolveAdjacentEpisode(direction: .forward) else {
            guard currentIndex + 1 < queue.count else { shouldDismiss = true; return }
            currentIndex += 1
            await loadCurrent()
            return
        }

        switch target {
        case .episode(let season, let episode):
            if isAutoplayEnabled {
                await changeEpisode(season: season, episode: episode)
            } else {
                shouldDismiss = true
            }
        case .seriesEnded:
            shouldDismiss = true
        }
    }

    func playPrevious() async {
        guard let target = resolveAdjacentEpisode(direction: .backward) else {
            guard currentIndex - 1 >= 0 else { return }
            currentIndex -= 1
            await loadCurrent()
            return
        }

        switch target {
        case .episode(let season, let episode):
            await changeEpisode(season: season, episode: episode)
        case .seriesEnded:
            break // Already at S1E1, stay
        }
    }

    func changeEpisode(season: Int, episode: Int) async {
        guard let item = queue[safe: currentIndex],
              let context = currentContext else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let studio: String
            let quality: String
            switch context {
            case .movie(_, let s, let q, _, _):
                studio = s; quality = q
            case .episode(_, _, _, let s, let q, _, _):
                studio = s; quality = q
            }

            let newContext = try await playerUseCase.switchEpisode(in: item, season: season, episode: episode, currentStudio: studio, currentQuality: quality)
            self.currentContext = newContext
        } catch {
            self.error = error
        }
    }

    // MARK: - Private

    private enum EpisodeNavigationTarget {
        case episode(season: Int, episode: Int)
        case seriesEnded
    }

    private enum NavigationDirection {
        case forward, backward
    }

    /// Returns nil if current context is not an episode (caller handles queue fallback).
    /// Returns .seriesEnded if there's nowhere to go in the given direction.
    private func resolveAdjacentEpisode(direction: NavigationDirection) -> EpisodeNavigationTarget? {
        guard let context = currentContext,
              case .episode(_, let s, let e, let studio, _, _, _) = context,
              let translation = translations.first(where: { $0.studio == studio })
        else { return nil }

        switch direction {
        case .forward:
            let seasonIdx = s - 1
            if let season = translation.seasons[safe: seasonIdx], e < season.episodes.count {
                return .episode(season: s, episode: e + 1)
            } else if translation.seasons[safe: s] != nil {
                return .episode(season: s + 1, episode: 1)
            } else {
                return .seriesEnded
            }

        case .backward:
            if e > 1 {
                return .episode(season: s, episode: e - 1)
            } else if let prevSeason = translation.seasons[safe: s - 2], !prevSeason.episodes.isEmpty {
                return .episode(season: s - 1, episode: prevSeason.episodes.count)
            } else {
                return .seriesEnded
            }
        }
    }
    
    func clearError() {
        error = nil
    }
    
    private func setupSettingsBinding() {
        settingsUseCase.settings
            .map { $0.isAutoplayEnabled }
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAutoplayEnabled, on: self)
            .store(in: &cancellables)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
