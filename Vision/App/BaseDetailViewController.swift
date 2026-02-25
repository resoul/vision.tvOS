import UIKit
import AVKit

class BaseDetailViewController: UIViewController {

    let movie: Movie

    /// Called after the VC is dismissed — used by MainController to refresh favorites
    var onDismiss: (() -> Void)?

    // MARK: - State

    var detail: FilmixDetail?

    // MARK: - Background

    lazy var backdropIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 1920, height: 1080))
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0.94; v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Scroll

    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    lazy var contentView: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    // MARK: - Top zone

    lazy var posterIV: UIImageView = {
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

    lazy var accentStripe: UIView = {
        let v = UIView()
        v.backgroundColor = movie.accentColor.lighter(by: 0.5)
        v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = movie.title
        l.font = UIFont.systemFont(ofSize: 48, weight: .heavy)
        l.textColor = .white; l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true; l.minimumScaleFactor = 0.70
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    lazy var originalTitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1); l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    lazy var metaRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 8; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    let ratingsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 10; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    let countryRow  = DetailInfoRow()
    let directorRow = DetailInfoRow()
    let writerRow   = DetailInfoRow()
    let actorsRow   = DetailInfoRow()
    let sloganRow   = DetailInfoRow()
    let descDivider = ThinLine()
    let descRow     = DetailInfoRow()

    let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 10; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    let detailSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1); v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Bottom shared

    let bottomDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    lazy var myListBtn: DetailButton = {
        let b = DetailButton(title: favoriteButtonTitle(), style: .secondary)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(toggleFavorite), for: .primaryActionTriggered)
        return b
    }()

    // MARK: - Layout constants

    let lInset:  CGFloat = 64
    let hInset:  CGFloat = 80
    let posterW: CGFloat = 290
    var posterH: CGFloat { posterW * 313 / 220 }
    var topZoneH: CGFloat { posterH + 120 }
    var rightX: CGFloat { lInset + posterW + 28 + 4 + 24 }

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
        buildBaseLayout()
        populateFromListing()
        fetchDetail()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed { onDismiss?() }
    }

    // MARK: - Favorites

    private func favoriteButtonTitle() -> String {
        FavoritesStore.shared.isFavorite(id: movie.id)
            ? "✓  В избранном"
            : "+  Добавить в избранное"
    }

    @objc private func toggleFavorite() {
        FavoritesStore.shared.toggle(movie)
        updateFavoriteButton(animated: true)
    }

    private func updateFavoriteButton(animated: Bool) {
        let title = favoriteButtonTitle()
        let update = {
            var config = self.myListBtn.configuration ?? UIButton.Configuration.plain()
            config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold)
            ]))
            self.myListBtn.configuration = config
        }
        if animated {
            UIView.transition(with: myListBtn, duration: 0.20, options: .transitionCrossDissolve, animations: update)
        } else {
            update()
        }
    }

    // MARK: - Base Layout

    func buildBaseLayout() {
        view.addSubview(backdropIV)
        view.addSubview(backdropBlur)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

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

            bottomDivider.topAnchor.constraint(equalTo: topZone.bottomAnchor),
            bottomDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            bottomDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            bottomDivider.heightAnchor.constraint(equalToConstant: 1),

            myListBtn.topAnchor.constraint(equalTo: bottomDivider.bottomAnchor, constant: 28),
            myListBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
        ])
    }

    // MARK: - Data Population

    func populateFromListing() {
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

    func fetchDetail() {
        guard !movie.movieURL.isEmpty else { return }
        detailSpinner.startAnimating()
        FilmixService.shared.fetchDetail(path: movie.movieURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.detailSpinner.stopAnimating()
                if case .success(let d) = result {
                    self.detail = d
                    self.populateFromDetail(d)
                    self.onDetailLoaded(d)
                }
            }
        }
    }

    func populateFromDetail(_ d: FilmixDetail) {
        if !d.posterFull.isEmpty {
            posterIV.setPoster(url: d.posterFull,
                               placeholder: PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782)))
        }
        if !d.originalTitle.isEmpty && d.originalTitle != d.title {
            originalTitleLabel.text = d.originalTitle
            originalTitleLabel.isHidden = false
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

    func onDetailLoaded(_ detail: FilmixDetail) {}

    // MARK: - Meta Helpers

    func rebuildMetaPills(year: String, isSeries: Bool, genres: [String],
                          duration: String, quality: String, mpaa: String) {
        metaRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let yt = isSeries ? "\(year)–" : year
        if !year.isEmpty && year != "—" {
            metaRow.addArrangedSubview(Pill(text: yt, color: UIColor(white: 0.28, alpha: 1)))
        }
        for (i, g) in genres.prefix(3).enumerated() where !g.isEmpty && g != "—" {
            let a: CGFloat = [0.90, 0.70, 0.55][i]
            metaRow.addArrangedSubview(Pill(text: g, color: movie.accentColor.withAlphaComponent(a)))
        }
        if !duration.isEmpty && duration != "—" {
            metaRow.addArrangedSubview(Pill(text: duration, color: UIColor(white: 0.20, alpha: 1)))
        }
        if !quality.isEmpty {
            metaRow.addArrangedSubview(Pill(text: quality,
                color: UIColor(red: 0.12, green: 0.42, blue: 0.22, alpha: 0.9)))
        }
        if !mpaa.isEmpty {
            metaRow.addArrangedSubview(Pill(text: mpaa,
                color: UIColor(red: 0.55, green: 0.10, blue: 0.10, alpha: 0.85)))
        }
    }

    func rebuildRatingBadges(_ d: FilmixDetail) {
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

    // MARK: - Playback (Movie)

    /// Запустить фильм. Если есть сохранённый прогресс — продолжить с него.
    func playMovie(url: String, title: String, studio: String, quality: String) {
        let resumePos = PlaybackStore.shared.movieProgress(movieId: movie.id)?.positionSeconds ?? 0
        let ctx = PlaybackContext.movie(
            movieId:   movie.id,
            studio:    studio,
            quality:   quality,
            streamURL: url
        )
        let vc = PlaybackViewController(context: ctx, resumePosition: resumePos)
        present(vc, animated: true)
    }

    // MARK: - Factory

    static func make(movie: Movie) -> BaseDetailViewController {
        return movie.type.isSeries
            ? SerieDetailViewController(movie: movie)
            : MovieDetailViewController(movie: movie)
    }
}
