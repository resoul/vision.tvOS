import UIKit
import AVKit

final class MovieDetailViewController: UIViewController {

    private let movie: Movie

    private var detail: FilmixDetail?
    private var currentSeasonIndex = 0
    private var seasonTabButtons: [SeasonTabButton] = []
    private var selectedAudio: AudioTrack?
    private var translations: [FilmixTranslation] = []
    private var translationRowViews: [TranslationRow] = []
    private var activeTranslation: FilmixTranslation?

    // MARK: - Scroll container

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Background

    private lazy var backdropIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 1920, height: 1080))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0.94; v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Top zone views

    private lazy var posterIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.layer.cornerRadius = 18; iv.layer.cornerCurve = .continuous
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.75; iv.layer.shadowRadius = 36
        iv.layer.shadowOffset = CGSize(width: 0, height: 18)
        iv.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var accentStripe: UIView = {
        let v = UIView()
        v.backgroundColor = movie.accentColor.lighter(by: 0.5)
        v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = movie.title
        l.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        l.textColor = .white; l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true; l.minimumScaleFactor = 0.70
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var originalTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1); l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var metaRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 8; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let ratingsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 10; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let countryRow  = DetailInfoRow()
    private let directorRow = DetailInfoRow()
    private let writerRow   = DetailInfoRow()
    private let actorsRow   = DetailInfoRow()
    private let sloganRow   = DetailInfoRow()
    private let descDivider = ThinLine()
    private let descRow     = DetailInfoRow()

    private let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 10; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let detailSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1); v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Bottom zone views

    private let bottomDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var myListBtn: DetailButton = {
        let b = DetailButton(title: "+  Список", style: .secondary)
        b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()

    private let translationsDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.06)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let translationsSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1); v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let translationsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 4; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    // MARK: - Episodes panel

    private lazy var episodesPanelContainer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true; return v
    }()
    private let episodesDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.09)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private lazy var seasonTabsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 6; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()
    private let tabsSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private lazy var episodesCV: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical; layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 60, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear; cv.remembersLastFocusedIndexPath = true
        cv.register(EpisodeCell.self, forCellWithReuseIdentifier: EpisodeCell.reuseID)
        cv.dataSource = self; cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false; return cv
    }()
    private let audioTabSpacer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal); return v
    }()

    // MARK: - Constants

    private let lInset:  CGFloat = 64
    private let hInset:  CGFloat = 80
    private let posterW: CGFloat = 290
    private var posterH: CGFloat { posterW * 313 / 220 }
    private var topZoneH: CGFloat { posterH + 120 }
    private var rightX: CGFloat { lInset + posterW + 28 + 4 + 24 }

    // MARK: - Init

    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildLayout()
        populateFromListing()
        fetchDetail()
        fetchTranslations()
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(backdropIV)
        view.addSubview(backdropBlur)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Top zone container
        let topZone = UIView()
        topZone.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topZone)

        topZone.addSubview(posterIV)
        topZone.addSubview(accentStripe)
        topZone.addSubview(titleLabel)
        topZone.addSubview(originalTitleLabel)
        topZone.addSubview(metaRow)
        topZone.addSubview(ratingsStack)
        topZone.addSubview(infoStack)
        topZone.addSubview(detailSpinner)

        infoStack.addArrangedSubview(countryRow)
        infoStack.addArrangedSubview(directorRow)
        infoStack.addArrangedSubview(writerRow)
        infoStack.addArrangedSubview(actorsRow)
        infoStack.addArrangedSubview(sloganRow)
        infoStack.addArrangedSubview(descDivider)
        infoStack.addArrangedSubview(descRow)

        contentView.addSubview(bottomDivider)
        contentView.addSubview(myListBtn)
        contentView.addSubview(translationsDivider)
        contentView.addSubview(translationsSpinner)
        contentView.addSubview(translationsStack)

        contentView.addSubview(episodesPanelContainer)
        episodesPanelContainer.addSubview(episodesDivider)
        episodesPanelContainer.addSubview(seasonTabsStack)
        episodesPanelContainer.addSubview(tabsSeparator)
        episodesPanelContainer.addSubview(episodesCV)

        NSLayoutConstraint.activate([
            backdropIV.topAnchor.constraint(equalTo: view.topAnchor),
            backdropIV.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropIV.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropIV.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // ── Top zone ─────────────────────────────────────────────────
            topZone.topAnchor.constraint(equalTo: contentView.topAnchor),
            topZone.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topZone.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topZone.heightAnchor.constraint(equalToConstant: topZoneH),

            posterIV.leadingAnchor.constraint(equalTo: topZone.leadingAnchor, constant: lInset),
            posterIV.centerYAnchor.constraint(equalTo: topZone.centerYAnchor),
            posterIV.widthAnchor.constraint(equalToConstant: posterW),
            posterIV.heightAnchor.constraint(equalToConstant: posterH),

            accentStripe.leadingAnchor.constraint(equalTo: posterIV.trailingAnchor, constant: 28),
            accentStripe.topAnchor.constraint(equalTo: posterIV.topAnchor, constant: 8),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),
            accentStripe.heightAnchor.constraint(equalToConstant: posterH * 0.80),

            titleLabel.leadingAnchor.constraint(equalTo: topZone.leadingAnchor, constant: rightX),
            titleLabel.topAnchor.constraint(equalTo: topZone.topAnchor, constant: 56),
            titleLabel.trailingAnchor.constraint(equalTo: topZone.trailingAnchor, constant: -hInset),

            originalTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            originalTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            originalTitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            metaRow.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaRow.topAnchor.constraint(equalTo: originalTitleLabel.bottomAnchor, constant: 16),

            ratingsStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingsStack.topAnchor.constraint(equalTo: metaRow.bottomAnchor, constant: 14),

            infoStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoStack.topAnchor.constraint(equalTo: ratingsStack.bottomAnchor, constant: 18),
            infoStack.trailingAnchor.constraint(equalTo: topZone.trailingAnchor, constant: -hInset),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: topZone.bottomAnchor, constant: -24),

            detailSpinner.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailSpinner.topAnchor.constraint(equalTo: ratingsStack.bottomAnchor, constant: 20),

            // ── Bottom ────────────────────────────────────────────────────
            bottomDivider.topAnchor.constraint(equalTo: topZone.bottomAnchor),
            bottomDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            bottomDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            bottomDivider.heightAnchor.constraint(equalToConstant: 1),

            myListBtn.topAnchor.constraint(equalTo: bottomDivider.bottomAnchor, constant: 28),
            myListBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),

            translationsDivider.topAnchor.constraint(equalTo: myListBtn.bottomAnchor, constant: 28),
            translationsDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            translationsDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            translationsDivider.heightAnchor.constraint(equalToConstant: 1),

            translationsSpinner.topAnchor.constraint(equalTo: translationsDivider.bottomAnchor, constant: 24),
            translationsSpinner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),

            translationsStack.topAnchor.constraint(equalTo: translationsDivider.bottomAnchor, constant: 16),
            translationsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            translationsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),

            // ── Episodes ──────────────────────────────────────────────────
            episodesPanelContainer.topAnchor.constraint(equalTo: translationsStack.bottomAnchor, constant: 32),
            episodesPanelContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            episodesPanelContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            episodesPanelContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            episodesPanelContainer.heightAnchor.constraint(equalToConstant: 640),

            episodesDivider.topAnchor.constraint(equalTo: episodesPanelContainer.topAnchor),
            episodesDivider.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            episodesDivider.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),
            episodesDivider.heightAnchor.constraint(equalToConstant: 1),

            seasonTabsStack.topAnchor.constraint(equalTo: episodesDivider.bottomAnchor, constant: 24),
            seasonTabsStack.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            seasonTabsStack.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),

            tabsSeparator.topAnchor.constraint(equalTo: seasonTabsStack.bottomAnchor, constant: 10),
            tabsSeparator.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            tabsSeparator.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),
            tabsSeparator.heightAnchor.constraint(equalToConstant: 1),

            episodesCV.topAnchor.constraint(equalTo: tabsSeparator.bottomAnchor),
            episodesCV.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            episodesCV.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),
            episodesCV.bottomAnchor.constraint(equalTo: episodesPanelContainer.bottomAnchor),
        ])
    }

    // MARK: - Data

    private func populateFromListing() {
        titleLabel.text = movie.title
        posterIV.setPoster(url: movie.posterURL,
                           placeholder: PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782)))
        UIView.transition(with: backdropIV, duration: 0.4, options: .transitionCrossDissolve) {
            self.backdropIV.image = PlaceholderArt.generate(for: self.movie, size: CGSize(width: 1920, height: 1080))
        }
        rebuildMetaPills(year: movie.year, isSeries: movie.type.isSeries,
                         genres: movie.genreList.isEmpty ? [movie.genre] : movie.genreList,
                         duration: movie.duration, quality: "", mpaa: "")
        directorRow.set(key: "Режиссёр", value: movie.directors.prefix(2).joined(separator: ", "))
        actorsRow.set(key: "В ролях",    value: movie.actors.prefix(5).joined(separator: ", "), lines: 2)
        descRow.set(key: "Описание",     value: movie.description, lines: 4)
    }

    private func fetchDetail() {
        guard !movie.movieURL.isEmpty else { return }
        detailSpinner.startAnimating()
        FilmixService.shared.fetchDetail(path: movie.movieURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.detailSpinner.stopAnimating()
                if case .success(let d) = result { self.detail = d; self.populateFromDetail(d) }
            }
        }
    }

    private func populateFromDetail(_ d: FilmixDetail) {
        if !d.posterFull.isEmpty {
            posterIV.setPoster(url: d.posterFull,
                               placeholder: PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782)))
        }
        if !d.originalTitle.isEmpty && d.originalTitle != d.title {
            originalTitleLabel.text = d.originalTitle; originalTitleLabel.isHidden = false
        }
        rebuildMetaPills(year: d.year, isSeries: movie.type.isSeries,
                         genres: d.genres, duration: d.durationFormatted,
                         quality: d.quality, mpaa: d.mpaa)
        rebuildRatingBadges(d)
        countryRow.set(key: "Страна",    value: d.countries.joined(separator: ", "))
        directorRow.set(key: "Режиссёр", value: d.directors.prefix(2).joined(separator: ", "))
        writerRow.set(key: "Сценарист",  value: d.writers.prefix(2).joined(separator: ", "))
        actorsRow.set(key: "В ролях",    value: d.actors.prefix(5).joined(separator: ", "), lines: 2)
        sloganRow.set(key: "Слоган",     value: d.slogan)
        descRow.set(key: "Описание",     value: d.description, lines: 4)
    }

    private func fetchTranslations() {
        guard movie.id > 0 else { return }
        translationsSpinner.startAnimating()
        FilmixService.shared.fetchPlayerData(postId: movie.id, isSeries: movie.type.isSeries) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.translationsSpinner.stopAnimating()
                if case .success(let list) = result { self.translations = list; self.buildTranslationRows() }
            }
        }
    }

    private func buildTranslationRows() {
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        translationRowViews.removeAll()
        for t in translations {
            let row = TranslationRow(translation: t, accentColor: movie.accentColor.lighter(by: 0.5))
            row.onSelect = { [weak self] picked in self?.translationRowTapped(picked) }
            translationsStack.addArrangedSubview(row)
            translationRowViews.append(row)
        }
        if let first = translations.first {
            activeTranslation = first
            translationRowViews.first?.isActive = true
        }
    }

    private func translationRowTapped(_ t: FilmixTranslation) {
        activeTranslation = t
        translationRowViews.forEach { $0.isActive = ($0.translation.studio == t.studio) }

        if t.isSeries {
            let picker = SeriesPickerViewController(
                translation: t,
                movieId: movie.id,
                movieTitle: movie.title,
                accentColor: movie.accentColor.lighter(by: 0.5)
            )
            picker.onPlay = { [weak self] title, url in
                self?.playVideo(url: url, title: title)
            }
            present(picker, animated: true)
        } else {
            let picker = QualityPickerViewController(
                translation: t, accentColor: movie.accentColor.lighter(by: 0.5))
            picker.onSelect = { [weak self] quality, url in
                guard let self else { return }
                self.playVideo(url: url, title: "\(self.movie.title) · \(t.studio) · \(quality)")
            }
            present(picker, animated: true)
        }
    }

    private func playVideo(url: String, title: String) {
        guard let streamURL = URL(string: url) else { return }
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(url: streamURL); playerVC.title = title
        present(playerVC, animated: true) { playerVC.player?.play() }
    }

    private func rebuildMetaPills(year: String, isSeries: Bool,
                                  genres: [String], duration: String,
                                  quality: String, mpaa: String) {
        metaRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let yt = isSeries ? "\(year)–" : year
        if !year.isEmpty && year != "—" {
            metaRow.addArrangedSubview(MetaPill(text: yt, color: UIColor(white: 0.28, alpha: 1)))
        }
        for (i, g) in genres.prefix(3).enumerated() where !g.isEmpty && g != "—" {
            let a: CGFloat = [0.90, 0.70, 0.55][i]
            metaRow.addArrangedSubview(MetaPill(text: g, color: movie.accentColor.withAlphaComponent(a)))
        }
        if !duration.isEmpty && duration != "—" {
            metaRow.addArrangedSubview(MetaPill(text: duration, color: UIColor(white: 0.20, alpha: 1)))
        }
        if !quality.isEmpty {
            metaRow.addArrangedSubview(MetaPill(text: quality,
                                                color: UIColor(red: 0.12, green: 0.42, blue: 0.22, alpha: 0.9)))
        }
        if !mpaa.isEmpty {
            metaRow.addArrangedSubview(MetaPill(text: mpaa,
                                                color: UIColor(red: 0.55, green: 0.10, blue: 0.10, alpha: 0.85)))
        }
    }

    private func rebuildRatingBadges(_ d: FilmixDetail) {
        ratingsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if d.kinopoiskRating != "—", !d.kinopoiskRating.isEmpty {
            ratingsStack.addArrangedSubview(RatingBadge(
                logo: "КП", logoColor: UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1),
                rating: d.kinopoiskRating, votes: d.kinopoiskVotes))
        }
        if d.imdbRating != "—", !d.imdbRating.isEmpty {
            ratingsStack.addArrangedSubview(RatingBadge(
                logo: "IMDb", logoColor: UIColor(red: 0.85, green: 0.75, blue: 0.0, alpha: 1),
                rating: d.imdbRating, votes: d.imdbVotes))
        }
        if d.userPositivePercent > 0 {
            ratingsStack.addArrangedSubview(RatingBadge(
                logo: "👍", logoColor: .white,
                rating: "\(d.userPositivePercent)%",
                votes: "\(d.userLikes + d.userDislikes)"))
        }
    }

    private func scrollToFirstUnwatched(animated: Bool) {
        guard let season = currentSeason() else { return }
        if let idx = WatchStore.shared.firstUnwatchedIndex(movieId: movie.id, season: season) {
            DispatchQueue.main.async {
                self.episodesCV.scrollToItem(
                    at: IndexPath(item: idx, section: 0), at: .top, animated: animated)
            }
        }
    }

    @objc private func seasonTapped(_ sender: SeasonTabButton) {
        guard sender.tag != currentSeasonIndex else { return }
        seasonTabButtons[currentSeasonIndex].isActiveSeason = false
        currentSeasonIndex = sender.tag
        seasonTabButtons[currentSeasonIndex].isActiveSeason = true
        UIView.animate(withDuration: 0.14, animations: { self.episodesCV.alpha = 0 }) { _ in
            self.episodesCV.reloadData(); self.scrollToFirstUnwatched(animated: false)
            UIView.animate(withDuration: 0.18) { self.episodesCV.alpha = 1 }
        }
    }

    private func currentSeason() -> Season? {
        guard case .series(let seasons) = movie.type else { return nil }
        return seasons[safe: currentSeasonIndex]
    }
}

// MARK: - Episode CollectionView

extension MovieDetailViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        currentSeason()?.episodes.count ?? 0
    }
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: EpisodeCell.reuseID, for: ip) as! EpisodeCell
        if let season = currentSeason(), let ep = season.episodes[safe: ip.item] {
            let watched = WatchStore.shared.isWatched(
                movieId: movie.id, season: season.number, episode: ep.number)
            cell.configure(with: ep, movie: movie, isWatched: watched)
        }
        return cell
    }
}

extension MovieDetailViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        guard let season = currentSeason(), let ep = season.episodes[safe: ip.item] else { return }
        let store = WatchStore.shared
        let was = store.isWatched(movieId: movie.id, season: season.number, episode: ep.number)
        store.setWatched(!was, movieId: movie.id, season: season.number, episode: ep.number)
        cv.reloadItems(at: [ip])
    }
}

extension MovieDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize {
        CGSize(width: cv.bounds.width, height: 166)
    }
}
