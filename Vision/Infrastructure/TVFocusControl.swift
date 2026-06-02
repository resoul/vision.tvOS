import UIKit

class TVFocusControl: UIControl {
    var onSelect: (() -> Void)?
    var focusScale: CGFloat = 1.05
    var normalBgAlpha: CGFloat = 0
    var focusedBgAlpha: CGFloat = 0.18
    var pressedBgAlpha: CGFloat = 0.25

    let bgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        return view
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

    override var canBecomeFocused: Bool { true }

    func applyFocusAppearance(focused: Bool) {}

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.transform = self.isFocused ? CGAffineTransform(scaleX: self.focusScale, y: self.focusScale) : .identity
            self.applyFocusAppearance(focused: self.isFocused)
        })
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event)
            return
        }
        onSelect?()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
