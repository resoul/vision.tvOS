import UIKit

final class StorageRowView: UIView {
    private let dotView   = UIView()
    private let titleLbl  = UILabel()
    private let subtitleLbl = UILabel()
    private let sizeLbl   = UILabel()
    private var clearBtn: ClearBtn?

    init(color: UIColor, title: String, subtitle: String,
         size: String, canClear: Bool, onClear: (() -> Void)? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        dotView.backgroundColor = color
        dotView.layer.cornerRadius = 6
        dotView.translatesAutoresizingMaskIntoConstraints = false

        titleLbl.text = title
        titleLbl.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        titleLbl.textColor = .white
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        subtitleLbl.text = subtitle
        subtitleLbl.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        subtitleLbl.textColor = UIColor(white: 0.45, alpha: 1)
        subtitleLbl.translatesAutoresizingMaskIntoConstraints = false

        sizeLbl.text = size
        sizeLbl.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        sizeLbl.textColor = UIColor(white: 0.65, alpha: 1)
        sizeLbl.textAlignment = .right
        sizeLbl.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subtitleLbl])
        textStack.axis = .vertical; textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(dotView); addSubview(textStack); addSubview(sizeLbl)

        var trailingAnchor = trailingAnchor
        var trailingConstant: CGFloat = -24

        if canClear, let onClear {
            let btn = ClearBtn()
            btn.onTap = onClear
            addSubview(btn)
            clearBtn = btn
            NSLayoutConstraint.activate([
                btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
                btn.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
            trailingAnchor = btn.leadingAnchor
            trailingConstant = -12
        }

        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 12),
            dotView.heightAnchor.constraint(equalToConstant: 12),
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 16),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            sizeLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingConstant),
            sizeLbl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func updateSize(_ text: String) { sizeLbl.text = text }
    func updateSubtitle(_ text: String) { subtitleLbl.text = text }
}
