import UIKit
import AVKit

// MARK: - MovieDetailViewController

final class MovieDetailViewController: UIViewController {

    // MARK: - Input
    private let movie: Movie

    // MARK: - State
    private var detail: FilmixDetail?
    private var currentSeasonIndex = 0
    private var seasonTabButtons: [SeasonTabButton] = []
    private var selectedAudio: AudioTrack?
    private var translations: [FilmixTranslation] = []
    private var translationRowViews: [TranslationRow] = []

    // MARK: - Background

    private lazy var backdropIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 1920, height: 1080))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0.94
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Poster

    private lazy var posterIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.layer.cornerCurve = .continuous
        iv.layer.shadowColor   = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.75
        iv.layer.shadowRadius  = 32
        iv.layer.shadowOffset  = CGSize(width: 0, height: 16)
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

    // MARK: - Info (right of poster)

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = movie.title
        l.font = UIFont.systemFont(ofSize: 44, weight: .heavy)
        l.textColor = .white
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.72
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var originalTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var metaRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let ratingsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .center
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
        sv.axis = .vertical
        sv.spacing = 9
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let detailSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Bottom zone

    private let bottomDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var myListBtn: DetailButton = {
        let b = DetailButton(title: "+  Список", style: .secondary)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Translations section

    private let translationsDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.06)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let translationsSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let translationsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Episodes panel

    private lazy var episodesPanelContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()
    private let episodesDivider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.09)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var seasonTabsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 6; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    private let tabsSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private lazy var episodesCV: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection    = .vertical
        layout.minimumLineSpacing = 14
        layout.sectionInset       = UIEdgeInsets(top: 20, left: 0, bottom: 60, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.remembersLastFocusedIndexPath = true
        cv.register(EpisodeCell.self, forCellWithReuseIdentifier: EpisodeCell.reuseID)
        cv.dataSource = self; cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    private let audioTabSpacer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
    }()
    private lazy var audioTabButton: AudioTabButton = {
        let b = AudioTabButton()
        b.accentColor = movie.accentColor.lighter(by: 0.5)
        b.addTarget(self, action: #selector(audioTapped), for: .primaryActionTriggered)
        return b
    }()

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
        setupAudio()
        fetchTranslations()
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(backdropIV)
        view.addSubview(backdropBlur)

        view.addSubview(posterIV)
        view.addSubview(accentStripe)
        view.addSubview(titleLabel)
        view.addSubview(originalTitleLabel)
        view.addSubview(metaRow)
        view.addSubview(ratingsStack)
        view.addSubview(infoStack)
        view.addSubview(detailSpinner)

        infoStack.addArrangedSubview(countryRow)
        infoStack.addArrangedSubview(directorRow)
        infoStack.addArrangedSubview(writerRow)
        infoStack.addArrangedSubview(actorsRow)
        infoStack.addArrangedSubview(sloganRow)
        infoStack.addArrangedSubview(descDivider)
        infoStack.addArrangedSubview(descRow)

        view.addSubview(bottomDivider)
        view.addSubview(myListBtn)
        view.addSubview(translationsDivider)
        view.addSubview(translationsSpinner)
        view.addSubview(translationsStack)

        view.addSubview(episodesPanelContainer)
        episodesPanelContainer.addSubview(episodesDivider)
        episodesPanelContainer.addSubview(seasonTabsStack)
        episodesPanelContainer.addSubview(tabsSeparator)
        episodesPanelContainer.addSubview(episodesCV)

        let lInset:  CGFloat = 64
        let hInset:  CGFloat = 80
        let posterW: CGFloat = 220
        let posterH: CGFloat = posterW * 313 / 220
        let rightX:  CGFloat = lInset + posterW + 28 + 4 + 24

        NSLayoutConstraint.activate([
            // Backdrop
            backdropIV.topAnchor.constraint(equalTo: view.topAnchor),
            backdropIV.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropIV.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropIV.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Poster
            posterIV.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: lInset),
            posterIV.topAnchor.constraint(equalTo: view.topAnchor, constant: 54),
            posterIV.widthAnchor.constraint(equalToConstant: posterW),
            posterIV.heightAnchor.constraint(equalToConstant: posterH),

            // Accent stripe
            accentStripe.leadingAnchor.constraint(equalTo: posterIV.trailingAnchor, constant: 28),
            accentStripe.topAnchor.constraint(equalTo: posterIV.topAnchor, constant: 6),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),
            accentStripe.heightAnchor.constraint(equalToConstant: posterH * 0.80),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: rightX),
            titleLabel.topAnchor.constraint(equalTo: posterIV.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),

            // Original title
            originalTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            originalTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            originalTitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Meta pills
            metaRow.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaRow.topAnchor.constraint(equalTo: originalTitleLabel.bottomAnchor, constant: 14),

            // Ratings
            ratingsStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingsStack.topAnchor.constraint(equalTo: metaRow.bottomAnchor, constant: 12),

            // Info rows
            infoStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoStack.topAnchor.constraint(equalTo: ratingsStack.bottomAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: posterIV.bottomAnchor),

            // Detail spinner
            detailSpinner.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailSpinner.topAnchor.constraint(equalTo: ratingsStack.bottomAnchor, constant: 18),

            // ── Bottom zone ───────────────────────────────────────────

            // Divider after poster
            bottomDivider.topAnchor.constraint(equalTo: posterIV.bottomAnchor, constant: 32),
            bottomDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hInset),
            bottomDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),
            bottomDivider.heightAnchor.constraint(equalToConstant: 1),

            // "+ Список"
            myListBtn.topAnchor.constraint(equalTo: bottomDivider.bottomAnchor, constant: 28),
            myListBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hInset),

            // Divider before translations
            translationsDivider.topAnchor.constraint(equalTo: myListBtn.bottomAnchor, constant: 28),
            translationsDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hInset),
            translationsDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),
            translationsDivider.heightAnchor.constraint(equalToConstant: 1),

            // Translations spinner
            translationsSpinner.topAnchor.constraint(equalTo: translationsDivider.bottomAnchor, constant: 24),
            translationsSpinner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hInset),

            // Translations list
            translationsStack.topAnchor.constraint(equalTo: translationsDivider.bottomAnchor, constant: 16),
            translationsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hInset),
            translationsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),

            // ── Episodes ──────────────────────────────────────────────
            episodesPanelContainer.topAnchor.constraint(equalTo: translationsStack.bottomAnchor, constant: 32),
            episodesPanelContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            episodesPanelContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            episodesPanelContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

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

    // MARK: - Populate from listing

    private func populateFromListing() {
        titleLabel.text = movie.title
        let ph = PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782))
        posterIV.setPoster(url: movie.posterURL, placeholder: ph)
        UIView.transition(with: backdropIV, duration: 0.4, options: .transitionCrossDissolve) {
            self.backdropIV.image = PlaceholderArt.generate(for: self.movie, size: CGSize(width: 1920, height: 1080))
        }
        rebuildMetaPills(
            year: movie.year, isSeries: movie.type.isSeries,
            genres: movie.genreList.isEmpty ? [movie.genre] : movie.genreList,
            duration: movie.duration, quality: "", mpaa: ""
        )
        directorRow.set(key: "Режиссёр", value: movie.directors.prefix(2).joined(separator: ", "))
        actorsRow.set(key: "В ролях",    value: movie.actors.prefix(5).joined(separator: ", "), lines: 2)
        descRow.set(key: "Описание",     value: movie.description, lines: 4)
    }

    // MARK: - Fetch detail

    private func fetchDetail() {
        guard !movie.movieURL.isEmpty else { return }
        detailSpinner.startAnimating()
        FilmixService.shared.fetchDetail(path: movie.movieURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.detailSpinner.stopAnimating()
                if case .success(let d) = result {
                    self.detail = d
                    self.populateFromDetail(d)
                }
            }
        }
    }

    private func populateFromDetail(_ d: FilmixDetail) {
        if !d.posterFull.isEmpty {
            let ph = PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782))
            posterIV.setPoster(url: d.posterFull, placeholder: ph)
        }
        if !d.originalTitle.isEmpty && d.originalTitle != d.title {
            originalTitleLabel.text     = d.originalTitle
            originalTitleLabel.isHidden = false
        }
        rebuildMetaPills(
            year: d.year, isSeries: movie.type.isSeries,
            genres: d.genres, duration: d.durationFormatted,
            quality: d.quality, mpaa: d.mpaa
        )
        rebuildRatingBadges(d)
        countryRow.set(key: "Страна",    value: d.countries.joined(separator: ", "))
        directorRow.set(key: "Режиссёр", value: d.directors.prefix(2).joined(separator: ", "))
        writerRow.set(key: "Сценарист",  value: d.writers.prefix(2).joined(separator: ", "))
        actorsRow.set(key: "В ролях",    value: d.actors.prefix(5).joined(separator: ", "), lines: 2)
        sloganRow.set(key: "Слоган",     value: d.slogan)
        descRow.set(key: "Описание",     value: d.description, lines: 4)
    }

    // MARK: - Fetch translations

    private func fetchTranslations() {
        guard movie.id > 0 else { return }
        translationsSpinner.startAnimating()
        FilmixService.shared.fetchPlayerData(postId: movie.id) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.translationsSpinner.stopAnimating()
                if case .success(let list) = result {
                    self.translations = list
                    self.buildTranslationRows()
                }
            }
        }
    }

    // MARK: - Build translation rows

    private func buildTranslationRows() {
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        translationRowViews.removeAll()

        for translation in translations {
            let row = TranslationRow(
                translation: translation,
                accentColor: movie.accentColor.lighter(by: 0.5)
            )
            row.onSelect = { [weak self] t in self?.selectTranslation(t) }
            translationsStack.addArrangedSubview(row)
            translationRowViews.append(row)
        }

        if let first = translations.first { selectTranslation(first) }
    }

    private func selectTranslation(_ translation: FilmixTranslation) {
        for row in translationRowViews {
            let active = row.translation.studio == translation.studio
            row.isActive = active
            row.showQualities(
                active,
                streams: translation.streams,
                sortedKeys: translation.sortedQualities,
                accentColor: movie.accentColor.lighter(by: 0.5)
            ) { [weak self] url in
                guard let self else { return }
                self.playVideo(url: url, title: "\(self.movie.title) · \(translation.studio)")
            }
        }
    }

    // MARK: - Play

    private func playVideo(url: String, title: String) {
        guard let streamURL = URL(string: url) else { return }
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(url: streamURL)
        playerVC.title  = title
        present(playerVC, animated: true) { playerVC.player?.play() }
    }

    // MARK: - Meta pills

    private func rebuildMetaPills(year: String, isSeries: Bool,
                                  genres: [String], duration: String,
                                  quality: String, mpaa: String) {
        metaRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let yearText = isSeries ? "\(year)–" : year
        if !year.isEmpty && year != "—" {
            metaRow.addArrangedSubview(MetaPill(text: yearText, color: UIColor(white: 0.28, alpha: 1)))
        }
        let alphas: [CGFloat] = [0.90, 0.70, 0.55]
        for (i, g) in genres.prefix(3).enumerated() where !g.isEmpty && g != "—" {
            metaRow.addArrangedSubview(MetaPill(text: g, color: movie.accentColor.withAlphaComponent(alphas[i])))
        }
        if !duration.isEmpty && duration != "—" {
            metaRow.addArrangedSubview(MetaPill(text: duration, color: UIColor(white: 0.20, alpha: 1)))
        }
        if !quality.isEmpty {
            metaRow.addArrangedSubview(MetaPill(text: quality, color: UIColor(red: 0.12, green: 0.42, blue: 0.22, alpha: 0.9)))
        }
        if !mpaa.isEmpty {
            metaRow.addArrangedSubview(MetaPill(text: mpaa, color: UIColor(red: 0.55, green: 0.10, blue: 0.10, alpha: 0.85)))
        }
    }

    // MARK: - Rating badges

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

    // MARK: - Audio

    private func setupAudio() {
        let savedId = WatchStore.shared.selectedAudioId(movieId: movie.id)
        selectedAudio = movie.audioTracks.first { $0.id == savedId } ?? movie.audioTracks.first
        audioTabButton.configure(with: selectedAudio)
    }

    @objc private func audioTapped() {
        let picker = AudioTrackPickerViewController(
            tracks: movie.audioTracks, movieId: movie.id, selectedId: selectedAudio?.id)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Series

    private func setupSeriesIfNeeded() {
        guard case .series(let seasons) = movie.type else { return }
        episodesPanelContainer.isHidden = false
        for (i, season) in seasons.enumerated() {
            let btn = SeasonTabButton(season: season)
            btn.accentColor    = movie.accentColor.lighter(by: 0.5)
            btn.isActiveSeason = (i == 0)
            btn.tag            = i
            btn.addTarget(self, action: #selector(seasonTapped(_:)), for: .primaryActionTriggered)
            seasonTabsStack.addArrangedSubview(btn)
            seasonTabButtons.append(btn)
        }
        if movie.audioTracks.count > 1 {
            seasonTabsStack.addArrangedSubview(audioTabSpacer)
            seasonTabsStack.addArrangedSubview(audioTabButton)
        }
        scrollToFirstUnwatched(animated: false)
    }

    private func scrollToFirstUnwatched(animated: Bool) {
        guard let season = currentSeason() else { return }
        if let idx = WatchStore.shared.firstUnwatchedIndex(movieId: movie.id, season: season) {
            DispatchQueue.main.async {
                self.episodesCV.scrollToItem(at: IndexPath(item: idx, section: 0), at: .top, animated: animated)
            }
        }
    }

    @objc private func seasonTapped(_ sender: SeasonTabButton) {
        guard sender.tag != currentSeasonIndex else { return }
        seasonTabButtons[currentSeasonIndex].isActiveSeason = false
        currentSeasonIndex = sender.tag
        seasonTabButtons[currentSeasonIndex].isActiveSeason = true
        UIView.animate(withDuration: 0.14, animations: { self.episodesCV.alpha = 0 }) { _ in
            self.episodesCV.reloadData()
            self.scrollToFirstUnwatched(animated: false)
            UIView.animate(withDuration: 0.18) { self.episodesCV.alpha = 1 }
        }
    }

    private func currentSeason() -> Season? {
        guard case .series(let seasons) = movie.type else { return nil }
        return seasons[safe: currentSeasonIndex]
    }
}

// MARK: - CollectionView

extension MovieDetailViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        currentSeason()?.episodes.count ?? 0
    }
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: EpisodeCell.reuseID, for: ip) as! EpisodeCell
        if let season = currentSeason(), let ep = season.episodes[safe: ip.item] {
            let watched = WatchStore.shared.isWatched(movieId: movie.id, season: season.number, episode: ep.number)
            cell.configure(with: ep, movie: movie, isWatched: watched)
        }
        return cell
    }
}

