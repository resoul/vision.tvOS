import UIKit

// MARK: - Models
struct Season {
    let number: Int
    let year: String
    let episodes: [Episode]
}

struct Episode {
    let number: Int
    let title: String
    let duration: String
    let description: String
}

struct AudioTrack: Equatable {
    let id: String
    let language: String
    let kind: Kind
    let flag: String

    enum Kind {
        case original
        case dubbing(studio: String)
        case voiceover(studio: String)
    }

    var displayTitle: String {
        switch kind {
        case .original:             return "\(flag)  \(language)  · Оригинал"
        case .dubbing(let s):       return "\(flag)  \(language)  · \(s)"
        case .voiceover(let s):     return "\(flag)  \(language)  · \(s) (Закадр)"
        }
    }

    static func == (lhs: AudioTrack, rhs: AudioTrack) -> Bool { lhs.id == rhs.id }
}

// MARK: - Watch State

final class WatchStore {
    static let shared = WatchStore()
    private let defaults = UserDefaults.standard

    // MARK: Watched episodes
    private func watchedKey(movieId: Int, season: Int, episode: Int) -> String {
        "watched_\(movieId)_s\(season)_e\(episode)"
    }

    func isWatched(movieId: Int, season: Int, episode: Int) -> Bool {
        defaults.bool(forKey: watchedKey(movieId: movieId, season: season, episode: episode))
    }

    func setWatched(_ watched: Bool, movieId: Int, season: Int, episode: Int) {
        defaults.set(watched, forKey: watchedKey(movieId: movieId, season: season, episode: episode))
    }

    func firstUnwatchedIndex(movieId: Int, season: Season) -> Int? {
        for (i, ep) in season.episodes.enumerated() {
            if !isWatched(movieId: movieId, season: season.number, episode: ep.number) { return i }
        }
        return nil
    }

    // MARK: Selected audio track
    private func audioKey(movieId: Int) -> String { "audio_\(movieId)" }

    func selectedAudioId(movieId: Int) -> String? {
        defaults.string(forKey: audioKey(movieId: movieId))
    }

    func setSelectedAudioId(_ id: String, movieId: Int) {
        defaults.set(id, forKey: audioKey(movieId: movieId))
    }
}

// MARK: - Sample Audio Tracks

extension AudioTrack {
    static let originalEn  = AudioTrack(id: "en_orig",  language: "English",  kind: .original,              flag: "🇺🇸")
    static let originalFr  = AudioTrack(id: "fr_orig",  language: "Français", kind: .original,              flag: "🇫🇷")
    static let rubDubbing  = AudioTrack(id: "ru_dub",   language: "Русский",  kind: .dubbing(studio: "Дублированный"),  flag: "🇷🇺")
    static let ruVoiceover = AudioTrack(id: "ru_vo",    language: "Русский",  kind: .voiceover(studio: "LostFilm"),     flag: "🇷🇺")
    static let ruAmedia    = AudioTrack(id: "ru_amedia",language: "Русский",  kind: .dubbing(studio: "Amedia"),         flag: "🇷🇺")
    static let ruCub       = AudioTrack(id: "ru_cub",   language: "Русский",  kind: .voiceover(studio: "Кубик в Кубе"), flag: "🇷🇺")
    static let deDub       = AudioTrack(id: "de_dub",   language: "Deutsch",  kind: .dubbing(studio: "Dублированный"),  flag: "🇩🇪")

    static let movieTracks: [AudioTrack] = [originalEn, rubDubbing, ruVoiceover]
    static let seriesTracks: [AudioTrack] = [originalEn, ruVoiceover, ruAmedia, ruCub]
    static let europeanTracks: [AudioTrack] = [originalFr, rubDubbing, deDub]
}

// MARK: - Audio Track Picker

protocol AudioTrackPickerDelegate: AnyObject {
    func audioPicker(_ picker: AudioTrackPickerViewController, didSelect track: AudioTrack)
}

final class AudioTrackPickerViewController: UIViewController {

    weak var delegate: AudioTrackPickerDelegate?

