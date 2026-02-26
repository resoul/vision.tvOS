import UIKit

final class SerieDetailViewController: BaseDetailViewController {

    // MARK: - State

    private var translations: [FilmixTranslation] = []
    private var activeTranslation: FilmixTranslation?
    private var activeSeasonIndex = 0

    // MARK: - Episode Panel Views

    private let episodePanelDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let controlBar: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var studioPicker: StudioPickerButton = {
        let b = StudioPickerButton(accentColor: movie.accentColor.lighter(by: 0.5))
        b.onTap = { [weak self] in self?.showStudioPicker() }
        return b
    }()

    private let seasonTabsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 6; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()
    private var seasonTabButtons: [CompactSeasonTab] = []

    private let episodeSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1); v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var qualityButton: QualityPreferenceButton = {
        let b = QualityPreferenceButton()
        b.onTap = { [weak self] in self?.showQualityPicker() }
        return b
    }()

    private let tabSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let episodesStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Серии не найдены"
        l.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildSerieLayout()
        episodesStack.clipsToBounds = false
        qualityButton.configure(quality: SeriesPickerStore.shared.globalPreferredQuality ?? "Авто")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshEpisodeProgress()
    }

    // MARK: - Layout

    private func buildSerieLayout() {
        contentView.addSubview(episodePanelDivider)
        contentView.addSubview(controlBar)
        controlBar.addSubview(studioPicker)
        controlBar.addSubview(seasonTabsStack)
        controlBar.addSubview(qualityButton)
        controlBar.addSubview(episodeSpinner)
        contentView.addSubview(tabSeparator)
        contentView.addSubview(episodesStack)
        contentView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            episodePanelDivider.topAnchor.constraint(equalTo: myListBtn.bottomAnchor, constant: 28),
            episodePanelDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            episodePanelDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            episodePanelDivider.heightAnchor.constraint(equalToConstant: 1),

            controlBar.topAnchor.constraint(equalTo: episodePanelDivider.bottomAnchor, constant: 20),
            controlBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            controlBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            controlBar.heightAnchor.constraint(equalToConstant: 54),

            studioPicker.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor),
            studioPicker.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            seasonTabsStack.leadingAnchor.constraint(equalTo: studioPicker.trailingAnchor, constant: 16),
            seasonTabsStack.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            episodeSpinner.trailingAnchor.constraint(equalTo: qualityButton.leadingAnchor, constant: -12),
            episodeSpinner.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            qualityButton.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor),
            qualityButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            tabSeparator.topAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: 12),
            tabSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            tabSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            tabSeparator.heightAnchor.constraint(equalToConstant: 1),

            episodesStack.topAnchor.constraint(equalTo: tabSeparator.bottomAnchor, constant: 12),
            episodesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset - 4),
            episodesStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -(hInset - 4)),
            episodesStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60),

            emptyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tabSeparator.bottomAnchor, constant: 60),
        ])
    }
    
    override func onDetailLoaded(_ detail: FilmixDetail) {
        if detail.isNotMovie {
//            translationsSpinner.stopAnimating()
//            emptyLabel.text = "Видео недоступно"
//            emptyLabel.isHidden = false
        } else {
            fetchTranslations()
        }
    }

    private func fetchTranslations() {
        guard movie.id > 0 else { return }
        episodeSpinner.startAnimating()
        FilmixService.shared.fetchPlayerData(postId: movie.id, isSeries: true) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.episodeSpinner.stopAnimating()
                if case .success(let list) = result, !list.isEmpty {
                    self.translations = list
                    self.activeTranslation = list.first
                    self.studioPicker.configure(studio: list.first?.studio ?? "")
                    self.rebuildSeasonTabs()
                    self.rebuildEpisodes(animated: false)
                } else {
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    // MARK: - Studio Picker

    private func showStudioPicker() {
        guard !translations.isEmpty else { return }
        let picker = StudioListViewController(
            translations: translations,
            activeStudio: activeTranslation?.studio ?? "",
            accentColor: movie.accentColor.lighter(by: 0.5)
        )
        picker.onSelect = { [weak self] translation in
            guard let self else { return }
            self.activeTranslation = translation
            self.studioPicker.configure(studio: translation.studio)
            self.activeSeasonIndex = 0
            self.rebuildSeasonTabs()
            self.rebuildEpisodes(animated: true)
        }
        present(picker, animated: true)
    }

    // MARK: - Season Tabs

    private func rebuildSeasonTabs() {
        seasonTabsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        seasonTabButtons.removeAll()

        guard let t = activeTranslation else { return }

        for (i, season) in t.seasons.enumerated() {
            let btn = CompactSeasonTab(title: "С\(i + 1)", subtitle: season.title)
            btn.tag = i
            btn.isActiveTab = (i == activeSeasonIndex)
            btn.onSelect = { [weak self] in
                guard let self, i != self.activeSeasonIndex else { return }
                self.seasonTabButtons[self.activeSeasonIndex].isActiveTab = false
                self.activeSeasonIndex = i
                self.seasonTabButtons[i].isActiveTab = true
                self.rebuildEpisodes(animated: true)
            }
            seasonTabsStack.addArrangedSubview(btn)
            seasonTabButtons.append(btn)
        }
    }

    // MARK: - Episodes List

    private func rebuildEpisodes(animated: Bool) {
        guard let translation = activeTranslation,
              let season = translation.seasons[safe: activeSeasonIndex] else { return }

        let build = {
            self.episodesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

            if season.folder.isEmpty {
                self.emptyLabel.isHidden = false
                return
            }
            self.emptyLabel.isHidden = true

            for (i, folder) in season.folder.enumerated() {
                let seasonNum  = self.activeSeasonIndex + 1
                let episodeNum = i + 1

                let watched = PlaybackStore.shared.isEpisodeWatched(
                    movieId: self.movie.id, season: seasonNum, episode: episodeNum)

                let progress = PlaybackStore.shared.episodeProgress(
                    movieId: self.movie.id, season: seasonNum, episode: episodeNum)

                let row = EpisodeRow(
                    index: i,
                    folder: folder,
                    accentColor: self.movie.accentColor.lighter(by: 0.5),
                    isWatched: watched,
                    progressFraction: watched ? nil : progress?.fraction
                )

                row.onPlay = { [weak self] in
                    self?.playEpisode(folder: folder,
                                      seasonIndex: self?.activeSeasonIndex ?? 0,
                                      episodeIndex: i)
                }
                row.onWatchToggle = { [weak self] in
                    guard let self else { return }
                    let was = PlaybackStore.shared.isEpisodeWatched(
                        movieId: self.movie.id, season: seasonNum, episode: episodeNum)
                    PlaybackStore.shared.setEpisodeWatched(!was,
                        movieId: self.movie.id, season: seasonNum, episode: episodeNum)
                    row.setWatched(!was)
                }
                self.episodesStack.addArrangedSubview(row)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.scrollToFirstUnwatched(season: season, seasonIndex: self.activeSeasonIndex)
            }
        }

        if animated {
            UIView.animate(withDuration: 0.12, animations: {
                self.episodesStack.alpha = 0
            }) { _ in
                build()
                UIView.animate(withDuration: 0.18) { self.episodesStack.alpha = 1 }
            }
        } else {
            build()
        }
    }

    private func refreshEpisodeProgress() {
        guard let translation = activeTranslation,
              let season = translation.seasons[safe: activeSeasonIndex] else { return }

        for (i, row) in episodesStack.arrangedSubviews.enumerated() {
            guard let episodeRow = row as? EpisodeRow else { continue }
            let seasonNum  = activeSeasonIndex + 1
            let episodeNum = i + 1
            _ = season

            let watched  = PlaybackStore.shared.isEpisodeWatched(
                movieId: movie.id, season: seasonNum, episode: episodeNum)
            let progress = PlaybackStore.shared.episodeProgress(
                movieId: movie.id, season: seasonNum, episode: episodeNum)

            episodeRow.setWatched(watched)
            episodeRow.setProgressFraction(watched ? nil : progress?.fraction)
        }
    }

    private func scrollToFirstUnwatched(season: _FilmixPlayerSerial, seasonIndex: Int) {
        for (i, _) in season.folder.enumerated() {
            if !PlaybackStore.shared.isEpisodeWatched(
                movieId: movie.id, season: seasonIndex + 1, episode: i + 1) {
                guard let row = episodesStack.arrangedSubviews[safe: i] else { return }
                let rowFrame = row.convert(row.bounds, to: scrollView)
                scrollView.scrollRectToVisible(rowFrame, animated: false)
                return
            }
        }
    }

    private func showQualityPicker() {
        let qualities = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let current = SeriesPickerStore.shared.globalPreferredQuality

        var items: [PickerViewController.Item] = [
            .init(primary: "Авто", secondary: "Лучшее доступное", isSelected: current == nil)
        ]
        items += qualities.map { q in
            .init(primary: q, secondary: nil, isSelected: q == current)
        }

        let picker = PickerViewController(title: "Качество по умолчанию", items: items)
        picker.onSelect = { [weak self] index in
            guard let self else { return }
            let selected = index == 0 ? nil : qualities[index - 1]
            SeriesPickerStore.shared.globalPreferredQuality = selected
            self.qualityButton.configure(quality: selected ?? "Авто")
        }
        present(picker, animated: true)
    }


    // MARK: - Next Episode

    private func playNextEpisode(afterSeasonIndex seasonIndex: Int, episodeIndex: Int) {
        guard let translation = activeTranslation else { return }

        let season = translation.seasons[safe: seasonIndex]
        let nextEpisodeIndex = episodeIndex + 1

        if let season, nextEpisodeIndex < season.folder.count {
            let folder = season.folder[nextEpisodeIndex]
            playEpisode(folder: folder, seasonIndex: seasonIndex, episodeIndex: nextEpisodeIndex)
            if activeSeasonIndex != seasonIndex {
                activeSeasonIndex = seasonIndex
                rebuildSeasonTabs()
                rebuildEpisodes(animated: false)
            }
        } else {
            let nextSeasonIndex = seasonIndex + 1
            guard nextSeasonIndex < translation.seasons.count,
                  let nextSeason = translation.seasons[safe: nextSeasonIndex],
                  !nextSeason.folder.isEmpty
            else { return }

            activeSeasonIndex = nextSeasonIndex
            rebuildSeasonTabs()
            rebuildEpisodes(animated: false)

            playEpisode(folder: nextSeason.folder[0],
                        seasonIndex: nextSeasonIndex, episodeIndex: 0)
        }
    }

    private func handleNextEpisodeRequest(seasonIndex: Int, episodeIndex: Int) {
        if activeSeasonIndex != seasonIndex {
            activeSeasonIndex = seasonIndex
            rebuildSeasonTabs()
            rebuildEpisodes(animated: false)
        }

        guard let translation = activeTranslation,
              let folder = translation.seasons[safe: seasonIndex]?.folder[safe: episodeIndex]
        else { return }

        playEpisode(folder: folder, seasonIndex: seasonIndex, episodeIndex: episodeIndex)
    }

    func playEpisode(folder: _FilmixPlayerFolder, seasonIndex: Int, episodeIndex: Int) {
        let streams = folder.streams
        guard !streams.isEmpty else { return }

        let studio    = activeTranslation?.studio ?? ""
        let order     = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let preferred = SeriesPickerStore.shared.globalPreferredQuality

        if let pref = preferred, let url = streams[pref] {
            finishPlay(url: url, quality: pref, folder: folder,
                       seasonIndex: seasonIndex, episodeIndex: episodeIndex, studio: studio)
        } else if preferred != nil {
            showEpisodeQualityFallback(streams: streams, folder: folder,
                                       seasonIndex: seasonIndex, episodeIndex: episodeIndex, studio: studio)
        } else {
            let bestKey = order.first(where: { streams[$0] != nil }) ?? streams.keys.sorted().first
            guard let key = bestKey, let url = streams[key] else { return }
            finishPlay(url: url, quality: key, folder: folder,
                       seasonIndex: seasonIndex, episodeIndex: episodeIndex, studio: studio)
        }
    }

    // MARK: - finishPlay

    func finishPlay(url: String, quality: String, folder: _FilmixPlayerFolder,
                    seasonIndex: Int, episodeIndex: Int, studio: String) {

        SeriesPickerStore.shared.save(
            movieId: movie.id, season: seasonIndex,
            episode: episodeIndex, quality: quality, studio: studio
        )

        let seasonNum  = seasonIndex + 1
        let episodeNum = episodeIndex + 1
        let resumePos  = PlaybackStore.shared
            .episodeProgress(movieId: movie.id, season: seasonNum, episode: episodeNum)?
            .positionSeconds ?? 0

        let nextItem = buildNextItem(
            currentSeasonIndex: seasonIndex,
            currentEpisodeIndex: episodeIndex,
            studio: studio,
            quality: quality
        )

        let ctx = PlaybackContext.episode(
            movieId:   movie.id,
            season:    seasonNum,
            episode:   episodeNum,
            studio:    studio,
            quality:   quality,
            streamURL: url,
            title:     "E\(episodeNum) · \(folder.title)",
            nextItem:  nextItem
        )

        let playerVC = PlaybackViewController(context: ctx, resumePosition: resumePos)

        playerVC.onRequestNextEpisode = { [weak self] seasonIndex, episodeIndex in
            self?.syncUIToEpisode(seasonIndex: seasonIndex, episodeIndex: episodeIndex)
        }

        playerVC.onTranslationEnded = { [weak self] in
            self?.handleTranslationEnded()
        }

        playerVC.translationProvider = { [weak self] in
            self?.activeTranslation
        }
        
        WatchHistoryStore.shared.touch(movie)

        present(playerVC, animated: true)
    }

    // MARK: - buildNextItem

    private func buildNextItem(
        currentSeasonIndex: Int,
        currentEpisodeIndex: Int,
        studio: String,
        quality: String
    ) -> NextEpisodeItem? {
        guard let translation = activeTranslation else { return nil }

        let availability = TranslationReachabilityChecker.nextEpisode(
            in: translation,
            seasonIndex: currentSeasonIndex,
            episodeIndex: currentEpisodeIndex,
            allTranslations: translations
        )

        guard case let .available(si, ei, folder) = availability else { return nil }

        return NextEpisodeItem(
            seasonIndex:  si,
            episodeIndex: ei,
            folder:       folder,
            studio:       studio,
            quality:      quality
        )
    }

    // MARK: - Callbacks from PlaybackViewController

    func syncUIToEpisode(seasonIndex: Int, episodeIndex: Int) {
        if activeSeasonIndex != seasonIndex {
            activeSeasonIndex = seasonIndex
            rebuildSeasonTabs()
            rebuildEpisodes(animated: false)
        }
        
        guard let row = episodesStack.arrangedSubviews[safe: episodeIndex] else { return }
        let rowFrame = row.convert(row.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rowFrame, animated: true)
    }

    private func handleTranslationEnded() {
        let alert = NoTranslationAlert()
        alert.onSwitchTranslation = { [weak self] in
            self?.showStudioPicker()
        }
        alert.modalPresentationStyle = .overFullScreen
        alert.modalTransitionStyle   = .crossDissolve
        present(alert, animated: true)
    }
    
    func showEpisodeQualityFallback(streams: [String: String],
                                        folder: _FilmixPlayerFolder,
                                        seasonIndex: Int, episodeIndex: Int, studio: String) {
        let available = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
            .filter { streams[$0] != nil }

        let items = available.map { q in
            PickerViewController.Item(primary: q, secondary: nil, isSelected: false)
        }

        let picker = PickerViewController(
            title: "Качество недоступно",
            subtitle: "Предпочитаемое качество отсутствует. Выберите из доступных:",
            items: items
        )
        picker.onSelect = { [weak self] index in
            guard let self else { return }
            let key = available[index]
            guard let url = streams[key] else { return }
            self.finishPlay(url: url, quality: key, folder: folder,
                            seasonIndex: seasonIndex, episodeIndex: episodeIndex, studio: studio)
        }
        present(picker, animated: true)
    }
}
