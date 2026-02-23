import UIKit
import AVKit

private enum AnimationDirection { case forward, back }
private enum PickerStep {
    case season
    case episode(seasonIndex: Int)
    case quality(seasonIndex: Int, episodeIndex: Int)
}

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
