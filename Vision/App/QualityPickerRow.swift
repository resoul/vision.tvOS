import UIKit

final class QualityPickerRow: UIView {

    var onSelect: (() -> Void)?

    private let qualityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let resolutionLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let playIcon: UILabel = {
        let l = UILabel()
        l.text = "▶"
        l.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(quality: String, accentColor: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        addSubview(bgView); addSubview(qualityLabel)
        addSubview(resolutionLabel); addSubview(playIcon)

        qualityLabel.text    = quality
        resolutionLabel.text = Self.hint(for: quality)

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            qualityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            qualityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            resolutionLabel.leadingAnchor.constraint(equalTo: qualityLabel.trailingAnchor, constant: 12),
            resolutionLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            playIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            playIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private static func hint(for q: String) -> String {
        switch q {
        case "4K UHD":       return "3840×2160"
        case "1080p Ultra+": return "1920×1080 HDR"
        case "1080p":        return "1920×1080"
        case "720p":         return "1280×720"
        case "480p":         return "854×480"
        case "360p":         return "640×360"
        default:             return ""
        }
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20) : .clear
            self.playIcon.textColor = self.isFocused
                ? UIColor(white: 0.85, alpha: 1) : UIColor(white: 0.35, alpha: 1)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.03, y: 1.03) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .select }) {
            UIView.animate(withDuration: 0.07) {
                self.bgView.backgroundColor = UIColor(white: 1, alpha: 0.30)
            }
        } else {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .select }) {
            UIView.animate(withDuration: 0.10) {
                self.bgView.backgroundColor = UIColor(white: 1, alpha: 0.20)
            }
            onSelect?()
        } else {
            super.pressesEnded(presses, with: event)
        }
    }
}
