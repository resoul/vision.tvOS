import UIKit

final class MetaPill: UIView {
    init(text: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = color; layer.cornerRadius = 8; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        let l = UILabel(); l.text = text; l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .white; l.translatesAutoresizingMaskIntoConstraints = false; addSubview(l)
        NSLayoutConstraint.activate([l.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                                     l.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                                     l.topAnchor.constraint(equalTo: topAnchor, constant: 6),
                                     l.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)])
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class SmallPill: UIView {
    init(text: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = color
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false

        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        addSubview(l)

        NSLayoutConstraint.activate([
            l.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            l.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            l.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            l.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