extension MovieDetailViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        guard let season = currentSeason(), let ep = season.episodes[safe: ip.item] else { return }
        let store = WatchStore.shared
        let was   = store.isWatched(movieId: movie.id, season: season.number, episode: ep.number)
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

extension MovieDetailViewController: AudioTrackPickerDelegate {
    func audioPicker(_ picker: AudioTrackPickerViewController, didSelect track: AudioTrack) {
        selectedAudio = track
        audioTabButton.configure(with: selectedAudio)
    }
}

// MARK: - TranslationRow
// Строка вида:  • Название студии          [480p] [720p] [1080p] [4K UHD]
// Качества видны только у активной (выбранной) строки.

final class TranslationRow: UIControl {

    let translation: FilmixTranslation
    var onSelect: ((FilmixTranslation) -> Void)?
    var isActive: Bool = false { didSet { updateLook(animated: true) } }

    private let dot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 3.5
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let studioLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let qualityStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(translation: FilmixTranslation, accentColor: UIColor) {
        self.translation = translation
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 54).isActive = true
        dot.backgroundColor = accentColor

        addSubview(bg)
        addSubview(dot)
        addSubview(studioLabel)
        addSubview(qualityStack)

        studioLabel.text = translation.studio

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 7),
            dot.heightAnchor.constraint(equalToConstant: 7),

            studioLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            studioLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            studioLabel.widthAnchor.constraint(equalToConstant: 380),

            qualityStack.leadingAnchor.constraint(equalTo: studioLabel.trailingAnchor, constant: 16),
            qualityStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            qualityStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
        ])

        addTarget(self, action: #selector(tapped), for: .primaryActionTriggered)
        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onSelect?(translation) }

    func showQualities(_ show: Bool,
                       streams: [String: String],
                       sortedKeys: [String],
                       accentColor: UIColor,
                       onPlay: @escaping (String) -> Void) {
        qualityStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard show else { return }
        for key in sortedKeys {
            guard let url = streams[key] else { continue }
            let btn = QualityButton(quality: key, accentColor: accentColor)
            btn.onSelect = { onPlay(url) }
            qualityStack.addArrangedSubview(btn)
        }
    }

    private func updateLook(animated: Bool) {
        let block = {
            self.bg.backgroundColor  = self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear
            self.studioLabel.textColor = self.isActive ? .white : UIColor(white: 0.55, alpha: 1)
            self.studioLabel.font    = UIFont.systemFont(ofSize: 22, weight: self.isActive ? .semibold : .medium)
            self.dot.alpha           = self.isActive ? 1 : 0
        }
        animated ? UIView.animate(withDuration: 0.18, animations: block) : block()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.15)
                : (self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear)
            self.studioLabel.textColor = self.isFocused ? .white
                : (self.isActive ? .white : UIColor(white: 0.55, alpha: 1))
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.015, y: 1.015) : .identity
        }, completion: nil)
    }

    override var canBecomeFocused: Bool { true }
}