    private let movie: AudioTrack?          // currently selected
    private let tracks: [AudioTrack]
    private let movieId: Int
    private var selectedId: String?

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24; v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor; v.layer.shadowOpacity = 0.8
        v.layer.shadowRadius = 60; v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.text = "Озвучка"
        l.font = UIFont.systemFont(ofSize: 32, weight: .heavy); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private lazy var stackView: UIStackView = {
        let sv = UIStackView(); sv.axis = .vertical; sv.spacing = 8; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    init(tracks: [AudioTrack], movieId: Int, selectedId: String?) {
        self.tracks = tracks; self.movieId = movieId; self.selectedId = selectedId
        self.movie = tracks.first { $0.id == selectedId }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.72)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 640),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32),
        ])

        for track in tracks {
            let row = AudioTrackRow(track: track, isSelected: track.id == selectedId)
            row.onSelect = { [weak self] in self?.select(track) }
            stackView.addArrangedSubview(row)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        // focus on currently selected row
        stackView.arrangedSubviews.first(where: {
            ($0 as? AudioTrackRow)?.isCurrentlySelected == true
        }).map { [$0] } ?? [stackView.arrangedSubviews.first].compactMap { $0 }
    }

    private func select(_ track: AudioTrack) {
        selectedId = track.id
        WatchStore.shared.setSelectedAudioId(track.id, movieId: movieId)
        stackView.arrangedSubviews.forEach { ($0 as? AudioTrackRow)?.isCurrentlySelected = ($0 as? AudioTrackRow)?.trackId == track.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.dismiss(animated: true)
            self.delegate?.audioPicker(self, didSelect: track)
        }
    }
}

// MARK: - AudioTrackRow

final class AudioTrackRow: UIControl {

    let trackId: String
    var isCurrentlySelected: Bool { didSet { updateAppearance() } }
    var onSelect: (() -> Void)?

    private let flagLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 30); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 26, weight: .medium); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let checkIcon: UILabel = {
        let l = UILabel(); l.text = "✓"; l.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        l.textColor = .white; l.alpha = 0; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bgView: UIView = {
        let v = UIView(); v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(track: AudioTrack, isSelected: Bool) {
        self.trackId = track.id; self.isCurrentlySelected = isSelected
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        addSubview(bgView); addSubview(flagLabel); addSubview(titleLabel); addSubview(checkIcon)

        flagLabel.text = track.flag
        // Build title without flag (flag shown separately)
        switch track.kind {
        case .original:           titleLabel.text = "\(track.language)  ·  Оригинал"
        case .dubbing(let s):     titleLabel.text = "\(track.language)  ·  \(s)"
        case .voiceover(let s):   titleLabel.text = "\(track.language)  ·  \(s)  (Закадр)"
        }

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            flagLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            flagLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            checkIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            checkIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        addTarget(self, action: #selector(tapped), for: .primaryActionTriggered)
        updateAppearance()
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onSelect?() }

    private func updateAppearance() {
        bgView.backgroundColor = isCurrentlySelected ? UIColor(white: 1, alpha: 0.14) : .clear
        checkIcon.alpha = isCurrentlySelected ? 1 : 0
        titleLabel.textColor = isCurrentlySelected ? .white : UIColor(white: 0.70, alpha: 1)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20)
                : (self.isCurrentlySelected ? UIColor(white: 1, alpha: 0.14) : .clear)
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.03, y: 1.03) : .identity
        }, completion: nil)
    }

    override var canBecomeFocused: Bool { true }
}

// MARK: - Shared UI

enum DetailButtonStyle { case primary, secondary }

final class DetailButton: UIButton {
    init(title: String, style: DetailButtonStyle) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 26, bottom: 0, trailing: 26)
        config.background.backgroundColor = .clear
        switch style {
        case .primary:   config.baseForegroundColor = .black
        case .secondary: config.baseForegroundColor = .white
        }
        configuration = config
        layer.cornerRadius = 12; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true
        switch style {
        case .primary:   backgroundColor = .white
        case .secondary:
            backgroundColor = UIColor(white: 1, alpha: 0.13)
            layer.borderWidth = 1; layer.borderColor = UIColor(white: 1, alpha: 0.2).cgColor
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
            self.layer.shadowOpacity = self.isFocused ? 0.28 : 0
            self.layer.shadowColor = UIColor.white.cgColor; self.layer.shadowRadius = 16; self.layer.shadowOffset = .zero
        }, completion: nil)
    }
}

