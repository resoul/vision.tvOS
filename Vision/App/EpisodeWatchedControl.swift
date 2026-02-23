import UIKit

final class EpisodeWatchedControl: UIControl {

    var onToggle: (() -> Void)?
    private var isWatched: Bool

    private let bg: UIView = {
        let v = UIView(); v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let icon: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    init(isWatched: Bool) {
        self.isWatched = isWatched
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(bg); addSubview(icon)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            icon.centerXAnchor.constraint(equalTo: bg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
        ])
        setWatched(isWatched)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setWatched(_ w: Bool) {
        isWatched = w
        icon.text      = w ? "✓" : "○"
        icon.textColor = w
            ? UIColor(red: 0.25, green: 0.85, blue: 0.50, alpha: 1)
            : UIColor(white: 0.28, alpha: 1)
        bg.backgroundColor = w ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 1, alpha: 0.03)
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.18)
                : (self.isWatched ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 1, alpha: 0.03))
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.25) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.18)
                : (self.isWatched ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 1, alpha: 0.03))
        }
        onToggle?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isWatched
                ? UIColor(white: 1, alpha: 0.07) : UIColor(white: 1, alpha: 0.03)
        }
        super.pressesCancelled(presses, with: event)
    }
}
