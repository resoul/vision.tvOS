import UIKit

final class MovieDetailViewController: BaseDetailViewController {

    private var translations: [FilmixTranslation] = []
    private var translationRowViews: [TranslationRow] = []
    private var activeTranslation: FilmixTranslation?

    // MARK: - Resume banner (показывается если есть незавершённый прогресс)

    private lazy var resumeBanner: ResumeBannerView = {
        let v = ResumeBannerView()
        v.isHidden = true
        v.onResume = { [weak self] in self?.resumePlayback() }
        v.onClear  = { [weak self] in self?.clearProgress() }
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Views

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

    private let bottomSpacer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildMovieLayout()
        fetchTranslations()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshResumeBanner()
    }

    // MARK: - Layout

    private func buildMovieLayout() {
        contentView.addSubview(resumeBanner)
        contentView.addSubview(translationsDivider)
        contentView.addSubview(translationsSpinner)
        contentView.addSubview(translationsStack)
        contentView.addSubview(bottomSpacer)

        NSLayoutConstraint.activate([
            // Resume banner сразу под myListBtn
            resumeBanner.topAnchor.constraint(equalTo: myListBtn.bottomAnchor, constant: 20),
            resumeBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            resumeBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),

            translationsDivider.topAnchor.constraint(equalTo: resumeBanner.bottomAnchor, constant: 20),
            translationsDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            translationsDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            translationsDivider.heightAnchor.constraint(equalToConstant: 1),

            translationsSpinner.topAnchor.constraint(equalTo: translationsDivider.bottomAnchor, constant: 24),
            translationsSpinner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),

            translationsStack.topAnchor.constraint(equalTo: translationsDivider.bottomAnchor, constant: 16),
            translationsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            translationsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),

            bottomSpacer.topAnchor.constraint(equalTo: translationsStack.bottomAnchor),
            bottomSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 80),
            bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Resume Banner

    private func refreshResumeBanner() {
        guard let progress = PlaybackStore.shared.movieProgress(movieId: movie.id),
              progress.hasProgress
        else {
            resumeBanner.isHidden = true
            return
        }
        resumeBanner.configure(progress: progress)
        resumeBanner.isHidden = false
    }

    private func resumePlayback() {
        guard let progress = PlaybackStore.shared.movieProgress(movieId: movie.id),
              let url     = progress.streamURL,
              let studio  = progress.studio,
              let quality = progress.quality
        else { return }
        playMovie(url: url, title: movie.title, studio: studio, quality: quality)
    }

    private func clearProgress() {
        PlaybackStore.shared.clearMovieProgress(movieId: movie.id)
        UIView.animate(withDuration: 0.2) { self.resumeBanner.isHidden = true }
    }

    // MARK: - Translations

    private func fetchTranslations() {
        guard movie.id > 0 else { return }
        translationsSpinner.startAnimating()
        FilmixService.shared.fetchPlayerData(postId: movie.id, isSeries: false) { [weak self] result in
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

        let picker = QualityPickerViewController(
            translation: t,
            accentColor: movie.accentColor.lighter(by: 0.5)
        )
        picker.onSelect = { [weak self] quality, url in
            guard let self else { return }
            self.playMovie(url: url, title: self.movie.title, studio: t.studio, quality: quality)
        }
        present(picker, animated: true)
    }
}

// MARK: - ResumeBannerView

final class ResumeBannerView: UIView {

    var onResume: (() -> Void)?
    var onClear:  (() -> Void)?

    private let progressBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.23, green: 0.62, blue: 0.96, alpha: 1)
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let trackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var progressWidthConstraint: NSLayoutConstraint!

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var resumeBtn: DetailButton = {
        let b = DetailButton(title: "▶  Продолжить", style: .primary)
        b.addTarget(self, action: #selector(resumeTapped), for: .primaryActionTriggered)
        return b
    }()

    private lazy var clearBtn: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Начать сначала"
        config.baseForegroundColor = UIColor(white: 0.45, alpha: 1)
        config.buttonSize = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(clearTapped), for: .primaryActionTriggered)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        let bg = UIView()
        bg.backgroundColor = UIColor(white: 1, alpha: 0.06)
        bg.layer.cornerRadius = 16; bg.layer.cornerCurve = .continuous
        bg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bg)

        bg.addSubview(trackView)
        trackView.addSubview(progressBar)
        bg.addSubview(timeLabel)
        bg.addSubview(resumeBtn)
        bg.addSubview(clearBtn)

        progressWidthConstraint = progressBar.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),

            trackView.topAnchor.constraint(equalTo: bg.topAnchor),
            trackView.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
            trackView.heightAnchor.constraint(equalToConstant: 4),

            progressBar.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            progressBar.topAnchor.constraint(equalTo: trackView.topAnchor),
            progressBar.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            progressWidthConstraint,

            timeLabel.topAnchor.constraint(equalTo: trackView.bottomAnchor, constant: 18),
            timeLabel.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 24),

            resumeBtn.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 14),
            resumeBtn.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 24),
            resumeBtn.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -20),

            clearBtn.centerYAnchor.constraint(equalTo: resumeBtn.centerYAnchor),
            clearBtn.leadingAnchor.constraint(equalTo: resumeBtn.trailingAnchor, constant: 16),
        ])
    }

    func configure(progress: PlaybackProgress) {
        let pos = Int(progress.positionSeconds)
        let dur = Int(progress.durationSeconds)
        let posStr = formatTime(pos)
        let durStr = formatTime(dur)
        timeLabel.text = "Просмотрено \(posStr) из \(durStr)"

        layoutIfNeeded()
        let w = trackView.bounds.width * CGFloat(progress.fraction)
        progressWidthConstraint.constant = w
        UIView.animate(withDuration: 0.3) { self.layoutIfNeeded() }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    @objc private func resumeTapped() { onResume?() }
    @objc private func clearTapped()  { onClear?() }
}
