import UIKit
import Combine

final class MovieDetailViewController: BaseDetailViewController {
    private let viewModel: MovieDetailViewModel

    private let translationsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 10
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Init

    convenience init(
        movie: ContentItem,
        viewModel: MovieDetailViewModel,
        themeManager: ThemeManagerProtocol,
        languageManager: LanguageManagerProtocol
    ) {
        self.init(viewModel: viewModel, themeManager: themeManager, languageManager: languageManager)
    }

    init(
        viewModel: MovieDetailViewModel,
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

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        setupUI()
        Task { await viewModel.load() }
    }
    
    private func setupUI() {
        contentView.addSubview(translationsStack)
        translationsStack.constraints(top: infoStack.bottomAnchor, leading: titleLabel.leadingAnchor, bottom: contentView.bottomAnchor, trailing: titleLabel.trailingAnchor, padding: .init(top: 40, left: 0, bottom: 80, right: 0))

        favoriteButton.onPrimaryAction = { [weak self] in self?.viewModel.toggleFavorite() }
        playButton.onPrimaryAction = { [weak self] in
            guard let self, let first = self.viewModel.translations.first else { return }
            self.viewModel.play(translation: first)
        }
    }
    
    private func bindViewModel() {
        viewModel.$detail
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detail in self?.populateExtendedData(detail) }
            .store(in: &cancellables)
        
        viewModel.$resolvedStreams
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.rebuildTranslations(self.viewModel.translations)
            }
            .store(in: &cancellables)

        viewModel.$translations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] translations in self?.rebuildTranslations(translations) }
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

        viewModel.$isWatched
            .receive(on: DispatchQueue.main)
            .sink { [weak self] watched in self?.updateWatchedStatus(watched) }
            .store(in: &cancellables)
    }

    // MARK: - UI helpers

    private func updateWatchedStatus(_ isWatched: Bool) {
        metaStack.arrangedSubviews.forEach {
            if ($0 as? DetailPillView)?.text == L10n.Detail.watched { $0.removeFromSuperview() }
        }
        if isWatched {
            let pill = DetailPillView(text: L10n.Detail.watched, color: UIColor.systemGreen.withAlphaComponent(0.6))
            metaStack.insertArrangedSubview(pill, at: 0)
        }
    }

    private func populateExtendedData(_ detail: ContentDetail) {
        setPlaybackAvailability(isUnavailable: detail.isNotMovie)
        translationsStack.isHidden = detail.isNotMovie
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
            (detail.duration,          .systemGray),
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
    
    private func rebuildTranslations(_ list: [Translation]) {
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for translation in list {
            let qualityLabel = viewModel.displayQuality(for: translation)
            let row = TranslationRow(studio: translation.studio, quality: qualityLabel)
            row.onPlay = { [weak self] in self?.viewModel.play(translation: translation) }
            row.setThemeStyle(themeManager.theme.style)
            translationsStack.addArrangedSubview(row)
        }
    }
}
