import UIKit

final class GenreTabButton: UIControl {

    var isActiveTab: Bool = false { didSet { updateLook(animated: oldValue != isActiveTab) } }
    var onSelect: (() -> Void)?

    private let label: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10
        v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let accentDot: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 2.5
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        label.text = title

        addSubview(bgView)
        addSubview(label)
        addSubview(accentDot)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            label.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),

            accentDot.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            accentDot.widthAnchor.constraint(equalToConstant: 16),
            accentDot.heightAnchor.constraint(equalToConstant: 3),
        ])

        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let block = {
            self.label.textColor = self.isActiveTab ? .white : UIColor(white: 0.45, alpha: 1)
            self.label.font = UIFont.systemFont(ofSize: 20, weight: self.isActiveTab ? .bold : .semibold)
            self.bgView.backgroundColor = self.isActiveTab ? UIColor(white: 1, alpha: 0.10) : .clear
            self.accentDot.alpha = self.isActiveTab ? 1 : 0
            self.accentDot.transform = self.isActiveTab ? .identity : CGAffineTransform(scaleX: 0.4, y: 1)
        }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0,
                           usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5,
                           animations: block)
        } else {
            block()
        }
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.18)
                : (self.isActiveTab ? UIColor(white: 1, alpha: 0.10) : .clear)
            self.label.textColor = self.isFocused ? .white
                : (self.isActiveTab ? .white : UIColor(white: 0.45, alpha: 1))
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.08) {
            self.bgView.backgroundColor = UIColor(white: 1, alpha: 0.25)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.12) {
            self.bgView.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.18) : .clear
        }
        onSelect?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.12) {
            self.bgView.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.18) : .clear
        }
        super.pressesCancelled(presses, with: event)
    }
}
