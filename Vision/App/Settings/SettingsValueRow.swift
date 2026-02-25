import UIKit

final class SettingsValueRow: UIView {

    private let action: (SettingsValueRow) -> Void
    private let iconView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFit; iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 28, weight: .medium); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let valueLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        l.textColor = UIColor(white: 0.50, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let chevron: UILabel = {
        let l = UILabel(); l.text = "›"; l.font = UIFont.systemFont(ofSize: 30, weight: .light)
        l.textColor = UIColor(white: 0.30, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bg: UIView = {
        let v = UIView(); v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(title: String, value: String, icon: String, action: @escaping (SettingsValueRow) -> Void) {
        self.action = action
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 76).isActive = true
        titleLabel.text = title; valueLabel.text = value
        iconView.image = UIImage(systemName: icon)
        addSubview(bg); addSubview(iconView); addSubview(titleLabel)
        addSubview(valueLabel); addSubview(chevron)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            iconView.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 24),
            iconView.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -24),
            chevron.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -10),
            valueLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func updateValue(_ text: String) { valueLabel.text = text }

    override var canBecomeFocused: Bool { true }
    override func didUpdateFocus(in ctx: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.12) : .clear
            self.chevron.textColor = self.isFocused ? UIColor(white: 0.80, alpha: 1) : UIColor(white: 0.30, alpha: 1)
            self.valueLabel.textColor = self.isFocused ? .white : UIColor(white: 0.50, alpha: 1)
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }, completion: nil)
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesBegan(presses, with: event); return }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.20) }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesEnded(presses, with: event); return }
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.12) : .clear }
        action(self)
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = .clear }
        super.pressesCancelled(presses, with: event)
    }
}
