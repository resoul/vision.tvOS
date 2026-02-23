import UIKit

// MARK: - CategorySettingsButton

final class CategorySettingsButton: UIControl {

    var onSelect: (() -> Void)?

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "gearshape.fill")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(white: 0.45, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let bgView: UIView = {
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
        addSubview(iconView)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),

            bgView.widthAnchor.constraint(equalToConstant: 52),
            bgView.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.18) : .clear
            self.iconView.tintColor = self.isFocused ? .white : UIColor(white: 0.45, alpha: 1)
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
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
