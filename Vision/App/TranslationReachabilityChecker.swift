import Foundation

// MARK: - NextEpisodeAvailability

enum NextEpisodeAvailability {
    /// Следующий эпизод доступен в текущей озвучке
    case available(seasonIndex: Int, episodeIndex: Int, folder: _FilmixPlayerFolder)
    /// Озвучка закончилась — нет больше сезонов/эпизодов в этой озвучке
    case endOfTranslation
    /// Это последняя серия сериала вообще (все озвучки закончились)
    case endOfSeries
}

// MARK: - TranslationReachabilityChecker

enum TranslationReachabilityChecker {

    /// Возвращает доступность следующего эпизода для данной озвучки.
    ///
    /// - Parameters:
    ///   - translation: текущая активная озвучка
    ///   - seasonIndex: индекс текущего сезона (0-based)
    ///   - episodeIndex: индекс текущего эпизода (0-based)
    ///   - allTranslations: все доступные озвучки (для определения endOfSeries)
    static func nextEpisode(
        in translation: FilmixTranslation,
        seasonIndex: Int,
        episodeIndex: Int,
        allTranslations: [FilmixTranslation]
    ) -> NextEpisodeAvailability {

        // 1. Следующий эпизод в том же сезоне
        if let season = translation.seasons[safe: seasonIndex] {
            let nextEpisodeIndex = episodeIndex + 1
            if let folder = season.folder[safe: nextEpisodeIndex] {
                return .available(
                    seasonIndex: seasonIndex,
                    episodeIndex: nextEpisodeIndex,
                    folder: folder
                )
            }
        }

        // 2. Ищем следующий сезон с эпизодами в текущей озвучке
        let nextSeasonIndex = seasonIndex + 1
        for si in nextSeasonIndex ..< translation.seasons.count {
            let season = translation.seasons[si]
            if let folder = season.folder.first {
                return .available(
                    seasonIndex: si,
                    episodeIndex: 0,
                    folder: folder
                )
            }
        }

        // 3. В текущей озвучке больше нет эпизодов
        // Проверяем — есть ли хоть какая-то другая озвучка с продолжением
        let otherHasContinuation = allTranslations
            .filter { $0.studio != translation.studio }
            .contains { other in
                hasContinuation(in: other, afterSeasonIndex: seasonIndex, episodeIndex: episodeIndex)
            }

        return otherHasContinuation ? .endOfTranslation : .endOfSeries
    }

    /// Проверяет есть ли в озвучке эпизоды после указанной позиции
    static func hasContinuation(
        in translation: FilmixTranslation,
        afterSeasonIndex seasonIndex: Int,
        episodeIndex: Int
    ) -> Bool {
        // Следующий эпизод в том же сезоне
        if let season = translation.seasons[safe: seasonIndex],
           season.folder[safe: episodeIndex + 1] != nil {
            return true
        }
        // Следующий сезон с эпизодами
        for si in (seasonIndex + 1) ..< translation.seasons.count {
            if !translation.seasons[si].folder.isEmpty {
                return true
            }
        }
        return false
    }

    /// Удобный метод — возвращает folder и индексы если следующий эпизод доступен, иначе nil
    static func nextFolder(
        in translation: FilmixTranslation,
        seasonIndex: Int,
        episodeIndex: Int
    ) -> (seasonIndex: Int, episodeIndex: Int, folder: _FilmixPlayerFolder)? {
        let result = nextEpisode(
            in: translation,
            seasonIndex: seasonIndex,
            episodeIndex: episodeIndex,
            allTranslations: []
        )
        if case let .available(si, ei, folder) = result {
            return (si, ei, folder)
        }
        return nil
    }
}
