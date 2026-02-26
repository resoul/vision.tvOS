import UIKit

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

    init(studio: String, quality: String, accentColor: UIColor) {
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
