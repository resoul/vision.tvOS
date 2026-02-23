import UIKit

final class EpisodeMainControl: UIControl {

    var onPlay: (() -> Void)?

    private let accentColor: UIColor
    private var watched: Bool

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

    private let numberLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        l.textColor = UIColor(white: 0.30, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        l.textColor = .white; l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let qualityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let playIconLabel: UILabel = {
        let l = UILabel(); l.text = "▶"
        l.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    init(index: Int, folder: _FilmixPlayerFolder, accentColor: UIColor, isWatched: Bool) {
        self.accentColor = accentColor
        self.watched     = isWatched
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        accentLine.backgroundColor = accentColor
        numberLabel.text = "E\(index + 1)"
        titleLabel.text  = folder.title.trimmingCharacters(in: .whitespaces)

        let order = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let streams = folder.streams
        qualityLabel.text = order.first(where: { streams[$0] != nil })
            ?? streams.keys.sorted().first ?? ""

        addSubview(bg); addSubview(accentLine)
        addSubview(numberLabel); addSubview(titleLabel)
        addSubview(qualityLabel); addSubview(playIconLabel)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            accentLine.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
            accentLine.topAnchor.constraint(equalTo: bg.topAnchor, constant: 10),
            accentLine.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -10),
            accentLine.widthAnchor.constraint(equalToConstant: 3),

            numberLabel.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 20),
            numberLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 42),

            titleLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: qualityLabel.leadingAnchor, constant: -16),

            qualityLabel.trailingAnchor.constraint(equalTo: playIconLabel.leadingAnchor, constant: -16),
            qualityLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),

            playIconLabel.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -20),
            playIconLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
        ])

        applyWatchedState(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setWatched(_ w: Bool) {
        watched = w
        applyWatchedState(animated: true)
    }

    private func applyWatchedState(animated: Bool) {
        let block = {
            self.titleLabel.alpha  = self.watched ? 0.40 : 1.0
            self.numberLabel.alpha = self.watched ? 0.30 : 1.0
            self.bg.backgroundColor = UIColor(white: 1, alpha: self.watched ? 0.03 : 0.05)
        }
        animated ? UIView.animate(withDuration: 0.18, animations: block) : block()
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.bg.backgroundColor = UIColor(white: 1, alpha: 0.12)
                self.accentLine.alpha = 1
                self.playIconLabel.textColor = self.accentColor
                self.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOpacity = 0.4
                self.layer.shadowRadius = 12
                self.layer.shadowOffset = CGSize(width: 0, height: 6)
            } else {
                self.bg.backgroundColor = UIColor(white: 1, alpha: self.watched ? 0.03 : 0.05)
                self.accentLine.alpha = 0
                self.playIconLabel.textColor = UIColor(white: 0.45, alpha: 1)
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
            self.bg.backgroundColor = UIColor(white: 1, alpha: self.isFocused ? 0.12 : (self.watched ? 0.03 : 0.05))
        }
        onPlay?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = UIColor(white: 1, alpha: self.watched ? 0.03 : 0.05)
        }
        super.pressesCancelled(presses, with: event)
    }
}