final class MetaPill: UIView {
    init(text: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = color; layer.cornerRadius = 8; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        let l = UILabel(); l.text = text; l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .white; l.translatesAutoresizingMaskIntoConstraints = false; addSubview(l)
        NSLayoutConstraint.activate([l.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                                     l.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                                     l.topAnchor.constraint(equalTo: topAnchor, constant: 6),
                                     l.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - SeasonTabButton

final class SeasonTabButton: UIButton {

    private let accentBar: UIView = {
        let v = UIView(); v.layer.cornerRadius = 2; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    var accentColor: UIColor = .white { didSet { accentBar.backgroundColor = accentColor } }
    var isActiveSeason: Bool = false { didSet { updateLook(animated: true) } }

    init(season: Season) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Season \(season.number)  ·  \(season.year)", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor(white: 0.50, alpha: 1)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 14, trailing: 20)
        config.background.backgroundColor = .clear
        configuration = config
        layer.cornerRadius = 10; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)
        NSLayoutConstraint.activate([
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            accentBar.centerXAnchor.constraint(equalTo: centerXAnchor),
            accentBar.heightAnchor.constraint(equalToConstant: 3),
            accentBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.65),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let color: UIColor = isActiveSeason ? .white : UIColor(white: 0.50, alpha: 1)
        let block = {
            var c = self.configuration ?? UIButton.Configuration.plain()
            c.baseForegroundColor = color
            self.configuration = c
            self.backgroundColor = self.isActiveSeason ? UIColor(white: 1, alpha: 0.10) : .clear
            self.accentBar.alpha = self.isActiveSeason ? 1 : 0
        }
        animated ? UIView.animate(withDuration: 0.2, animations: block) : block()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            var c = self.configuration ?? UIButton.Configuration.plain()
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
                self.backgroundColor = UIColor(white: 1, alpha: 0.14)
                c.baseForegroundColor = .white
                self.layer.shadowColor = UIColor.white.cgColor; self.layer.shadowOpacity = 0.12
                self.layer.shadowRadius = 10; self.layer.shadowOffset = .zero
            } else {
                self.transform = .identity
                self.backgroundColor = self.isActiveSeason ? UIColor(white: 1, alpha: 0.10) : .clear
                c.baseForegroundColor = self.isActiveSeason ? .white : UIColor(white: 0.50, alpha: 1)
                self.layer.shadowOpacity = 0
            }
            self.configuration = c
        }, completion: nil)
    }
}

// MARK: - AudioTabButton

final class AudioTabButton: UIControl {

    var accentColor: UIColor = .white { didSet { updateAppearance() } }

