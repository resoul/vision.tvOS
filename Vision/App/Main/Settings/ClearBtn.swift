import UIKit

final class ClearBtn: UIControl {
    var onTap: (() -> Void)?

    private let label: UILabel = {
        let l = UILabel()
        l.text = "Очистить"
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor = UIColor(red: 0.9, green: 0.30, blue: 0.30, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(bg); addSubview(label)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private let red = UIColor(red: 0.9, green: 0.30, blue: 0.30, alpha: 1)

    override var canBecomeFocused: Bool { true }
    override func didUpdateFocus(in ctx: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused ? self.red.withAlphaComponent(0.18) : .clear
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }, completion: nil)
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesBegan(presses, with: event); return }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = self.red.withAlphaComponent(0.28) }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesEnded(presses, with: event); return }
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = self.isFocused ? self.red.withAlphaComponent(0.18) : .clear }
        onTap?()
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = .clear }
        super.pressesCancelled(presses, with: event)
    }
}
