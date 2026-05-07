import UIKit
import Combine

final class SerieDetailViewController: BaseDetailViewController {

    private let viewModel: SerieDetailViewModel

    private let translationButton = DetailButton(
        title: L10n.Detail.audioTrack,
        icon: UIImage(systemName: "waveform"),
        style: .secondary
    )

    private let seasonsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.clipsToBounds = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let seasonTabsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 60
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let episodesStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Init

    init(
        viewModel: SerieDetailViewModel,
        themeManager: ThemeManagerProtocol,
        languageManager: LanguageManagerProtocol
    ) {
        self.viewModel = viewModel
        super.init(
            movie: ContentItem(
                id: 0, title: "", year: "", description: "", genre: "",
                rating: "", duration: "", type: .movie, translate: "",
                isAdIn: false, movieURL: "", posterURL: "",
                actors: [], directors: [], genreList: [], lastAdded: nil
            ),
            themeManager: themeManager,
            languageManager: languageManager
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshProgress()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSerieUI()
        bindViewModel()
        Task { await viewModel.load() }
    }

    // MARK: - Setup

    private func setupSerieUI() {
        contentView.addSubview(translationButton)
        contentView.addSubview(seasonsScrollView)
        seasonsScrollView.addSubview(seasonTabsStack)
        contentView.addSubview(episodesStack)

        NSLayoutConstraint.activate([
            translationButton.topAnchor.constraint(equalTo: infoStack.bottomAnchor, constant: 32),
            translationButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            translationButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),

            seasonsScrollView.topAnchor.constraint(equalTo: translationButton.bottomAnchor, constant: 24),
            seasonsScrollView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            seasonsScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            seasonsScrollView.heightAnchor.constraint(equalToConstant: 140),

            seasonTabsStack.topAnchor.constraint(equalTo: seasonsScrollView.topAnchor),
            seasonTabsStack.leadingAnchor.constraint(equalTo: seasonsScrollView.leadingAnchor, constant: 40),
            seasonTabsStack.trailingAnchor.constraint(equalTo: seasonsScrollView.trailingAnchor, constant: -40),
            seasonTabsStack.bottomAnchor.constraint(equalTo: seasonsScrollView.bottomAnchor),
            seasonTabsStack.centerYAnchor.constraint(equalTo: seasonsScrollView.centerYAnchor),

            episodesStack.topAnchor.constraint(equalTo: seasonsScrollView.bottomAnchor, constant: 24),
            episodesStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            episodesStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            episodesStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -80)
        ])

