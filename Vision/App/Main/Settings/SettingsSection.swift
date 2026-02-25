import UIKit

final class SettingsSection: UIView {

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        l.textColor = UIColor(white: 0.40, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let rowsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 0; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.05)
        v.layer.cornerRadius = 18; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = title.uppercased()
        addSubview(headerLabel); addSubview(container); container.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            container.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowsStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            rowsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            rowsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            rowsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func addRow(_ row: UIView) {
        if !rowsStack.arrangedSubviews.isEmpty {
            let sep = UIView()
            sep.backgroundColor = UIColor(white: 1, alpha: 0.06)
            sep.translatesAutoresizingMaskIntoConstraints = false
            sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
            rowsStack.addArrangedSubview(sep)
        }
        rowsStack.addArrangedSubview(row)
    }
}
