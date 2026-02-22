import UIKit

final class HeroInfoRow: UIView {
    private let keyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.42, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.74, alpha: 1)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(keyLabel)
        addSubview(valueLabel)
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyLabel.firstBaselineAnchor.constraint(equalTo: valueLabel.firstBaselineAnchor),

            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 10),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func set(key: String, value: String, lines: Int = 1) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let empty   = trimmed.isEmpty || trimmed == "—"
        isHidden    = empty
        guard !empty else { return }
        keyLabel.text            = key + ":"
        valueLabel.text          = trimmed
        valueLabel.numberOfLines = lines
    }
}