// MARK: - QualityButton

final class QualityButton: UIControl {

    var onSelect: (() -> Void)?
    var isActive: Bool = false { didSet { updateLook() } }

    private let label: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let accentColor: UIColor

    init(quality: String, accentColor: UIColor) {
        self.accentColor = accentColor
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 8
        layer.cornerCurve  = .continuous
        layer.borderWidth  = 1.5
        label.text = quality
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
        addTarget(self, action: #selector(tapped), for: .primaryActionTriggered)
        updateLook()
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { isActive = true; onSelect?() }

    private func updateLook() {
        backgroundColor = isActive
            ? accentColor.withAlphaComponent(0.22)
            : UIColor(white: 1, alpha: 0.06)
        layer.borderColor = isActive
            ? accentColor.withAlphaComponent(0.75).cgColor
            : UIColor(white: 1, alpha: 0.12).cgColor
        label.textColor = isActive ? .white : UIColor(white: 0.55, alpha: 1)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20)
                : (self.isActive ? self.accentColor.withAlphaComponent(0.22) : UIColor(white: 1, alpha: 0.06))
            self.label.textColor = self.isFocused ? .white
                : (self.isActive ? .white : UIColor(white: 0.55, alpha: 1))
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.07, y: 1.07) : .identity
        }, completion: nil)
    }

    override var canBecomeFocused: Bool { true }
}

