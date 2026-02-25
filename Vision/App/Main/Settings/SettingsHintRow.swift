import UIKit

final class SettingsHintRow: UIView {
    init(text: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        addSubview(l)
        NSLayoutConstraint.activate([
            l.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            l.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            l.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            l.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