        favoriteButton.onPrimaryAction = { [weak self] in self?.viewModel.toggleFavorite() }
        translationButton.onPrimaryAction = { [weak self] in self?.showTranslationPicker() }
        translationButton.setThemeStyle(themeManager.theme.style)
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.$detail
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detail in self?.populateExtendedData(detail) }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$activeTranslation, viewModel.$activeSeasonIndex)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] translation, seasonIndex in
                guard let self, let t = translation else { return }
                self.updateTranslationButton(t)
                self.rebuildSeasons(t, activeIndex: seasonIndex)
                self.rebuildEpisodes(t.seasons[safe: seasonIndex]?.episodes ?? [])
            }
            .store(in: &cancellables)
        
        viewModel.$resolvedTranslationQualities
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let t = self.viewModel.activeTranslation else { return }
                self.updateTranslationButton(t)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in loading ? self?.startLoading() : self?.stopLoading() }
            .store(in: &cancellables)

        viewModel.$isFavorite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFav in
                self?.favoriteButton.setTitle(isFav ? L10n.Detail.inFavorites : L10n.Detail.addToFavorites)
                self?.favoriteButton.setIcon(UIImage(systemName: isFav ? "checkmark" : "plus"))
            }
            .store(in: &cancellables)

        viewModel.$progressUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self,
                      let t = self.viewModel.activeTranslation else { return }
                self.rebuildEpisodes(t.seasons[safe: self.viewModel.activeSeasonIndex]?.episodes ?? [])
            }
            .store(in: &cancellables)
    }
    
    private func updateTranslationButton(_ translation: Translation) {
        let quality = viewModel.displayQuality(for: translation)
        if quality.isEmpty {
            translationButton.setTitle("\(L10n.Detail.audioTrack): \(translation.studio)")
        } else {
            translationButton.setTitle("\(L10n.Detail.audioTrack): \(translation.studio) · \(quality)")
        }
    }
    
    private func populateExtendedData(_ detail: ContentDetail) {
        setPlaybackAvailability(isUnavailable: detail.isNotMovie)
        translationButton.isHidden = detail.isNotMovie
        seasonsScrollView.isHidden = detail.isNotMovie
        episodesStack.isHidden = detail.isNotMovie
        descriptionLabel.text = detail.description

        infoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let rows = [
            (L10n.Detail.country,   detail.countries.joined(separator: ", ")),
            (L10n.Detail.director,  detail.directors.joined(separator: ", ")),
            (L10n.Detail.writer,    detail.writers.joined(separator: ", ")),
            (L10n.Detail.actors,    detail.actors.prefix(5).joined(separator: ", ")),
            (L10n.Detail.slogan,    detail.slogan)
        ]

        posterIV.setPoster(url: detail.posterFullURL, placeholder: nil)
        backdropIV.setPoster(url: detail.posterFullURL, placeholder: nil)

        for (key, value) in rows {
            let row = DetailInfoRow()
            row.set(key: key, value: value, lines: key == L10n.Detail.actors ? 2 : 1)
            infoStack.addArrangedSubview(row)
        }

        rebuildMeta(detail)
        rebuildRatings(detail)
        applyStyle(themeManager.theme.style)
    }

    private func rebuildMeta(_ detail: ContentDetail) {
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let pills: [(String, UIColor)] = [
            (detail.year,              .systemGray),
            (detail.genres.first ?? "", .systemBlue),
            (L10n.Tab.series,          .systemIndigo),
            (detail.mpaa,              .systemRed)
        ]
        for (text, color) in pills where !text.isEmpty && text != "—" {
            metaStack.addArrangedSubview(DetailPillView(text: text, color: color.withAlphaComponent(0.6)))
        }
    }

    private func rebuildRatings(_ detail: ContentDetail) {
        ratingsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if detail.kinopoiskRating != "—" {
            ratingsStack.addArrangedSubview(RatingBadgeView(logo: "КП",   logoColor: .systemOrange, rating: detail.kinopoiskRating, votes: detail.kinopoiskVotes))
        }
        if detail.imdbRating != "—" {
            ratingsStack.addArrangedSubview(RatingBadgeView(logo: "IMDb", logoColor: .systemYellow, rating: detail.imdbRating,       votes: detail.imdbVotes))
        }
        if !detail.userRating.isEmpty {
            ratingsStack.addArrangedSubview(RatingBadgeView(logo: "👍",   logoColor: .white,        rating: detail.userRating,        votes: "\(detail.userLikes + detail.userDislikes)"))
        }
    }

    private func rebuildSeasons(_ translation: Translation, activeIndex: Int) {
        let seasons = translation.seasons
        if seasonTabsStack.arrangedSubviews.count == seasons.count {
            for (i, subview) in seasonTabsStack.arrangedSubviews.enumerated() {
                (subview as? SeasonTabButton)?.isActive = (i == activeIndex)
            }
        } else {
            seasonTabsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for (i, season) in seasons.enumerated() {
                let tab = SeasonTabButton(title: "\(L10n.Detail.season) \(i + 1)", subtitle: season.title)
                tab.isActive = (i == activeIndex)
                tab.onSelect = { [weak self] in self?.viewModel.selectSeason(index: i) }
                tab.setThemeStyle(themeManager.theme.style)
                seasonTabsStack.addArrangedSubview(tab)
            }
        }
    }

    private func rebuildEpisodes(_ list: [Episode]) {
        episodesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (i, episode) in list.enumerated() {
            let row = EpisodeRow(index: i, title: episode.title)
            row.setWatched(viewModel.isWatched(episodeIndex: i))
            row.setProgress(viewModel.getProgress(episodeIndex: i))
            row.onPlay = { [weak self] in self?.viewModel.play(episode: episode) }
            row.setThemeStyle(themeManager.theme.style)
            episodesStack.addArrangedSubview(row)
        }
    }

    // MARK: - Translation picker

    private func showTranslationPicker() {
        guard !viewModel.translations.isEmpty else { return }

        let items = viewModel.translations.map { translation in
            let quality = viewModel.displayQuality(for: translation)
            let subtitle = quality.isEmpty ? nil : quality
            return PickerViewController.Item(
                primary: translation.studio,
                secondary: subtitle,
                isSelected: translation.studio == viewModel.activeTranslation?.studio
            )
        }

        let picker = PickerViewController(title: L10n.Detail.audioTrack, items: items)
        picker.onSelect = { [weak self] index in
            self?.viewModel.selectTranslation(index: index)
        }
        present(picker, animated: true)
    }
    
    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        translationButton.setThemeStyle(style)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
