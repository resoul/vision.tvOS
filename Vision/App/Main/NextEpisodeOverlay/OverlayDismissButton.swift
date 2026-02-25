import UIKit

final class OverlayDismissButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        configuration = makeConfig(focused: false)
    }

    private func makeConfig(focused: Bool) -> UIButton.Configuration {
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: "xmark.circle.fill",
                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium))
        c.baseForegroundColor = focused
            ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
            : UIColor(white: 1.0, alpha: 0.45)
        c.contentInsets = .zero
        return c
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            self.configuration = self.makeConfig(focused: self.isFocused)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.15, y: 1.15)
                : .identity
        }
    }

    override var canBecomeFocused: Bool { true }
}
