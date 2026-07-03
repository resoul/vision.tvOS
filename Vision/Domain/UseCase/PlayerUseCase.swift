import Foundation

protocol PlayerUseCaseProtocol {
    func resolveInitialContext(for item: ContentItem) async throws -> PlaybackContext
    func resolveEpisode(from translations: [Translation], id: Int, season: Int, episode: Int, studio: String, quality: String) -> PlaybackContext?
    func switchTranslation(in item: ContentItem, translation: Translation, currentContext: PlaybackContext) async throws -> PlaybackContext
    func savePlaybackState(movieId: Int, context: PlaybackContext) async throws
    func savedPlaybackState(movieId: Int) async throws -> PlaybackState?
    func saveSelectedTranslation(movieId: Int, studio: String, quality: String, season: Int, episode: Int) async throws
    func fetchTranslations(for item: ContentItem) async throws -> [Translation]
    func resolvePreferredStream(from streams: [String: String]) async -> (quality: String, url: String)?
    func preferredURL(from streams: [String: String]) async -> String?
}

final class PlayerUseCase: PlayerUseCaseProtocol {
    private let filmix: FilmixProtocol
    private let stateRepository: PlaybackStateRepository
    private let settingsRepository: SettingsRepositoryProtocol
    
    init(
        filmix: FilmixProtocol,
        stateRepository: PlaybackStateRepository,
        settingsRepository: SettingsRepositoryProtocol
    ) {
        self.filmix = filmix
        self.stateRepository = stateRepository
        self.settingsRepository = settingsRepository
    }
    
    func resolveInitialContext(for item: ContentItem) async throws -> PlaybackContext {
        let translations = try await filmix.fetchTranslations(postId: item.id, isSeries: item.type.isSeries)
        guard !translations.isEmpty else {
            throw PlayerError.noTranslations
        }

        let lastState = try await stateRepository.getState(movieId: item.id)
        let preferredQuality = await getPreferredQuality()
        
        if let state = lastState {
            if let translation = translations.first(where: { $0.studio == state.studio }) ?? translations.first {
                if item.type.isSeries {
                    let seasonIdx = max(0, state.season - 1)
                    let episodeIdx = max(0, state.episode - 1)
                    
                    if let season = translation.seasons[safe: seasonIdx],
                       let episode = season.episodes[safe: episodeIdx] {
                        let url = resolveURL(from: episode.streams, preferred: preferredQuality)
                        return .episode(
                            id: item.id,
                            season: state.season,
                            episode: state.episode,
                            studio: translation.studio,
                            quality: preferredQuality,
                            url: url,
                            title: episode.title
                        )
                    }
                } else {
                    let url = resolveURL(from: translation.streams, preferred: preferredQuality)
                    return .movie(
                        id: item.id,
                        studio: translation.studio,
                        quality: preferredQuality,
                        url: url,
                        title: item.title
                    )
                }
            }
        }
        
        let translation = translations.first!
        if item.type.isSeries {
            let season = translation.seasons.first!
            let episode = season.episodes.first!
            let url = resolveURL(from: episode.streams, preferred: preferredQuality)
            return .episode(
                id: item.id,
                season: 1,
                episode: 1,
                studio: translation.studio,
                quality: preferredQuality,
                url: url,
                title: episode.title
            )
        } else {
            let url = resolveURL(from: translation.streams, preferred: preferredQuality)
            return .movie(
                id: item.id,
                studio: translation.studio,
                quality: preferredQuality,
                url: url,
                title: item.title
            )
        }
    }
    
    func resolveEpisode(from translations: [Translation], id: Int, season: Int, episode: Int, studio: String, quality: String) -> PlaybackContext? {
        guard let translation = translations.first(where: { $0.studio == studio }) else { return nil }

        let seasonIdx = season - 1
        let episodeIdx = episode - 1

        guard let s = translation.seasons[safe: seasonIdx],
              let e = s.episodes[safe: episodeIdx] else { return nil }

        let url = resolveURL(from: e.streams, preferred: quality)
        return .episode(
            id: id,
            season: season,
            episode: episode,
            studio: translation.studio,
            quality: quality,
            url: url,
            title: e.title
        )
    }
    
