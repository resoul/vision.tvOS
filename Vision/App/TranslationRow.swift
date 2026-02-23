import UIKit

final class TranslationRow: UIView {

    let translation: FilmixTranslation
    var onSelect: ((FilmixTranslation) -> Void)?
    var isActive: Bool = false { didSet { updateLook(animated: true) } }

    private let dot: UIView = {
        let v = UIView(); v.layer.cornerRadius = 3.5; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let studioLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let qualityHint: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        l.textColor = UIColor(white: 0.32, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let chevron: UILabel = {
        let l = UILabel(); l.text = "›"
        l.font = UIFont.systemFont(ofSize: 30, weight: .light)
        l.textColor = UIColor(white: 0.25, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bg: UIView = {
        let v = UIView(); v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(translation: FilmixTranslation, accentColor: UIColor) {
        self.translation = translation
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 62).isActive = true
        dot.backgroundColor = accentColor

        addSubview(bg); addSubview(dot)
        addSubview(studioLabel); addSubview(qualityHint); addSubview(chevron)

        studioLabel.text = translation.studio
        if let best = translation.bestQuality { qualityHint.text = "до \(best)" }

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 7),
            dot.heightAnchor.constraint(equalToConstant: 7),

            studioLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 34),
            studioLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            qualityHint.leadingAnchor.constraint(equalTo: studioLabel.trailingAnchor, constant: 16),
            qualityHint.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let block = {
            self.bg.backgroundColor    = self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear
            self.studioLabel.textColor = self.isActive ? .white : UIColor(white: 0.55, alpha: 1)
            self.studioLabel.font      = UIFont.systemFont(ofSize: 24, weight: self.isActive ? .semibold : .medium)
            self.dot.alpha             = self.isActive ? 1 : 0
            self.chevron.textColor     = self.isActive
                ? UIColor(white: 0.55, alpha: 1) : UIColor(white: 0.25, alpha: 1)
        }
        animated ? UIView.animate(withDuration: 0.18, animations: block) : block()
    }

    // MARK: - Focus / Press (tvOS native)

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor    = self.isFocused
                ? UIColor(white: 1, alpha: 0.16)
                : (self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear)
            self.studioLabel.textColor = self.isFocused ? .white
                : (self.isActive ? .white : UIColor(white: 0.55, alpha: 1))
            self.chevron.textColor     = self.isFocused
                ? UIColor(white: 0.85, alpha: 1) : UIColor(white: 0.25, alpha: 1)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.015, y: 1.015) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event); return
        }
        UIView.animate(withDuration: 0.07) {
            self.bg.backgroundColor = UIColor(white: 1, alpha: 0.24)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event); return
        }
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.16)
                : (self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear)
        }
        onSelect?(translation)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.16)
                : (self.isActive ? UIColor(white: 1, alpha: 0.08) : .clear)
        }
        super.pressesCancelled(presses, with: event)
    }
}
