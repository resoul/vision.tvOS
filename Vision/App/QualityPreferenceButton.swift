import UIKit

final class QualityPreferenceButton: UIControl {

    var onTap: (() -> Void)?

    private let bg: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.layer.cornerRadius = 12; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let gearLabel: UILabel = {
        let l = UILabel(); l.text = "⚙"
        l.font = UIFont.systemFont(ofSize: 18); l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let qualityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.75, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(bg); addSubview(gearLabel); addSubview(qualityLabel)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),

            gearLabel.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 14),
            gearLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),

            qualityLabel.leadingAnchor.constraint(equalTo: gearLabel.trailingAnchor, constant: 8),
            qualityLabel.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -14),
            qualityLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            qualityLabel.topAnchor.constraint(equalTo: bg.topAnchor, constant: 10),
            qualityLabel.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(quality: String?) {
        qualityLabel.text = quality ?? "Авто"
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.18) : UIColor(white: 1, alpha: 0.08)
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.04, y: 1.04) : .identity
            self.gearLabel.textColor = self.isFocused ? .white : UIColor(white: 0.55, alpha: 1)
            self.qualityLabel.textColor = self.isFocused ? .white : UIColor(white: 0.75, alpha: 1)
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.26) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.18) : UIColor(white: 1, alpha: 0.08)
        }
        onTap?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.08) }
        super.pressesCancelled(presses, with: event)
    }
}
