import UIKit
import AVKit

// MARK: - SeriesPickerStore

final class SeriesPickerStore {
    static let shared = SeriesPickerStore()
    private let defaults = UserDefaults.standard

    private func key(_ movieId: Int, _ suffix: String) -> String { "series_picker_\(movieId)_\(suffix)" }

    func season(movieId: Int) -> Int      { defaults.integer(forKey: key(movieId, "season")) }
    func episode(movieId: Int) -> Int     { defaults.integer(forKey: key(movieId, "episode")) }
    func quality(movieId: Int) -> String? { defaults.string(forKey: key(movieId, "quality")) }
    func studio(movieId: Int) -> String?  { defaults.string(forKey: key(movieId, "studio")) }

    func save(movieId: Int, season: Int, episode: Int, quality: String, studio: String) {
        defaults.set(season,  forKey: key(movieId, "season"))
        defaults.set(episode, forKey: key(movieId, "episode"))
        defaults.set(quality, forKey: key(movieId, "quality"))
        defaults.set(studio,  forKey: key(movieId, "studio"))
    }
}

// MARK: - Step

private enum PickerStep {
    case season
    case episode(seasonIndex: Int)
    case quality(seasonIndex: Int, episodeIndex: Int)
}

private enum AnimationDirection { case forward, back }

// MARK: - SeriesPickerViewController

final class SeriesPickerViewController: UIViewController {

    var onPlay: ((String, String) -> Void)?

    private let translation: FilmixTranslation
    private let movieId: Int
    private let movieTitle: String
    private let accentColor: UIColor
    private var step: PickerStep = .season

    // MARK: - UI

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24
        v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.85
        v.layer.shadowRadius = 60
        v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.40, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 4
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // MARK: - Init

    init(translation: FilmixTranslation, movieId: Int, movieTitle: String, accentColor: UIColor) {
        self.translation = translation
        self.movieId     = movieId
        self.movieTitle  = movieTitle
        self.accentColor = accentColor
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(separator)
        containerView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 620),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            separator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            separator.heightAnchor.constraint(equalToConstant: 1),

            contentStack.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -28),
        ])

        // Restore saved state or start at season step
        let savedStudio = SeriesPickerStore.shared.studio(movieId: movieId)
        if savedStudio == translation.studio {
            let si = SeriesPickerStore.shared.season(movieId: movieId)
            let ei = SeriesPickerStore.shared.episode(movieId: movieId)
            if si < translation.seasons.count {
                let folders = translation.seasons[si].folder
                if ei < folders.count {
                    step = .quality(seasonIndex: si, episodeIndex: ei)
                } else {
                    step = .episode(seasonIndex: si)
                }
            }
        }

        render(animated: false)
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [contentStack.arrangedSubviews.first].compactMap { $0 }
    }

    // MARK: - Render

    private func render(animated: Bool, direction: AnimationDirection = .forward) {
        updateHeader(for: step)
        let newRows = buildRows(for: step)

        guard animated else {
            contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            newRows.forEach { contentStack.addArrangedSubview($0) }
            return
        }

        let offsetX: CGFloat = direction == .forward ? 50 : -50
        let oldViews = contentStack.arrangedSubviews

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            oldViews.forEach {
                $0.alpha = 0
                $0.transform = CGAffineTransform(translationX: -offsetX, y: 0)
            }
        } completion: { _ in
            oldViews.forEach { $0.removeFromSuperview() }
            newRows.forEach {
                $0.alpha = 0
                $0.transform = CGAffineTransform(translationX: offsetX, y: 0)
                self.contentStack.addArrangedSubview($0)
            }
            UIView.animate(withDuration: 0.20, delay: 0, options: .curveEaseOut) {
                newRows.forEach { $0.alpha = 1; $0.transform = .identity }
            } completion: { _ in
                self.setNeedsFocusUpdate()
                self.updateFocusIfNeeded()
            }
        }
    }

    // MARK: - Header

    private func updateHeader(for step: PickerStep) {
        subtitleLabel.text = translation.studio
        let newTitle: String
        switch step {
        case .season:
            newTitle = "Качество"
        case .episode(let si):
            newTitle = translation.seasons[si].title.trimmingCharacters(in: .whitespaces)
        case .quality(let si, let ei):
            newTitle = translation.seasons[si].folder[ei].title.trimmingCharacters(in: .whitespaces)
        }
        UIView.transition(with: titleLabel, duration: 0.18, options: .transitionCrossDissolve) {
            self.titleLabel.text = newTitle
        }
    }

    // MARK: - Build rows

    private func buildRows(for step: PickerStep) -> [UIView] {
        switch step {

        case .season:
            return translation.seasons.enumerated().map { i, season in
                let savedSi     = SeriesPickerStore.shared.season(movieId: movieId)
                let savedStudio = SeriesPickerStore.shared.studio(movieId: movieId)
                let highlighted = (i == savedSi && savedStudio == translation.studio)

                let row = PickerRow(
                    primary: season.title.trimmingCharacters(in: .whitespaces),
                    secondary: "\(season.folder.count) эп.",
                    icon: "›",
                    accentColor: accentColor,
                    isHighlighted: highlighted
                )
                row.onSelect = { [weak self] in
                    guard let self else { return }
                    self.step = .episode(seasonIndex: i)
                    self.render(animated: true, direction: .forward)
                }
                return row
            }

        case .episode(let si):
            let season      = translation.seasons[si]
            let savedSi     = SeriesPickerStore.shared.season(movieId: movieId)
            let savedEi     = SeriesPickerStore.shared.episode(movieId: movieId)
            let savedStudio = SeriesPickerStore.shared.studio(movieId: movieId)

            return season.folder.enumerated().map { i, folder in
                let highlighted = (si == savedSi && i == savedEi && savedStudio == translation.studio)

                let row = PickerRow(
                    primary: folder.title.trimmingCharacters(in: .whitespaces),
                    secondary: nil,
                    icon: "›",
                    accentColor: accentColor,
                    isHighlighted: highlighted
                )
                row.onSelect = { [weak self] in
                    guard let self else { return }
                    self.step = .quality(seasonIndex: si, episodeIndex: i)
                    self.render(animated: true, direction: .forward)
                }
                return row
            }

        case .quality(let si, let ei):
            let folder  = translation.seasons[si].folder[ei]
            let streams = folder.streams

            let order   = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
            let known   = order.filter { streams[$0] != nil }
            let unknown = streams.keys.filter { !order.contains($0) }.sorted()
            let keys    = known + unknown

            let savedQ      = SeriesPickerStore.shared.quality(movieId: movieId)
            let savedSi     = SeriesPickerStore.shared.season(movieId: movieId)
            let savedEi     = SeriesPickerStore.shared.episode(movieId: movieId)
            let savedStudio = SeriesPickerStore.shared.studio(movieId: movieId)

            return keys.compactMap { key -> UIView? in
                guard let url = streams[key] else { return nil }
                let highlighted = (key == savedQ && si == savedSi && ei == savedEi && savedStudio == translation.studio)

                let row = QualityRow(
                    quality: key,
                    accentColor: accentColor,
                    isHighlighted: highlighted
                )
                row.onSelect = { [weak self] in
                    guard let self else { return }
                    SeriesPickerStore.shared.save(
                        movieId: self.movieId,
                        season: si, episode: ei,
                        quality: key, studio: self.translation.studio
                    )
                    let playTitle = "\(self.movieTitle) · \(self.translation.studio) · \(key)"
                    self.dismiss(animated: true) {
                        self.onPlay?(playTitle, url)
                    }
                }
                return row
            }
        }
    }

    // MARK: - Menu button → back navigation

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .menu }) else {
            super.pressesBegan(presses, with: event); return
        }
        switch step {
        case .season:
            dismiss(animated: true)
        case .episode:
            step = .season
            render(animated: true, direction: .back)
        case .quality(let si, _):
            step = .episode(seasonIndex: si)
            render(animated: true, direction: .back)
        }
    }
}

