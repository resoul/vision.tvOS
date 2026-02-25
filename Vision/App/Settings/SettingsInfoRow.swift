import UIKit

final class SettingsInfoRow: UIView {
    init(title: String, value: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true
        let tl = UILabel(); tl.text = title
        tl.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        tl.textColor = UIColor(white: 0.60, alpha: 1)
        tl.translatesAutoresizingMaskIntoConstraints = false
        let vl = UILabel(); vl.text = value
        vl.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        vl.textColor = UIColor(white: 0.38, alpha: 1)
        vl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tl); addSubview(vl)
        NSLayoutConstraint.activate([
            tl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            tl.centerYAnchor.constraint(equalTo: centerYAnchor),
            vl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            vl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
