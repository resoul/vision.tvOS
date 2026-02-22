import UIKit
import AVKit

// MARK: - QualityPickerViewController

final class QualityPickerViewController: UIViewController {

    var onSelect: ((String, String) -> Void)?

    private let translation: FilmixTranslation
    private let accentColor: UIColor

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24; v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.85; v.layer.shadowRadius = 60
        v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Качество"
        l.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var qualityStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    init(translation: FilmixTranslation, accentColor: UIColor) {
        self.translation = translation
        self.accentColor = accentColor
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(qualityStack)

        subtitleLabel.text = translation.studio

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 580),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            qualityStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            qualityStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            qualityStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            qualityStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32),
        ])

        for key in translation.sortedQualities {
            guard let url = translation.streams[key] else { continue }
            let capturedKey = key
            let capturedURL = url
            let row = QualityPickerRow(quality: key, accentColor: accentColor)
            row.onSelect = { [weak self] in
                self?.dismiss(animated: true) {
                    self?.onSelect?(capturedKey, capturedURL)
                }
            }
            qualityStack.addArrangedSubview(row)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [qualityStack.arrangedSubviews.first].compactMap { $0 }
    }
}

// MARK: - QualityPickerRow

final class QualityPickerRow: UIView {

    var onSelect: (() -> Void)?

    private let qualityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let resolutionLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let playIcon: UILabel = {
        let l = UILabel()
        l.text = "▶"
        l.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(quality: String, accentColor: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        addSubview(bgView); addSubview(qualityLabel)
        addSubview(resolutionLabel); addSubview(playIcon)

        qualityLabel.text    = quality
        resolutionLabel.text = Self.hint(for: quality)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            qualityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            qualityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            resolutionLabel.leadingAnchor.constraint(equalTo: qualityLabel.trailingAnchor, constant: 12),
            resolutionLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            playIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            playIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private static func hint(for q: String) -> String {
        switch q {
        case "4K UHD":       return "3840×2160"
        case "1080p Ultra+": return "1920×1080 HDR"
        case "1080p":        return "1920×1080"
        case "720p":         return "1280×720"
        case "480p":         return "854×480"
        case "360p":         return "640×360"
        default:             return ""
        }
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20) : .clear
            self.playIcon.textColor = self.isFocused
                ? UIColor(white: 0.85, alpha: 1) : UIColor(white: 0.35, alpha: 1)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.03, y: 1.03) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .select }) {
            UIView.animate(withDuration: 0.07) {
                self.bgView.backgroundColor = UIColor(white: 1, alpha: 0.30)
            }
        } else {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .select }) {
            UIView.animate(withDuration: 0.10) {
                self.bgView.backgroundColor = UIColor(white: 1, alpha: 0.20)
            }
            onSelect?()
        } else {
            super.pressesEnded(presses, with: event)
        }
    }
}