    private let flagLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 24)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let trackLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let chevron: UILabel = {
        let l = UILabel(); l.text = "⌄"; l.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let leftSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.10)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let bgView: UIView = {
        let v = UIView(); v.layer.cornerRadius = 10; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let accentBarBottom: UIView = {
        let v = UIView(); v.layer.cornerRadius = 2; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftSeparator); addSubview(bgView)
        addSubview(flagLabel); addSubview(trackLabel); addSubview(chevron)
        addSubview(accentBarBottom)

        NSLayoutConstraint.activate([
            leftSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftSeparator.widthAnchor.constraint(equalToConstant: 1),
            leftSeparator.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            leftSeparator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leftSeparator.trailingAnchor, constant: 8),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),

            flagLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            flagLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            trackLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 8),
            trackLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.leadingAnchor.constraint(equalTo: trackLabel.trailingAnchor, constant: 6),
            chevron.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),

            accentBarBottom.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            accentBarBottom.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            accentBarBottom.heightAnchor.constraint(equalToConstant: 3),
            accentBarBottom.widthAnchor.constraint(equalTo: bgView.widthAnchor, multiplier: 0.65),
        ])

        addTarget(self, action: #selector(handleTap), for: .primaryActionTriggered)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with track: AudioTrack?) {
        guard let track else { return }
        flagLabel.text = track.flag
        switch track.kind {
        case .original:         trackLabel.text = track.language
        case .dubbing(let s):   trackLabel.text = "\(track.language) · \(s)"
        case .voiceover(let s): trackLabel.text = "\(track.language) · \(s)"
        }
        accentBarBottom.backgroundColor = accentColor
    }

    private func updateAppearance() {
        accentBarBottom.backgroundColor = accentColor
    }

    @objc private func handleTap() { sendActions(for: .primaryActionTriggered) }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
                self.bgView.backgroundColor = UIColor(white: 1, alpha: 0.14)
                self.trackLabel.textColor = .white
                self.chevron.textColor = UIColor(white: 0.65, alpha: 1)
                self.accentBarBottom.alpha = 1
                self.layer.shadowColor = UIColor.white.cgColor
                self.layer.shadowOpacity = 0.10; self.layer.shadowRadius = 10; self.layer.shadowOffset = .zero
            } else {
                self.transform = .identity
                self.bgView.backgroundColor = .clear
                self.trackLabel.textColor = UIColor(white: 0.55, alpha: 1)
                self.chevron.textColor = UIColor(white: 0.35, alpha: 1)
                self.accentBarBottom.alpha = 0
                self.layer.shadowOpacity = 0
            }
        }, completion: nil)
    }

    override var canBecomeFocused: Bool { true }
}



final class EpisodeCell: UICollectionViewCell {
    static let reuseID = "EpisodeCell"