// MARK: - DetailInfoRow

final class DetailInfoRow: UIView {

    private let keyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        l.textColor = UIColor(white: 0.38, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        l.textColor = UIColor(white: 0.76, alpha: 1)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(keyLabel); addSubview(valueLabel)
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyLabel.firstBaselineAnchor.constraint(equalTo: valueLabel.firstBaselineAnchor),
            keyLabel.widthAnchor.constraint(equalToConstant: 155),
            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func set(key: String, value: String, lines: Int = 1) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        isHidden    = trimmed.isEmpty || trimmed == "—"
        guard !isHidden else { return }
        keyLabel.text            = key + ":"
        valueLabel.text          = trimmed
        valueLabel.numberOfLines = lines
    }
}

// MARK: - ThinLine

final class ThinLine: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.07)
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - RatingBadge

private final class RatingBadge: UIView {
    init(logo: String, logoColor: UIColor, rating: String, votes: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor    = UIColor(white: 1, alpha: 0.07)
        layer.cornerRadius = 10; layer.cornerCurve = .continuous

        let logoLbl = UILabel()
        logoLbl.text = logo; logoLbl.font = UIFont.systemFont(ofSize: 17, weight: .heavy)
        logoLbl.textColor = logoColor; logoLbl.translatesAutoresizingMaskIntoConstraints = false

        let ratingLbl = UILabel()
        ratingLbl.text = rating; ratingLbl.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        ratingLbl.textColor = .white; ratingLbl.translatesAutoresizingMaskIntoConstraints = false

        let votesLbl = UILabel()
        votesLbl.text = votes.isEmpty ? "" : "(\(Self.fmt(votes)))"
        votesLbl.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        votesLbl.textColor = UIColor(white: 0.42, alpha: 1)
        votesLbl.translatesAutoresizingMaskIntoConstraints = false

        let col = UIStackView(arrangedSubviews: [ratingLbl, votesLbl])
        col.axis = .vertical; col.spacing = 1
        col.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [logoLbl, col])
        row.axis = .horizontal; row.spacing = 8; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private static func fmt(_ raw: String) -> String {
        guard let n = Int(raw.replacingOccurrences(of: " ", with: "")) else { return raw }
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:     return String(format: "%.1fK", Double(n) / 1_000)
        default:           return "\(n)"
        }
    }
}
