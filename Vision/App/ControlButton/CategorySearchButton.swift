import UIKit

final class CategorySearchButton: TVFocusControl {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "magnifyingglass")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(white: 0.45, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.text = String(localized: "main.searh")
        l.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)
        addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -18),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -12),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func applyFocusAppearance(focused: Bool) {
        let dim = UIColor(white: 0.45, alpha: 1)
        label.textColor    = focused ? .white : dim
        iconView.tintColor = focused ? .white : dim
    }
}
