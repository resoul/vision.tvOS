import UIKit

final class DetailInfoRow: UIView {
    private let keyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        l.textColor = UIColor(white: 0.38, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        l.textColor = UIColor(white: 0.76, alpha: 1); l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    override init(frame: CGRect) {
        super.init(frame: frame); translatesAutoresizingMaskIntoConstraints = false
        addSubview(keyLabel); addSubview(valueLabel)
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyLabel.firstBaselineAnchor.constraint(equalTo: valueLabel.firstBaselineAnchor),
            keyLabel.widthAnchor.constraint(equalToConstant: 155),
            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func set(key: String, value: String, lines: Int = 1) {
        let t = value.trimmingCharacters(in: .whitespacesAndNewlines)
        isHidden = t.isEmpty || t == "—"; guard !isHidden else { return }
        keyLabel.text = key + ":"; valueLabel.text = t; valueLabel.numberOfLines = lines
    }
}
