import UIKit

final class CompactSeasonTab: UIControl {

    var onSelect: (() -> Void)?
    var isActiveTab: Bool = false { didSet { updateLook(animated: oldValue != isActiveTab) } }

    private let label: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let bg: UIView = {
        let v = UIView(); v.layer.cornerRadius = 10; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        // tooltip via subtitle (could be used for accessibility label)
        accessibilityLabel = subtitle

        addSubview(bg); addSubview(label)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),

            label.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: bg.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -8),
        ])
        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let block = {
            self.label.textColor = self.isActiveTab ? .white : UIColor(white: 0.40, alpha: 1)
            self.label.font = UIFont.systemFont(ofSize: 20, weight: self.isActiveTab ? .bold : .semibold)
            self.bg.backgroundColor = self.isActiveTab ? UIColor(white: 1, alpha: 0.14) : .clear
        }
        animated ? UIView.animate(withDuration: 0.18, animations: block) : block()
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.22)
                : (self.isActiveTab ? UIColor(white: 1, alpha: 0.14) : .clear)
            self.label.textColor = self.isFocused ? .white
                : (self.isActiveTab ? .white : UIColor(white: 0.40, alpha: 1))
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
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
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.22)
                : (self.isActiveTab ? UIColor(white: 1, alpha: 0.14) : .clear)
        }
        onSelect?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isActiveTab ? UIColor(white: 1, alpha: 0.14) : .clear
        }
        super.pressesCancelled(presses, with: event)
    }
}
