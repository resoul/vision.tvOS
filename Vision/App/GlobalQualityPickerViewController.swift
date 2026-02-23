import UIKit

final class GlobalQualityPickerViewController: UIViewController {

    var onSelect: ((String?) -> Void)?

    private let qualities: [String]
    private let current: String?
    private let titleText: String
    private let subtitleText: String

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24; v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.85; v.layer.shadowRadius = 60
        v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel(); l.text = titleText
        l.font = UIFont.systemFont(ofSize: 32, weight: .heavy); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel(); l.text = subtitleText
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.numberOfLines = 2
        l.isHidden = subtitleText.isEmpty
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 4; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    init(qualities: [String], current: String?,
         title: String = "Качество по умолчанию",
         subtitle: String = "") {
        self.qualities    = qualities
        self.current      = current
        self.titleText    = title
        self.subtitleText = subtitle
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 580),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),

            contentStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -28),
        ])

        // "Авто" option at top
        let autoRow = PickerRow(
            primary: "Авто",
            secondary: "Лучшее доступное",
            icon: current == nil ? "✓" : "",
            accentColor: UIColor(white: 0.5, alpha: 1),
            isHighlighted: current == nil
        )
        autoRow.onSelect = { [weak self] in
            SeriesPickerStore.shared.globalPreferredQuality = nil
            self?.dismiss(animated: true) { self?.onSelect?(nil) }
        }
        contentStack.addArrangedSubview(autoRow)

        for q in qualities {
            let row = PickerRow(
                primary: q,
                secondary: nil,
                icon: q == current ? "✓" : "",
                accentColor: UIColor(white: 0.5, alpha: 1),
                isHighlighted: q == current
            )
            row.onSelect = { [weak self] in
                SeriesPickerStore.shared.globalPreferredQuality = q
                self?.dismiss(animated: true) { self?.onSelect?(q) }
            }
            contentStack.addArrangedSubview(row)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        contentStack.arrangedSubviews.compactMap { $0 as? PickerRow }
            .first.map { [$0] } ?? []
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true) }
        else { super.pressesBegan(presses, with: event) }
    }
}
