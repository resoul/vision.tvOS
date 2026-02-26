import UIKit

final class EpisodeWatchedControl: TVFocusControl {

    var onToggle: (() -> Void)?

    private var isWatched: Bool

    private let icon: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(isWatched: Bool) {
        self.isWatched = isWatched
        super.init(frame: .zero)

        focusedBgAlpha = 0.18
        pressedBgAlpha = 0.25
        focusScale     = 1.08
        bgView.layer.cornerRadius = 14

        addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
        ])

        onSelect = { [weak self] in self?.onToggle?() }

        setWatched(isWatched)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setWatched(_ w: Bool) {
        isWatched = w
        icon.text      = w ? "✓" : "○"
        icon.textColor = w
            ? UIColor(red: 0.25, green: 0.85, blue: 0.50, alpha: 1)
            : UIColor(white: 0.28, alpha: 1)
        normalBgAlpha = w ? 0.07 : 0.03
        bgView.backgroundColor = UIColor(white: 1, alpha: normalBgAlpha)
    }

    // MARK: - Focus

    override func applyFocusAppearance(focused: Bool) {}

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bgView.backgroundColor = UIColor(white: 1, alpha: self.normalBgAlpha)
        }
        super.pressesCancelled(presses, with: event)
    }
}
