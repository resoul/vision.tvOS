import UIKit

final class OverlayButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        configuration = makeConfig(focused: false)
        layer.cornerRadius = 14
        layer.cornerCurve  = .continuous
    }

    private func makeConfig(focused: Bool) -> UIButton.Configuration {
        var c = UIButton.Configuration.filled()
        c.baseBackgroundColor = focused
            ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
            : UIColor(white: 1.0, alpha: 0.18)
        c.baseForegroundColor = focused ? .black : .white
        c.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr
            a.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
            return a
        }
        return c
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            let focused = self.isFocused
            self.configuration = self.makeConfig(focused: focused)
            self.transform = focused
                ? CGAffineTransform(scaleX: 1.06, y: 1.06)
                : .identity
        }
    }

    override var canBecomeFocused: Bool { true }
}
