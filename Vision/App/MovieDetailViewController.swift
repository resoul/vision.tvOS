import UIKit

final class MovieDetailViewController: BaseDetailViewController {

    private var translations: [FilmixTranslation] = []
    private var translationRowViews: [TranslationRow] = []
    private var activeTranslation: FilmixTranslation?

    private let upwardFocusGuide   = UIFocusGuide()
    // Направляет фокус вниз из кнопок баннера (Продолжить / Начать сначала) → строки озвучки
    private let downwardFocusGuide = UIFocusGuide()

    // MARK: - Resume banner

    private lazy var resumeBanner: ResumeBannerView = {
        let v = ResumeBannerView()
        v.isHidden = true
        v.onResume = { [weak self] in self?.resumePlayback() }
        v.onClear  = { [weak self] in self?.clearProgress() }
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Translations section

    private let translationsDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.06)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let controlBar: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var translationsLabel: UILabel = {
        let l = UILabel()
        l.text = "Озвучка"
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let translationsSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.color = UIColor(white: 0.5, alpha: 1); v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var qualityButton: QualityPreferenceButton = {
        let b = QualityPreferenceButton()
        b.configure(quality: SeriesPickerStore.shared.globalPreferredQuality)
        b.onTap = { [weak self] in self?.showQualityPicker() }
        return b
    }()

    // Обычный UIStackView — теперь работает, потому что TranslationRow : UIControl
    private let translationsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 4; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    private lazy var noTranslationsLabel: UILabel = {
        let l = UILabel()
        l.text = "Нет доступных озвучек"
        l.font = UIFont.systemFont(ofSize: 22, weight: .medium)
        l.textColor = UIColor(white: 0.30, alpha: 1)
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
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
        contentView.addSubview(controlBar)
        controlBar.addSubview(translationsLabel)
        controlBar.addSubview(translationsSpinner)
        controlBar.addSubview(qualityButton)
        contentView.addSubview(translationsStack)
        contentView.addSubview(noTranslationsLabel)
        contentView.addSubview(bottomSpacer)

        contentView.addLayoutGuide(upwardFocusGuide)
        contentView.addLayoutGuide(downwardFocusGuide)
        upwardFocusGuide.preferredFocusEnvironments   = [myListBtn]
        downwardFocusGuide.preferredFocusEnvironments = []   // заполняется в buildTranslationRows

        NSLayoutConstraint.activate([
            resumeBanner.topAnchor.constraint(equalTo: myListBtn.bottomAnchor, constant: 20),
            resumeBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            resumeBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),

            // downwardFocusGuide — полная ширина, прямо под баннером.
            // Когда фокус на кнопках баннера и пользователь свайпает вниз —
            // движок попадает в этот гайд и редиректится на первую строку озвучки.
            downwardFocusGuide.topAnchor.constraint(equalTo: resumeBanner.bottomAnchor),
            downwardFocusGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            downwardFocusGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            downwardFocusGuide.heightAnchor.constraint(equalToConstant: 1),

            translationsDivider.topAnchor.constraint(equalTo: resumeBanner.bottomAnchor, constant: 20),
            translationsDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            translationsDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            translationsDivider.heightAnchor.constraint(equalToConstant: 1),

            controlBar.topAnchor.constraint(equalTo: translationsDivider.bottomAnchor, constant: 20),
            controlBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            controlBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            controlBar.heightAnchor.constraint(equalToConstant: 44),

            translationsLabel.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor),
            translationsLabel.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            translationsSpinner.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),
            translationsSpinner.leadingAnchor.constraint(equalTo: translationsLabel.trailingAnchor, constant: 12),

            qualityButton.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor),
            qualityButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            translationsStack.topAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: 12),
            translationsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            translationsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),

            noTranslationsLabel.topAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: 16),
            noTranslationsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),

            upwardFocusGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            upwardFocusGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            upwardFocusGuide.bottomAnchor.constraint(equalTo: translationsStack.topAnchor),
            upwardFocusGuide.heightAnchor.constraint(equalToConstant: 1),

            bottomSpacer.topAnchor.constraint(equalTo: translationsStack.bottomAnchor),
            bottomSpacer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSpacer.heightAnchor.constraint(equalToConstant: 80),
            bottomSpacer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Focus

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if let focused = context.nextFocusedItem as? TranslationRow {
            let isFirst = translationRowViews.first === focused
            upwardFocusGuide.preferredFocusEnvironments = isFirst ? [myListBtn] : []
        } else if context.nextFocusedItem is QualityPreferenceButton {
            upwardFocusGuide.preferredFocusEnvironments = [myListBtn]
        }
    }

    // MARK: - Resume Banner

    private func refreshResumeBanner() {
        guard let progress = PlaybackStore.shared.movieProgress(movieId: movie.id),
              progress.hasProgress
        else { resumeBanner.isHidden = true; return }
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

    // MARK: - Quality Picker

    private func showQualityPicker() {
        let allQualities = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let picker = GlobalQualityPickerViewController(
            qualities: allQualities,
            current: SeriesPickerStore.shared.globalPreferredQuality
        )
        picker.onSelect = { [weak self] quality in
            SeriesPickerStore.shared.globalPreferredQuality = quality
            self?.qualityButton.configure(quality: quality)
        }
        present(picker, animated: true)
    }

    // MARK: - Translations

    private func fetchTranslations() {
        let postId = movie.id
        guard postId > 0 else { showNoTranslations(); return }
        translationsSpinner.startAnimating()
        translationsLabel.text = "Загрузка озвучки…"

        FilmixService.shared.fetchPlayerData(postId: postId, isSeries: false) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.translationsSpinner.stopAnimating()
                self.translationsLabel.text = "Озвучка"
                switch result {
                case .success(let list):
                    list.isEmpty ? self.showNoTranslations() : self.buildTranslationRows(list)
                case .failure(let error):
                    self.noTranslationsLabel.text = "Ошибка: \(error.localizedDescription)"
                    self.noTranslationsLabel.isHidden = false
                }
            }
        }
    }

    private func showNoTranslations() {
        noTranslationsLabel.isHidden = false
    }

    private func buildTranslationRows(_ list: [FilmixTranslation]) {
        translations = list
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        translationRowViews.removeAll()
        noTranslationsLabel.isHidden = true

        for t in translations {
            let row = TranslationRow(translation: t, accentColor: movie.accentColor.lighter(by: 0.5))
            row.onSelect = { [weak self] picked in self?.translationRowTapped(picked) }
            translationsStack.addArrangedSubview(row)
            translationRowViews.append(row)
        }

        activeTranslation = translations.first
        translationRowViews.first?.isActive = true
        upwardFocusGuide.preferredFocusEnvironments   = [myListBtn]
        // Направляем свайп вниз из баннера на первую строку озвучки
        downwardFocusGuide.preferredFocusEnvironments = translationRowViews.first.map { [$0] } ?? []
    }

    // MARK: - Playback

    private func translationRowTapped(_ t: FilmixTranslation) {
        activeTranslation = t
        translationRowViews.forEach { $0.isActive = ($0.translation.studio == t.studio) }

        let preferred = SeriesPickerStore.shared.globalPreferredQuality
        if let pref = preferred, let url = t.streams[pref] {
            playMovie(url: url, title: movie.title, studio: t.studio, quality: pref)
        } else if preferred != nil {
            showFallbackQualityPicker(translation: t)
        } else if t.sortedQualities.count == 1, let q = t.bestQuality, let url = t.bestURL {
            playMovie(url: url, title: movie.title, studio: t.studio, quality: q)
        } else {
            showFullQualityPicker(translation: t)
        }
    }

    private func showFullQualityPicker(translation t: FilmixTranslation) {
        let picker = QualityPickerViewController(translation: t,
                                                  accentColor: movie.accentColor.lighter(by: 0.5))
        picker.onSelect = { [weak self] quality, url in
            guard let self else { return }
            self.playMovie(url: url, title: self.movie.title, studio: t.studio, quality: quality)
        }
        present(picker, animated: true)
    }

    private func showFallbackQualityPicker(translation t: FilmixTranslation) {
        let available = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
            .filter { t.streams[$0] != nil }
        let picker = GlobalQualityPickerViewController(qualities: available, current: nil,
            title: "Качество недоступно",
            subtitle: "Предпочитаемое качество отсутствует. Выберите из доступных:")
        picker.onSelect = { [weak self] quality in
            guard let self, let key = quality, let url = t.streams[key] else { return }
            self.playMovie(url: url, title: self.movie.title, studio: t.studio, quality: key)
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
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let trackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private var progressWidthConstraint: NSLayoutConstraint!

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
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
        b.translatesAutoresizingMaskIntoConstraints = false; return b
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
        timeLabel.text = "Просмотрено \(formatTime(pos)) из \(formatTime(dur))"
        layoutIfNeeded()
        let w = trackView.bounds.width * CGFloat(progress.fraction)
        progressWidthConstraint.constant = w
        UIView.animate(withDuration: 0.3) { self.layoutIfNeeded() }
    }

    private func formatTime(_ s: Int) -> String {
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }

    @objc private func resumeTapped() { onResume?() }
    @objc private func clearTapped()  { onClear?() }
}
