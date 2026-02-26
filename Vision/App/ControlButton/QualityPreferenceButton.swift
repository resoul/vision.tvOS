import UIKit

final class QualityPreferenceButton: TVFocusControl {

    var onTap: (() -> Void)?

    private let gearLabel: UILabel = {
        let l = UILabel()
        l.text = "⚙"
        l.font = UIFont.systemFont(ofSize: 18)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let qualityLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.75, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        normalBgAlpha  = 0.08
        focusedBgAlpha = 0.18
        pressedBgAlpha = 0.26
        focusScale     = 1.04
        bgView.backgroundColor = UIColor(white: 1, alpha: normalBgAlpha)

        addSubview(gearLabel)
        addSubview(qualityLabel)

        NSLayoutConstraint.activate([
            gearLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            gearLabel.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),

            qualityLabel.leadingAnchor.constraint(equalTo: gearLabel.trailingAnchor, constant: 8),
            qualityLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            qualityLabel.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            qualityLabel.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 10),
            qualityLabel.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -10),
        ])

        onSelect = { [weak self] in self?.onTap?() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(quality: String?) {
        qualityLabel.text = quality ?? String(localized: "main.auto")
    }

    override func applyFocusAppearance(focused: Bool) {
        gearLabel.textColor    = focused ? .white : UIColor(white: 0.55, alpha: 1)
        qualityLabel.textColor = focused ? .white : UIColor(white: 0.75, alpha: 1)
    }
}
