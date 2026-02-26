import UIKit

final class MovieDetailViewController: BaseDetailViewController {

    private var translations: [FilmixTranslation] = []
    private var activeTranslation: FilmixTranslation?
    private var translationRowViews: [MovieTranslationRow] = []

    // MARK: - Panel views

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
        qualityButton.configure(quality: SeriesPickerStore.shared.globalPreferredQuality)
//        fetchTranslations()
    }

    // MARK: - Layout

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
    
    override func onDetailLoaded(_ detail: FilmixDetail) {
        if detail.isNotMovie {
            translationsSpinner.stopAnimating()
            emptyLabel.text = "Видео недоступно"
            emptyLabel.isHidden = false
        } else {
            fetchTranslations()
        }
    }

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
                    self.buildRows()
                default:
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    private func buildRows() {
        translationsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        translationRowViews.removeAll()
        emptyLabel.isHidden = true

        guard let t = activeTranslation else { emptyLabel.isHidden = false; return }

        let preferredQuality = SeriesPickerStore.shared.globalPreferredQuality
        let order = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]

        if let preferred = preferredQuality, let url = t.streams[preferred] {
            addRow(studio: t.studio, quality: preferred, url: url, accentColor: movie.accentColor.lighter(by: 0.5))
        } else {
            let qualities = order.filter { t.streams[$0] != nil }
            if qualities.isEmpty { emptyLabel.isHidden = false; return }
            for quality in qualities {
                guard let url = t.streams[quality] else { continue }
                addRow(studio: t.studio, quality: quality, url: url, accentColor: movie.accentColor.lighter(by: 0.5))
            }
        }
    }

    private func addRow(studio: String, quality: String, url: String, accentColor: UIColor) {
        let row = MovieTranslationRow(studio: studio, quality: quality, accentColor: accentColor)
        row.onPlay = { [weak self] in
            self?.playMovie(url: url, title: self?.movie.title ?? "",
                            studio: studio, quality: quality)
        }
        translationsStack.addArrangedSubview(row)
        translationRowViews.append(row)
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
            self.buildRows()
        }
        present(picker, animated: true)
    }

    // MARK: - Quality Picker

    private func showQualityPicker() {
        let allQualities = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let picker = GlobalQualityPickerViewController(
            qualities: allQualities,
            current: SeriesPickerStore.shared.globalPreferredQuality
        )
        picker.onSelect = { [weak self] quality in
            guard let self else { return }
            SeriesPickerStore.shared.globalPreferredQuality = quality
            self.qualityButton.configure(quality: quality)
            self.buildRows()
        }
        present(picker, animated: true)
    }
}
