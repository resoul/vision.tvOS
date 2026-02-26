import UIKit

final class CompactSeasonTab: TVFocusControl {

    var isActiveTab: Bool = false {
        didSet { guard oldValue != isActiveTab else { return }
                 updateLook(animated: true) }
    }

    private let label: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        focusedBgAlpha = 0.22
        pressedBgAlpha = 0.28
        focusScale     = 1.06

        bgView.layer.cornerRadius = 10
        accessibilityLabel = subtitle
        label.text = title

        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -8),
        ])

        updateLook(animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Active tab appearance

    private func updateLook(animated: Bool) {
        let block = {
            self.label.textColor = self.isActiveTab ? .white : UIColor(white: 0.40, alpha: 1)
            self.label.font      = UIFont.systemFont(ofSize: 20, weight: self.isActiveTab ? .bold : .semibold)
            self.bgView.backgroundColor = UIColor(white: 1, alpha: self.isActiveTab ? 0.14 : 0)
        }
        animated ? UIView.animate(withDuration: 0.18, animations: block) : block()
    }

    // MARK: - Focus

    override func applyFocusAppearance(focused: Bool) {
        label.textColor = focused ? .white : (isActiveTab ? .white : UIColor(white: 0.40, alpha: 1))
        bgView.backgroundColor = UIColor(white: 1,
            alpha: focused ? focusedBgAlpha : (isActiveTab ? 0.14 : 0))
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.bgView.backgroundColor = UIColor(white: 1,
                alpha: self.isActiveTab ? 0.14 : 0)
        }
        super.pressesCancelled(presses, with: event)
    }
}
