import UIKit

final class StudioPickerButton: UIControl {

    var onTap: (() -> Void)?
    private let accentColor: UIColor

    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let studioLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let chevron: UILabel = {
        let l = UILabel(); l.text = "⌄"
        l.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let dot: UIView = {
        let v = UIView(); v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(accentColor: UIColor) {
        self.accentColor = accentColor
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        dot.backgroundColor = accentColor

        addSubview(bg); addSubview(dot); addSubview(studioLabel); addSubview(chevron)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),

            dot.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 14),
            dot.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),

            studioLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 10),
            studioLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            studioLabel.topAnchor.constraint(equalTo: bg.topAnchor, constant: 10),
            studioLabel.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -10),

            chevron.leadingAnchor.constraint(equalTo: studioLabel.trailingAnchor, constant: 8),
            chevron.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: bg.centerYAnchor, constant: 2),
        ])

        bg.backgroundColor = UIColor(white: 1, alpha: 0.10)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(studio: String) {
        studioLabel.text = studio
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20) : UIColor(white: 1, alpha: 0.10)
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.04, y: 1.04) : .identity
            self.chevron.textColor = self.isFocused ? .white : UIColor(white: 0.55, alpha: 1)
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
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.20) : UIColor(white: 1, alpha: 0.10)
        }
        onTap?()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.10) }
        super.pressesCancelled(presses, with: event)
    }
}
