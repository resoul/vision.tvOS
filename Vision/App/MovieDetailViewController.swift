import UIKit

final class MovieDetailViewController: BaseDetailViewController {

    private var translations: [FilmixTranslation] = []
    private var activeTranslation: FilmixTranslation?
    private var translationRowViews: [MovieTranslationRow] = []

    // MARK: - Panel views (same structure as SerieDetailViewController)

    private let panelDivider: UIView = {
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

    private let tabSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let translationsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Нет доступных озвучек"
        l.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildMovieLayout()
        qualityButton.configure(quality: SeriesPickerStore.shared.globalPreferredQuality ?? "Авто")
        fetchTranslations()
    }

    // MARK: - Layout (mirrors SerieDetailViewController.buildSerieLayout)

    private func buildMovieLayout() {
        contentView.addSubview(panelDivider)
        contentView.addSubview(controlBar)
        controlBar.addSubview(studioPicker)
        controlBar.addSubview(translationsSpinner)
        controlBar.addSubview(qualityButton)
        contentView.addSubview(tabSeparator)
        contentView.addSubview(translationsStack)
        contentView.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            panelDivider.topAnchor.constraint(equalTo: myListBtn.bottomAnchor, constant: 28),
            panelDivider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            panelDivider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            panelDivider.heightAnchor.constraint(equalToConstant: 1),

            controlBar.topAnchor.constraint(equalTo: panelDivider.bottomAnchor, constant: 20),
            controlBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            controlBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            controlBar.heightAnchor.constraint(equalToConstant: 54),

            studioPicker.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor),
            studioPicker.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            translationsSpinner.leadingAnchor.constraint(equalTo: studioPicker.trailingAnchor, constant: 16),
            translationsSpinner.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            qualityButton.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor),
            qualityButton.centerYAnchor.constraint(equalTo: controlBar.centerYAnchor),

            tabSeparator.topAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: 12),
            tabSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset),
            tabSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -hInset),
            tabSeparator.heightAnchor.constraint(equalToConstant: 1),

            translationsStack.topAnchor.constraint(equalTo: tabSeparator.bottomAnchor, constant: 12),
            translationsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: hInset - 4),
            translationsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -(hInset - 4)),
            translationsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60),

            emptyLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: tabSeparator.bottomAnchor, constant: 60),
        ])
    }

    // MARK: - Fetch

    private func fetchTranslations() {
        guard movie.id > 0 else { emptyLabel.isHidden = false; return }
        translationsSpinner.startAnimating()

        FilmixService.shared.fetchPlayerData(postId: movie.id, isSeries: false) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.translationsSpinner.stopAnimating()
                switch result {
                case .success(let list) where !list.isEmpty:
                    self.translations = list
                    self.activeTranslation = list.first
                    self.studioPicker.configure(studio: list.first?.studio ?? "")
                    self.buildTranslationRows()
                default:
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
            self.buildTranslationRows()
        }
        present(picker, animated: true)
    }

    // MARK: - Build rows (one row per quality, like episodes)

    private func buildTranslationRows() {
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        translationRowViews.removeAll()
        emptyLabel.isHidden = true

        guard let t = activeTranslation else { emptyLabel.isHidden = false; return }

        let order = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let qualities = order.filter { t.streams[$0] != nil }

        if qualities.isEmpty { emptyLabel.isHidden = false; return }

        for quality in qualities {
            guard let url = t.streams[quality] else { continue }
            let row = MovieTranslationRow(
                studio: t.studio,
                quality: quality,
                url: url,
                accentColor: movie.accentColor.lighter(by: 0.5)
            )
            row.onPlay = { [weak self] in
                self?.playMovie(url: url, title: self?.movie.title ?? "",
                                studio: t.studio, quality: quality)
            }
            translationsStack.addArrangedSubview(row)
            translationRowViews.append(row)
        }
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
            self?.qualityButton.configure(quality: quality ?? "Авто")
        }
        present(picker, animated: true)
    }
}

// MARK: - MovieTranslationRow
// Выглядит и ведёт себя как EpisodeMainControl — одна строка = один вариант качества

final class MovieTranslationRow: UIView {

    var onPlay: (() -> Void)?

    private let accentColor: UIColor

    private let bg: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.05)
        v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let accentLine: UIView = {
        let v = UIView(); v.layer.cornerRadius = 2; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let studioLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let qualityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let playIcon: UILabel = {
        let l = UILabel(); l.text = "▶"
        l.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    init(studio: String, quality: String, url: String, accentColor: UIColor) {
        self.accentColor = accentColor
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        accentLine.backgroundColor = accentColor
        studioLabel.text = studio
        qualityLabel.text = quality

        addSubview(bg); addSubview(accentLine)
        addSubview(studioLabel); addSubview(qualityLabel); addSubview(playIcon)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            accentLine.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            accentLine.topAnchor.constraint(equalTo: bg.topAnchor, constant: 10),
            accentLine.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -10),
            accentLine.widthAnchor.constraint(equalToConstant: 3),

            studioLabel.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 20),
            studioLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            studioLabel.trailingAnchor.constraint(lessThanOrEqualTo: qualityLabel.leadingAnchor, constant: -16),

            qualityLabel.trailingAnchor.constraint(equalTo: playIcon.leadingAnchor, constant: -16),
            qualityLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),

            playIcon.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -20),
            playIcon.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.bg.backgroundColor = UIColor(white: 1, alpha: 0.12)
                self.accentLine.alpha = 1
                self.playIcon.textColor = self.accentColor
                self.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOpacity = 0.4
                self.layer.shadowRadius = 12
                self.layer.shadowOffset = CGSize(width: 0, height: 6)
            } else {
                self.bg.backgroundColor = UIColor(white: 1, alpha: 0.05)
                self.accentLine.alpha = 0
                self.playIcon.textColor = UIColor(white: 0.45, alpha: 1)
                self.transform = .identity
                self.layer.shadowOpacity = 0
            }
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) {
            self.bg.backgroundColor = UIColor(white: 1, alpha: 0.18)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = UIColor(white: 1, alpha: self.isFocused ? 0.12 : 0.05)
        }
        onPlay?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = UIColor(white: 1, alpha: 0.05)
        }
        super.pressesCancelled(presses, with: event)
    }
}