// MARK: - MovieDetailViewController

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
    private lazy var audioTabButton: AudioTabButton = {
        let b = AudioTabButton()
        b.accentColor = movie.accentColor.lighter(by: 0.5)
        b.addTarget(self, action: #selector(audioTapped), for: .primaryActionTriggered); return b
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
        setupAudio()
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
        let picker = QualityPickerViewController(
            translation: t, accentColor: movie.accentColor.lighter(by: 0.5))
        picker.onSelect = { [weak self] quality, url in
            guard let self else { return }
            self.playVideo(url: url, title: "\(self.movie.title) · \(t.studio) · \(quality)")
        }
        present(picker, animated: true)
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

    private func setupAudio() {
        let savedId = WatchStore.shared.selectedAudioId(movieId: movie.id)
        selectedAudio = movie.audioTracks.first { $0.id == savedId } ?? movie.audioTracks.first
        audioTabButton.configure(with: selectedAudio)
    }

    @objc private func audioTapped() {
        let picker = AudioTrackPickerViewController(
            tracks: movie.audioTracks, movieId: movie.id, selectedId: selectedAudio?.id)
        picker.delegate = self; present(picker, animated: true)
    }

    private func setupSeriesIfNeeded() {
        guard case .series(let seasons) = movie.type else { return }
        episodesPanelContainer.isHidden = false
        for (i, season) in seasons.enumerated() {
            let btn = SeasonTabButton(season: season)
            btn.accentColor = movie.accentColor.lighter(by: 0.5)
            btn.isActiveSeason = (i == 0); btn.tag = i
            btn.addTarget(self, action: #selector(seasonTapped(_:)), for: .primaryActionTriggered)
            seasonTabsStack.addArrangedSubview(btn); seasonTabButtons.append(btn)
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

extension MovieDetailViewController: AudioTrackPickerDelegate {
    func audioPicker(_ picker: AudioTrackPickerViewController, didSelect track: AudioTrack) {
        selectedAudio = track; audioTabButton.configure(with: selectedAudio)
    }
}

// MARK: - TranslationRow

final class TranslationRow: UIView {

    let translation: FilmixTranslation
    var onSelect: ((FilmixTranslation) -> Void)?
    var isActive: Bool = false { didSet { updateLook(animated: true) } }

    private let dot: UIView = {
        let v = UIView(); v.layer.cornerRadius = 3.5; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let studioLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let qualityHint: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        l.textColor = UIColor(white: 0.32, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let chevron: UILabel = {
        let l = UILabel(); l.text = "›"
        l.font = UIFont.systemFont(ofSize: 30, weight: .light)
        l.textColor = UIColor(white: 0.25, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bg: UIView = {
        let v = UIView(); v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(translation: FilmixTranslation, accentColor: UIColor) {
        self.translation = translation
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 62).isActive = true
        dot.backgroundColor = accentColor

        addSubview(bg); addSubview(dot)
        addSubview(studioLabel); addSubview(qualityHint); addSubview(chevron)

        studioLabel.text = translation.studio
        if let best = translation.bestQuality { qualityHint.text = "до \(best)" }

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 7),
            dot.heightAnchor.constraint(equalToConstant: 7),

            studioLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34),
            studioLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            qualityHint.leadingAnchor.constraint(equalTo: studioLabel.trailingAnchor, constant: 16),
            qualityHint.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let block = {
            self.bg.backgroundColor    = self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear
            self.studioLabel.textColor = self.isActive ? .white : UIColor(white: 0.55, alpha: 1)
            self.studioLabel.font      = UIFont.systemFont(ofSize: 24, weight: self.isActive ? .semibold : .medium)
            self.dot.alpha             = self.isActive ? 1 : 0
            self.chevron.textColor     = self.isActive
                ? UIColor(white: 0.55, alpha: 1) : UIColor(white: 0.25, alpha: 1)
        }
        animated ? UIView.animate(withDuration: 0.18, animations: block) : block()
    }

    // MARK: - Focus / Press (tvOS native)

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor    = self.isFocused
                ? UIColor(white: 1, alpha: 0.16)
                : (self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear)
            self.studioLabel.textColor = self.isFocused ? .white
                : (self.isActive ? .white : UIColor(white: 0.55, alpha: 1))
            self.chevron.textColor     = self.isFocused
                ? UIColor(white: 0.85, alpha: 1) : UIColor(white: 0.25, alpha: 1)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.015, y: 1.015) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) {
            self.bg.backgroundColor = UIColor(white: 1, alpha: 0.24)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.16)
                : (self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear)
        }
        onSelect?(translation)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.16)
                : (self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear)
        }
        super.pressesCancelled(presses, with: event)
    }
}

// MARK: - DetailInfoRow

final class DetailInfoRow: UIView {
    private let keyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        l.textColor = UIColor(white: 0.38, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        l.textColor = UIColor(white: 0.76, alpha: 1); l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    override init(frame: CGRect) {
        super.init(frame: frame); translatesAutoresizingMaskIntoConstraints = false
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
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        isHidden = t.isEmpty || t == "—"; guard !isHidden else { return }
        keyLabel.text = key + ":"; valueLabel.text = t; valueLabel.numberOfLines = lines
    }
}

// MARK: - ThinLine

final class ThinLine: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame); translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.07)
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - RatingBadge

private final class RatingBadge: UIView {
    init(logo: String, logoColor: UIColor, rating: String, votes: String) {
        super.init(frame: .zero); translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.07)
        layer.cornerRadius = 10; layer.cornerCurve = .continuous

        let logoLbl = UILabel(); logoLbl.text = logo
        logoLbl.font = UIFont.systemFont(ofSize: 17, weight: .heavy); logoLbl.textColor = logoColor
        logoLbl.translatesAutoresizingMaskIntoConstraints = false

        let ratingLbl = UILabel(); ratingLbl.text = rating
        ratingLbl.font = UIFont.systemFont(ofSize: 22, weight: .heavy); ratingLbl.textColor = .white
        ratingLbl.translatesAutoresizingMaskIntoConstraints = false

        let votesLbl = UILabel()
        votesLbl.text = votes.isEmpty ? "" : "(\(Self.fmt(votes)))"
        votesLbl.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        votesLbl.textColor = UIColor(white: 0.42, alpha: 1)
        votesLbl.translatesAutoresizingMaskIntoConstraints = false

        let col = UIStackView(arrangedSubviews: [ratingLbl, votesLbl])
        col.axis = .vertical; col.spacing = 1; col.translatesAutoresizingMaskIntoConstraints = false

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
        default: return "\(n)"
        }
    }
}
