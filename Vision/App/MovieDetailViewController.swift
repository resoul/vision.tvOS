import UIKit

// MARK: - MovieDetailViewController

final class MovieDetailViewController: UIViewController {

    // MARK: - Input

    private let movie: Movie   // from listing (used for instant display while loading)

    // MARK: - State

    private var detail: FilmixDetail?
    private var currentSeasonIndex = 0
    private var seasonTabButtons: [SeasonTabButton] = []
    private var selectedAudio: AudioTrack?

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
        v.alpha = 0.92
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Left panel (poster + stripe)

    private lazy var posterIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 18
        iv.layer.cornerCurve = .continuous
        iv.layer.shadowColor  = UIColor.black.cgColor
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

    // MARK: - Right panel — info

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = movie.title
        l.font = UIFont.systemFont(ofSize: 42, weight: .heavy)
        l.textColor = .white
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var originalTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.50, alpha: 1)
        l.numberOfLines = 1
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

    // Vertical stack of labelled info rows
    private let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let translateRow  = DetailInfoRow()
    private let countryRow    = DetailInfoRow()
    private let directorRow   = DetailInfoRow()
    private let writerRow     = DetailInfoRow()
    private let actorsRow     = DetailInfoRow()
    private let sloganRow     = DetailInfoRow()
    private let descDivider   = ThinLine()
    private let descRow       = DetailInfoRow()

    // MARK: - Buttons

    private lazy var playBtn: DetailButton = {
        let b = DetailButton(title: "▶  Смотреть", style: .primary)
        b.addTarget(self, action: #selector(playTapped), for: .primaryActionTriggered)
        return b
    }()
    private lazy var myListBtn  = DetailButton(title: "+  Список",  style: .secondary)
    private lazy var trailerBtn = DetailButton(title: "⊳  Трейлер", style: .secondary)

    private lazy var btnStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [playBtn, myListBtn, trailerBtn])
        sv.axis = .horizontal
        sv.spacing = 14
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Rating badges

    private let ratingsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Loading overlay

    private let loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.6, alpha: 1)
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
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
        layout.scrollDirection   = .vertical
        layout.minimumLineSpacing = 14
        layout.sectionInset      = UIEdgeInsets(top: 20, left: 0, bottom: 60, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.remembersLastFocusedIndexPath = true
        cv.register(EpisodeCell.self, forCellWithReuseIdentifier: EpisodeCell.reuseID)
        cv.dataSource = self
        cv.delegate   = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // Audio
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
        populateFromListing()   // instant — from listing data
        fetchDetail()           // async — enrich with full page
        setupAudio()
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
        view.addSubview(btnStack)
        view.addSubview(loadingView)
        view.addSubview(episodesPanelContainer)

        episodesPanelContainer.addSubview(episodesDivider)
        episodesPanelContainer.addSubview(seasonTabsStack)
        episodesPanelContainer.addSubview(tabsSeparator)
        episodesPanelContainer.addSubview(episodesCV)

        // Info rows
        infoStack.addArrangedSubview(translateRow)
        infoStack.addArrangedSubview(countryRow)
        infoStack.addArrangedSubview(directorRow)
        infoStack.addArrangedSubview(writerRow)
        infoStack.addArrangedSubview(actorsRow)
        infoStack.addArrangedSubview(sloganRow)
        infoStack.addArrangedSubview(descDivider)
        infoStack.addArrangedSubview(descRow)

        let lInset: CGFloat = 64
        let hInset: CGFloat = 80

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
            posterIV.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            posterIV.widthAnchor.constraint(equalToConstant: 240),
            posterIV.heightAnchor.constraint(equalToConstant: 341),

            // Accent stripe
            accentStripe.leadingAnchor.constraint(equalTo: posterIV.trailingAnchor, constant: 28),
            accentStripe.topAnchor.constraint(equalTo: posterIV.topAnchor, constant: 8),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),
            accentStripe.heightAnchor.constraint(equalToConstant: 280),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 24),
            titleLabel.topAnchor.constraint(equalTo: posterIV.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),

            // Original title
            originalTitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            originalTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            originalTitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Meta pills
            metaRow.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaRow.topAnchor.constraint(equalTo: originalTitleLabel.bottomAnchor, constant: 12),

            // Rating badges
            ratingsStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ratingsStack.topAnchor.constraint(equalTo: metaRow.bottomAnchor, constant: 10),

            // Info stack
            infoStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoStack.topAnchor.constraint(equalTo: ratingsStack.bottomAnchor, constant: 14),
            infoStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: posterIV.bottomAnchor),

            // Buttons
            btnStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            btnStack.topAnchor.constraint(equalTo: posterIV.bottomAnchor, constant: 28),

            // Loading spinner — near the title
            loadingView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            loadingView.topAnchor.constraint(equalTo: ratingsStack.bottomAnchor, constant: 20),

            // Episodes panel
            episodesPanelContainer.topAnchor.constraint(equalTo: btnStack.bottomAnchor, constant: 32),
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

    // MARK: - Populate from listing (instant)

    private func populateFromListing() {
        titleLabel.text = movie.title

        let placeholder = PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782))
        posterIV.setPoster(url: movie.posterURL, placeholder: placeholder)

        // Backdrop
        UIView.transition(with: backdropIV, duration: 0.4, options: .transitionCrossDissolve) {
            self.backdropIV.image = PlaceholderArt.generate(for: self.movie, size: CGSize(width: 1920, height: 1080))
        }

        // Meta pills from listing data
        rebuildMetaPills(
            year: movie.year,
            isSeries: movie.type.isSeries,
            genres: movie.genreList.isEmpty ? [movie.genre] : movie.genreList,
            duration: movie.duration,
            quality: "",
            mpaa: ""
        )

        // Basic rows from listing
        translateRow.set(key: "Перевод",  value: movie.translate)
        directorRow.set(key: "Режиссёр",  value: movie.directors.prefix(2).joined(separator: ", "))
        actorsRow.set(key: "В ролях",     value: movie.actors.prefix(5).joined(separator: ", "), lines: 2)
        descRow.set(key: "Описание",      value: movie.description, lines: 3)
    }

    // MARK: - Fetch full detail

    private func fetchDetail() {
        // Need the canonical film/seria URL, not the /play/ URL
        // The listing movieURL might be a /play/ URL — derive the detail URL from it
        // Expected pattern: movie.movieURL contains path like /film/genre/xxx-title-year.html
        // But listing gives us /play/id — we can construct it from the article link
        // For now use movieURL directly; FilmixService handles /play/ redirect too
        let path = movie.movieURL
        guard !path.isEmpty else { return }

        loadingView.startAnimating()

        FilmixService.shared.fetchDetail(path: path) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loadingView.stopAnimating()
                switch result {
                case .success(let d):
                    self.detail = d
                    self.populateFromDetail(d)
                case .failure:
                    // Silently fail — listing data stays visible
                    break
                }
            }
        }
    }

    // MARK: - Populate from full detail

    private func populateFromDetail(_ d: FilmixDetail) {
        // Poster — upgrade to full if available
        if !d.posterFull.isEmpty {
            let placeholder = PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782))
            posterIV.setPoster(url: d.posterFull, placeholder: placeholder)
        }

        // Original title
        if !d.originalTitle.isEmpty && d.originalTitle != d.title {
            originalTitleLabel.text   = d.originalTitle
            originalTitleLabel.isHidden = false
        }

        // Meta pills — richer version
        rebuildMetaPills(
            year: d.year,
            isSeries: movie.type.isSeries,
            genres: d.genres,
            duration: d.durationFormatted,
            quality: d.quality,
            mpaa: d.mpaa
        )

        // External rating badges
        rebuildRatingBadges(d)

        // Info rows
        translateRow.set(key: "Перевод",    value: d.translate)
        countryRow.set(key: "Страна",       value: d.countries.joined(separator: ", "))
        directorRow.set(key: "Режиссёр",    value: d.directors.prefix(2).joined(separator: ", "))
        writerRow.set(key: "Сценарист",     value: d.writers.prefix(2).joined(separator: ", "))
        actorsRow.set(key: "В ролях",       value: d.actors.prefix(5).joined(separator: ", "), lines: 2)
        sloganRow.set(key: "Слоган",        value: d.slogan)
        descRow.set(key: "Описание",        value: d.description, lines: 3)
    }

    // MARK: - Meta pills builder

    private func rebuildMetaPills(year: String, isSeries: Bool,
                                  genres: [String], duration: String,
                                  quality: String, mpaa: String) {
        metaRow.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let yearText = isSeries ? "\(year)–" : year
        if !year.isEmpty && year != "—" {
            metaRow.addArrangedSubview(MetaPill(text: yearText, color: UIColor(white: 0.30, alpha: 1)))
        }

        let genreAlphas: [CGFloat] = [0.90, 0.70, 0.55]
        for (i, g) in genres.prefix(3).enumerated() where !g.isEmpty && g != "—" {
            metaRow.addArrangedSubview(MetaPill(text: g, color: movie.accentColor.withAlphaComponent(genreAlphas[i])))
        }

        if !duration.isEmpty && duration != "—" {
            metaRow.addArrangedSubview(MetaPill(text: duration, color: UIColor(white: 0.22, alpha: 1)))
        }

        if !quality.isEmpty {
            metaRow.addArrangedSubview(MetaPill(text: quality, color: UIColor(red: 0.15, green: 0.45, blue: 0.25, alpha: 0.9)))
        }

        if !mpaa.isEmpty {
            metaRow.addArrangedSubview(MetaPill(text: mpaa, color: UIColor(red: 0.6, green: 0.12, blue: 0.12, alpha: 0.85)))
        }
    }

    // MARK: - Rating badges builder

    private func rebuildRatingBadges(_ d: FilmixDetail) {
        ratingsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if d.kinopoiskRating != "—", !d.kinopoiskRating.isEmpty {
            ratingsStack.addArrangedSubview(RatingBadge(
                logo: "КП",
                logoColor: UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1),
                rating: d.kinopoiskRating,
                votes: d.kinopoiskVotes
            ))
        }

        if d.imdbRating != "—", !d.imdbRating.isEmpty {
            ratingsStack.addArrangedSubview(RatingBadge(
                logo: "IMDb",
                logoColor: UIColor(red: 0.85, green: 0.75, blue: 0.0, alpha: 1),
                rating: d.imdbRating,
                votes: d.imdbVotes
            ))
        }

        if d.userPositivePercent > 0 {
            ratingsStack.addArrangedSubview(RatingBadge(
                logo: "👍",
                logoColor: .white,
                rating: "\(d.userPositivePercent)%",
                votes: "\(d.userLikes + d.userDislikes)"
            ))
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
            tracks: movie.audioTracks,
            movieId: movie.id,
            selectedId: selectedAudio?.id
        )
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Series setup

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
            let ip = IndexPath(item: idx, section: 0)
            DispatchQueue.main.async {
                self.episodesCV.scrollToItem(at: ip, at: .top, animated: animated)
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

    // MARK: - Actions

    @objc private func playTapped() {
        // TODO: open player
        let alert = UIAlertController(
            title: "▶  Воспроизведение",
            message: movie.title,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView DataSource / Delegate

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

// MARK: - DetailInfoRow
// Key: Value row that hides itself when value is empty.

final class DetailInfoRow: UIView {

    private let keyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        l.textColor = UIColor(white: 0.40, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        l.textColor = UIColor(white: 0.75, alpha: 1)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(keyLabel)
        addSubview(valueLabel)
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyLabel.firstBaselineAnchor.constraint(equalTo: valueLabel.firstBaselineAnchor),
            keyLabel.widthAnchor.constraint(equalToConstant: 160),

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

// MARK: - ThinLine — hairline separator for infoStack

final class ThinLine: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.08)
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - RatingBadge

private final class RatingBadge: UIView {

    init(logo: String, logoColor: UIColor, rating: String, votes: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor   = UIColor(white: 1, alpha: 0.08)
        layer.cornerRadius = 10
        layer.cornerCurve  = .continuous

        let logoLabel = UILabel()
        logoLabel.text      = logo
        logoLabel.font      = UIFont.systemFont(ofSize: 17, weight: .heavy)
        logoLabel.textColor = logoColor
        logoLabel.translatesAutoresizingMaskIntoConstraints = false

        let ratingLabel = UILabel()
        ratingLabel.text      = rating
        ratingLabel.font      = UIFont.systemFont(ofSize: 22, weight: .heavy)
        ratingLabel.textColor = .white
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false

        let votesLabel = UILabel()
        votesLabel.text      = votes.isEmpty ? "" : "(\(Self.formatVotes(votes)))"
        votesLabel.font      = UIFont.systemFont(ofSize: 16, weight: .regular)
        votesLabel.textColor = UIColor(white: 0.45, alpha: 1)
        votesLabel.translatesAutoresizingMaskIntoConstraints = false

        let col = UIStackView(arrangedSubviews: [ratingLabel, votesLabel])
        col.axis    = .vertical
        col.spacing = 1
        col.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [logoLabel, col])
        row.axis      = .horizontal
        row.spacing   = 8
        row.alignment = .center
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

    /// "12844" → "12.8K",  "1200000" → "1.2M"
    private static func formatVotes(_ raw: String) -> String {
        guard let n = Int(raw.replacingOccurrences(of: " ", with: "")) else { return raw }
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:     return String(format: "%.1fK", Double(n) / 1_000)
        default:           return "\(n)"
        }
    }
}
