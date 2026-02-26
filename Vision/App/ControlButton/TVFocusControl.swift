import UIKit

class TVFocusControl: UIControl {

    var onSelect: (() -> Void)?
    var focusScale: CGFloat = 1.05
    var normalBgAlpha: CGFloat = 0
    var focusedBgAlpha: CGFloat = 0.18
    var pressedBgAlpha: CGFloat = 0.25

    let bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(bgView)
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        bgView.backgroundColor = UIColor(white: 1, alpha: normalBgAlpha)
    }
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { true }

    func applyFocusAppearance(focused: Bool) {}

    // MARK: - Focus

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = UIColor(white: 1,
                alpha: self.isFocused ? self.focusedBgAlpha : self.normalBgAlpha)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: self.focusScale, y: self.focusScale)
                : .identity
            self.applyFocusAppearance(focused: self.isFocused)
        }, completion: nil)
    }

    // MARK: - Press

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.08) {
            self.bgView.backgroundColor = UIColor(white: 1, alpha: self.pressedBgAlpha)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.12) {
            self.bgView.backgroundColor = UIColor(white: 1,
                alpha: self.isFocused ? self.focusedBgAlpha : self.normalBgAlpha)
        }
        onSelect?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.12) {
            self.bgView.backgroundColor = UIColor(white: 1,
                alpha: self.isFocused ? self.focusedBgAlpha : self.normalBgAlpha)
        }
        super.pressesCancelled(presses, with: event)
    }
}