// MARK: - PickerRow

final class PickerRow: UIView {

    var onSelect: (() -> Void)?

    private let primaryLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let secondaryLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.40, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let iconLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 24, weight: .light)
        l.textColor = UIColor(white: 0.32, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let dot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 3.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(primary: String, secondary: String?, icon: String,
         accentColor: UIColor, isHighlighted: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        dot.backgroundColor = accentColor
        dot.alpha = isHighlighted ? 1 : 0
        bg.backgroundColor = isHighlighted ? UIColor(white: 1, alpha: 0.08) : .clear

        addSubview(bg); addSubview(dot)
        addSubview(primaryLabel); addSubview(iconLabel)

        primaryLabel.text = primary
        iconLabel.text    = icon

        var constraints: [NSLayoutConstraint] = [
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 7),
            dot.heightAnchor.constraint(equalToConstant: 7),

            primaryLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34),
            primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ]

        if let sec = secondary {
            secondaryLabel.text = sec
            addSubview(secondaryLabel)
            constraints += [
                secondaryLabel.leadingAnchor.constraint(equalTo: primaryLabel.trailingAnchor, constant: 12),
                secondaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            let highlighted = self.dot.alpha > 0
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20)
                : (highlighted ? UIColor(white: 1, alpha: 0.08) : .clear)
            self.iconLabel.textColor = self.isFocused
                ? UIColor(white: 0.90, alpha: 1) : UIColor(white: 0.32, alpha: 1)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.28) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.20) : .clear
        }
        onSelect?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.20) : .clear
        }
        super.pressesCancelled(presses, with: event)
    }
}

// MARK: - QualityRow

final class QualityRow: UIView {

    var onSelect: (() -> Void)?

    private let qualityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let resLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.40, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let playIcon: UILabel = {
        let l = UILabel()
        l.text = "▶"
        l.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        l.textColor = UIColor(white: 0.32, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    private let dot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 3.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(quality: String, accentColor: UIColor, isHighlighted: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        dot.backgroundColor = accentColor
        dot.alpha = isHighlighted ? 1 : 0
        bg.backgroundColor = isHighlighted ? UIColor(white: 1, alpha: 0.08) : .clear

        addSubview(bg); addSubview(dot)
        addSubview(qualityLabel); addSubview(resLabel); addSubview(playIcon)

        qualityLabel.text = quality
        resLabel.text     = Self.hint(for: quality)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 7),
            dot.heightAnchor.constraint(equalToConstant: 7),

            qualityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34),
            qualityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            resLabel.leadingAnchor.constraint(equalTo: qualityLabel.trailingAnchor, constant: 12),
            resLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

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
            let highlighted = self.dot.alpha > 0
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20)
                : (highlighted ? UIColor(white: 1, alpha: 0.08) : .clear)
            self.playIcon.textColor = self.isFocused
                ? UIColor(white: 0.90, alpha: 1) : UIColor(white: 0.32, alpha: 1)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.28) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.20) : .clear
        }
        onSelect?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.20) : .clear
        }
        super.pressesCancelled(presses, with: event)
    }
}