    private let thumbView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.layer.cornerRadius = 10; iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let playCircle: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 0, alpha: 0.55); v.layer.cornerRadius = 26; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let playIcon: UILabel = {
        let l = UILabel(); l.text = "▶"; l.font = UIFont.systemFont(ofSize: 26, weight: .bold); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let numberLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        l.textColor = UIColor(white: 0.40, alpha: 1); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 24, weight: .semibold); l.textColor = .white
        l.numberOfLines = 2; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let durationLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let descLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.62, alpha: 1); l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let watchedOverlay: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 0, alpha: 0.52)
        v.layer.cornerRadius = 10; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false; v.isHidden = true; return v
    }()
    private let watchedBadge: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 0.15, alpha: 0.92)
        v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false; v.isHidden = true; return v
    }()
    private let watchedIcon: UILabel = {
        let l = UILabel(); l.text = "✓"; l.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        l.textColor = UIColor(red: 0.25, green: 0.85, blue: 0.50, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let watchedLabel: UILabel = {
        let l = UILabel(); l.text = "Просмотрено"
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textColor = UIColor(white: 0.65, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let focusBorder: UIView = {
        let v = UIView(); v.backgroundColor = .clear; v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 2.5; v.layer.borderColor = UIColor.white.cgColor; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(white: 1, alpha: 0.06)
        contentView.layer.cornerRadius = 14; contentView.layer.cornerCurve = .continuous; contentView.clipsToBounds = false
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.3; layer.shadowRadius = 10; layer.shadowOffset = CGSize(width: 0, height: 6)

        contentView.addSubview(thumbView); contentView.addSubview(watchedOverlay)
        contentView.addSubview(watchedBadge); watchedBadge.addSubview(watchedIcon); watchedBadge.addSubview(watchedLabel)
        contentView.addSubview(playCircle); playCircle.addSubview(playIcon)
        contentView.addSubview(numberLabel); contentView.addSubview(titleLabel); contentView.addSubview(durationLabel)
        contentView.addSubview(descLabel); contentView.addSubview(focusBorder)

        NSLayoutConstraint.activate([
            thumbView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            thumbView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbView.widthAnchor.constraint(equalToConstant: 213),
            thumbView.heightAnchor.constraint(equalToConstant: 120),

            watchedOverlay.topAnchor.constraint(equalTo: thumbView.topAnchor),
            watchedOverlay.leadingAnchor.constraint(equalTo: thumbView.leadingAnchor),
            watchedOverlay.trailingAnchor.constraint(equalTo: thumbView.trailingAnchor),
            watchedOverlay.bottomAnchor.constraint(equalTo: thumbView.bottomAnchor),

            watchedBadge.trailingAnchor.constraint(equalTo: thumbView.trailingAnchor, constant: -8),
            watchedBadge.bottomAnchor.constraint(equalTo: thumbView.bottomAnchor, constant: -8),
            watchedBadge.heightAnchor.constraint(equalToConstant: 28),

            watchedIcon.leadingAnchor.constraint(equalTo: watchedBadge.leadingAnchor, constant: 8),
            watchedIcon.centerYAnchor.constraint(equalTo: watchedBadge.centerYAnchor),

            watchedLabel.leadingAnchor.constraint(equalTo: watchedIcon.trailingAnchor, constant: 5),
            watchedLabel.trailingAnchor.constraint(equalTo: watchedBadge.trailingAnchor, constant: -8),
            watchedLabel.centerYAnchor.constraint(equalTo: watchedBadge.centerYAnchor),

            playCircle.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor),
            playCircle.centerYAnchor.constraint(equalTo: thumbView.centerYAnchor),
            playCircle.widthAnchor.constraint(equalToConstant: 52), playCircle.heightAnchor.constraint(equalToConstant: 52),
            playIcon.centerXAnchor.constraint(equalTo: playCircle.centerXAnchor, constant: 3),
            playIcon.centerYAnchor.constraint(equalTo: playCircle.centerYAnchor),

            numberLabel.leadingAnchor.constraint(equalTo: thumbView.trailingAnchor, constant: 22),
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: numberLabel.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -16),

            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            durationLabel.topAnchor.constraint(equalTo: numberLabel.topAnchor),

            descLabel.leadingAnchor.constraint(equalTo: numberLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),

            focusBorder.topAnchor.constraint(equalTo: contentView.topAnchor),
            focusBorder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            focusBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            focusBorder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with episode: Episode, movie: Movie, isWatched: Bool) {
        numberLabel.text = "E\(episode.number)"; titleLabel.text = episode.title
        durationLabel.text = episode.duration; descLabel.text = episode.description
        thumbView.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 426, height: 240))

        let watched = isWatched
        watchedOverlay.isHidden = !watched
        watchedBadge.isHidden = !watched
        // Dim text for watched episodes
        titleLabel.alpha = watched ? 0.45 : 1.0
        numberLabel.alpha = watched ? 0.35 : 1.0
        descLabel.alpha = watched ? 0.35 : 1.0
        durationLabel.alpha = watched ? 0.35 : 1.0
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
                self.contentView.backgroundColor = UIColor(white: 1, alpha: 0.11)
                self.focusBorder.alpha = 1; self.playCircle.alpha = 1
                // Always show full alpha on focus regardless of watched state
                self.titleLabel.alpha = 1; self.numberLabel.alpha = 1
                self.descLabel.alpha = 0.8; self.durationLabel.alpha = 0.8
                self.layer.shadowOpacity = 0.7; self.layer.shadowRadius = 20
            } else {
                self.transform = .identity; self.contentView.backgroundColor = UIColor(white: 1, alpha: 0.06)
                self.focusBorder.alpha = 0; self.playCircle.alpha = 0
                self.layer.shadowOpacity = 0.3; self.layer.shadowRadius = 10
                // Re-apply watched dimming
                let watched = !self.watchedOverlay.isHidden
                self.titleLabel.alpha = watched ? 0.45 : 1.0
                self.numberLabel.alpha = watched ? 0.35 : 1.0
                self.descLabel.alpha = watched ? 0.35 : 1.0
                self.durationLabel.alpha = watched ? 0.35 : 1.0
            }
        }, completion: nil)
    }
}

// MARK: - MainController

final class MainController: UIViewController {

    // MARK: - State

    private var movies: [Movie] = []
    private var currentFocusedMovieId: Int? = nil
    private var detailDebounceTimer: Timer?
    private var pendingMovie: Movie?

    // Пагинация
    private var nextPageURL: URL? = nil
    private var isFetching = false
    private var hasLoadedFirstPage = false

    // MARK: - Background