    func switchTranslation(in item: ContentItem, translation: Translation, currentContext: PlaybackContext) async throws -> PlaybackContext {
        let quality = await getPreferredQuality() // Or keep current quality
        
        switch currentContext {
        case .movie(let id, _, let quality, _, let title):
            let newUrl = resolveURL(from: translation.streams, preferred: quality)
            return .movie(id: id, studio: translation.studio, quality: quality, url: newUrl, title: title)
            
        case .episode(let id, let s, let e, _, _, _, _):
            guard let season = translation.seasons[safe: s - 1],
                  let episode = season.episodes[safe: e - 1] else {
                let fallbackS = translation.seasons.first!
                let fallbackE = fallbackS.episodes.first!
                let url = resolveURL(from: fallbackE.streams, preferred: quality)
                return .episode(id: id, season: 1, episode: 1, studio: translation.studio, quality: quality, url: url, title: fallbackE.title)
            }
            let url = resolveURL(from: episode.streams, preferred: quality)
            return .episode(id: id, season: s, episode: e, studio: translation.studio, quality: quality, url: url, title: episode.title)
        }
    }
    
    func savePlaybackState(movieId: Int, context: PlaybackContext) async throws {
        let state: PlaybackState
        switch context {
        case .movie(let id, let studio, let quality, _, _):
            state = PlaybackState(movieId: id, season: 0, episode: 0, studio: studio, quality: quality, updatedAt: Date())
        case .episode(let id, let s, let e, let studio, let quality, _, _):
            state = PlaybackState(movieId: id, season: s, episode: e, studio: studio, quality: quality, updatedAt: Date())
        }
        try await stateRepository.saveState(state)
    }

    func savedPlaybackState(movieId: Int) async throws -> PlaybackState? {
        try await stateRepository.getState(movieId: movieId)
    }

    func saveSelectedTranslation(movieId: Int, studio: String, quality: String, season: Int, episode: Int) async throws {
        let state = PlaybackState(
            movieId: movieId,
            season: season,
            episode: episode,
            studio: studio,
            quality: quality,
            updatedAt: Date()
        )
        try await stateRepository.saveState(state)
    }
    
    func fetchTranslations(for item: ContentItem) async throws -> [Translation] {
        try await filmix.fetchTranslations(postId: item.id, isSeries: item.type.isSeries)
    }

    func resolvePreferredStream(from streams: [String: String]) async -> (quality: String, url: String)? {
        guard !streams.isEmpty else { return nil }
        let preferredQuality = await getPreferredQuality()
        if let preferredURL = streams[preferredQuality] {
            return (preferredQuality, preferredURL)
        }

        let sorted = streams.sorted { lhs, rhs in
            let l = Int(lhs.key.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            let r = Int(rhs.key.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            return l > r
        }
        guard let best = sorted.first else { return nil }
        return (best.key, best.value)
    }
    
    func preferredURL(from streams: [String : String]) async -> String? {
        await resolvePreferredStream(from: streams)?.url
    }
    
    // MARK: - Private
    
    private func getPreferredQuality() async -> String {
        return await withCheckedContinuation { continuation in
            settingsRepository.fetchSettings { result in
                switch result {
                case .success(let settings):
                    continuation.resume(returning: settings.preferredQuality.rawValue)
                case .failure:
                    continuation.resume(returning: VideoQuality.auto.rawValue)
                }
            }
        }
    }
    
    private func resolveURL(from streams: [String: String], preferred: String) -> String {
        if let url = streams[preferred] { return url }
        let sorted = streams.sorted { lhs, rhs in
            let l = Int(lhs.key.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            let r = Int(rhs.key.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            return l > r
        }
        return sorted.first?.value ?? ""
    }
}

enum PlayerError: Error {
    case noTranslations
    case episodeNotFound
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
