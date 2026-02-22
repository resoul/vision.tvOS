import UIKit

enum DetailButtonStyle { case primary, secondary }

final class DetailButton: UIButton {
    init(title: String, style: DetailButtonStyle) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 26, bottom: 0, trailing: 26)
        config.background.backgroundColor = .clear
        switch style {
        case .primary:   config.baseForegroundColor = .black
        case .secondary: config.baseForegroundColor = .white
        }
        configuration = config
        layer.cornerRadius = 12; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true
        switch style {
        case .primary:   backgroundColor = .white
        case .secondary:
            backgroundColor = UIColor(white: 1, alpha: 0.13)
            layer.borderWidth = 1; layer.borderColor = UIColor(white: 1, alpha: 0.2).cgColor
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
            self.layer.shadowOpacity = self.isFocused ? 0.28 : 0
            self.layer.shadowColor = UIColor.white.cgColor; self.layer.shadowRadius = 16; self.layer.shadowOffset = .zero
        }, completion: nil)
    }
}