    private lazy var backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.alpha = 0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let vignetteLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.type = .radial
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.70).cgColor]
        l.startPoint = CGPoint(x: 0.5, y: 0.5)
        l.endPoint   = CGPoint(x: 1.0, y: 1.0)
        return l
    }()

    private let baseGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1).cgColor,
        ]
        return l
    }()

    // MARK: - Header

    private lazy var logoLabel: UILabel = {
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "FILMIX", attributes: [
            .kern: CGFloat(8),
            .font: UIFont.systemFont(ofSize: 38, weight: .heavy),
            .foregroundColor: UIColor.white,
        ])
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let logoAccentDot: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var sectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Popular"
        l.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        l.textColor = UIColor(white: 0.65, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let headerSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Hero Panel

    private lazy var heroPanel: HeroPanel = {
        let p = HeroPanel()
        p.alpha = 0
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()

    private lazy var heroPanelHeightConstraint = heroPanel.heightAnchor.constraint(equalToConstant: 0)

    // MARK: - Collection View

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeFlowLayout())
        cv.backgroundColor = .clear
        cv.remembersLastFocusedIndexPath = true
        cv.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseID)
        cv.register(LoadingFooterView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: LoadingFooterView.reuseID)
        cv.dataSource = self
        cv.delegate   = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // MARK: - Loading / Error overlays

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = .white
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.6, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 3
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var retryButton: DetailButton = {
        let b = DetailButton(title: "↻  Retry", style: .secondary)
        b.isHidden = true
        b.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.insertSublayer(baseGradientLayer, at: 0)
        view.addSubview(backdropImageView)
        view.layer.addSublayer(vignetteLayer)
        view.addSubview(backdropBlur)
        view.addSubview(logoLabel)
        view.addSubview(logoAccentDot)
        view.addSubview(sectionLabel)
        view.addSubview(headerSeparator)
        view.addSubview(heroPanel)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)

        heroPanelHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            logoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 52),
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),

            logoAccentDot.widthAnchor.constraint(equalToConstant: 10),
            logoAccentDot.heightAnchor.constraint(equalToConstant: 10),
            logoAccentDot.leadingAnchor.constraint(equalTo: logoLabel.trailingAnchor, constant: 4),
            logoAccentDot.bottomAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: -6),

            sectionLabel.centerYAnchor.constraint(equalTo: logoLabel.centerYAnchor),
            sectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),

            headerSeparator.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 18),
            headerSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            headerSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1),

            heroPanel.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor, constant: 16),
            heroPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroPanelHeightConstraint,

            collectionView.topAnchor.constraint(equalTo: heroPanel.bottomAnchor, constant: 60),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            errorLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),

            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
        ])

        loadFirstPage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baseGradientLayer.frame = view.bounds
        vignetteLayer.frame     = view.bounds
    }

    // MARK: - Networking

    private func loadFirstPage() {
        guard !isFetching else { return }
        isFetching = true
        errorLabel.isHidden  = true
        retryButton.isHidden = true
        loadingIndicator.startAnimating()

        FilmixService.shared.fetchPage(url: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isFetching = false
                self.loadingIndicator.stopAnimating()
                self.hasLoadedFirstPage = true

                switch result {
                case .success(let page):
                    self.nextPageURL = page.nextPageURL
                    self.movies = page.movies
                    self.collectionView.reloadData()
                    // После reloadData обновляем hero для текущего фокуса если он есть
                    self.refreshHeroForCurrentFocus()

                case .failure(let error):
                    self.errorLabel.text = "Failed to load\n\(error.localizedDescription)"
                    self.errorLabel.isHidden  = false
                    self.retryButton.isHidden = false
                }
            }
        }
    }

    private func loadNextPage() {
        guard !isFetching, let url = nextPageURL else { return }
        isFetching = true

        FilmixService.shared.fetchPage(url: url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isFetching = false

                switch result {
                case .success(let page):
                    let startIndex = self.movies.count
                    self.nextPageURL = page.nextPageURL
                    self.movies.append(contentsOf: page.movies)

                    let indexPaths = (startIndex ..< self.movies.count)
                        .map { IndexPath(item: $0, section: 0) }
                    self.collectionView.performBatchUpdates {
                        self.collectionView.insertItems(at: indexPaths)
                    }

                    if self.nextPageURL == nil {
                        self.collectionView.reloadData()
                    }

                    self.refreshHeroForCurrentFocus()

                case .failure:
                    break
                }
            }
        }
    }

    @objc private func retryTapped() {
        loadFirstPage()
    }

    // MARK: - Layout helpers

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection         = .vertical
        l.minimumInteritemSpacing = 28
        l.minimumLineSpacing      = 44
        l.sectionInset = UIEdgeInsets(top: 0, left: 80, bottom: 80, right: 80)
        l.footerReferenceSize = CGSize(width: 0, height: 80)
        return l
    }

    private func cellSize() -> CGSize {
        let width             = view.bounds.width
        let horizontalPadding = 80.0 * 2
        let spacing           = 28.0 * 4
        let w = floor((width - horizontalPadding - spacing) / 5)
        let h = floor(w * 313 / 220)
        return CGSize(width: w, height: h)
    }

    // MARK: - Hero Panel

    private func showHeroPanel(for movie: Movie) {
        heroPanel.configure(with: movie)
        UIView.transition(with: backdropImageView, duration: 0.55, options: .transitionCrossDissolve) {
            self.backdropImageView.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 1920, height: 1080))
        }
        if heroPanel.alpha < 0.5 {
            heroPanelHeightConstraint.constant = 290
            heroPanel.transform = CGAffineTransform(translationX: 0, y: -20)
            UIView.animate(withDuration: 0.40, delay: 0, options: .curveEaseOut) {
                self.heroPanel.alpha     = 1
                self.heroPanel.transform = .identity
                self.backdropImageView.alpha = 0.22
                self.backdropBlur.alpha      = 0.60
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.20) { self.heroPanel.alpha = 1 }
        }
    }

    private func hideHeroPanel() {
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseIn) {
            self.heroPanel.alpha     = 0
            self.heroPanel.transform = CGAffineTransform(translationX: 0, y: -10)
            self.backdropImageView.alpha = 0
            self.backdropBlur.alpha      = 0
            self.heroPanelHeightConstraint.constant = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.heroPanel.transform = .identity
        }
    }

    private func refreshHeroForCurrentFocus() {
        guard let focusedId = currentFocusedMovieId,
              let movie = movies.first(where: { $0.id == focusedId })
        else { return }
        showHeroPanel(for: movie)
    }

    // MARK: - Focus

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if let cell = context.nextFocusedItem as? MovieCell,
           let ip   = collectionView.indexPath(for: cell) {
            let movie = movies[ip.item]
            guard movie.id != currentFocusedMovieId else { return }
            currentFocusedMovieId = movie.id
            detailDebounceTimer?.invalidate()
            pendingMovie = movie
            detailDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: false) { [weak self] _ in
                guard let self, let m = self.pendingMovie else { return }
                self.showHeroPanel(for: m)
            }
        } else if !(context.nextFocusedItem is MovieCell) {
            detailDebounceTimer?.invalidate()
            pendingMovie          = nil
            currentFocusedMovieId = nil
            hideHeroPanel()
        }
    }
}

extension MainController: UICollectionViewDataSource {

    func collectionView(_ cv: UICollectionView,
                        numberOfItemsInSection s: Int) -> Int {
        movies.count
    }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseID,
                                          for: ip) as! MovieCell
        cell.configure(with: movies[ip.item], rank: ip.item + 1)
        return cell
    }

    func collectionView(_ cv: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at ip: IndexPath) -> UICollectionReusableView {
        let footer = cv.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: LoadingFooterView.reuseID,
            for: ip) as! LoadingFooterView
        footer.setAnimating(isFetching && nextPageURL != nil)
        return footer
    }
}

extension MainController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        present(MovieDetailViewController(movie: movies[ip.item]), animated: true)
    }

    func collectionView(_ cv: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt ip: IndexPath) {
        let threshold = max(0, movies.count - 10)
        if ip.item >= threshold {
            loadNextPage()
        }
    }
}

extension MainController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize {
        cellSize()
    }

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        nextPageURL != nil
            ? CGSize(width: cv.bounds.width, height: 80)
            : .zero
    }
}
