import UIKit

final class StudioPickerButton: TVFocusControl {

    var onTap: (() -> Void)?
    private let accentColor: UIColor

    private let studioLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let chevron: UILabel = {
        let l = UILabel()
        l.text = "⌄"
        l.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dot: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(accentColor: UIColor) {
        self.accentColor = accentColor
        super.init(frame: .zero)

        normalBgAlpha  = 0.10
        focusedBgAlpha = 0.20
        pressedBgAlpha = 0.28
        focusScale     = 1.04
        bgView.backgroundColor = UIColor(white: 1, alpha: normalBgAlpha)

        dot.backgroundColor = accentColor

        addSubview(dot)
        addSubview(studioLabel)
        addSubview(chevron)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            dot.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),

            studioLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 10),
            studioLabel.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            studioLabel.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 10),
            studioLabel.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -10),

            chevron.leadingAnchor.constraint(equalTo: studioLabel.trailingAnchor, constant: 8),
            chevron.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: bgView.centerYAnchor, constant: 2),
        ])

        onSelect = { [weak self] in self?.onTap?() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(studio: String) {
        studioLabel.text = studio
    }

    override func applyFocusAppearance(focused: Bool) {
        chevron.textColor = focused ? .white : UIColor(white: 0.55, alpha: 1)
    }
}
