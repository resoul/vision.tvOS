import UIKit

final class StudioListViewController: UIViewController {

    var onSelect: ((FilmixTranslation) -> Void)?

    private let translations: [FilmixTranslation]
    private let activeStudio: String
    private let accentColor: UIColor

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24; v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.85; v.layer.shadowRadius = 60
        v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel(); l.text = "Озвучка"
        l.font = UIFont.systemFont(ofSize: 32, weight: .heavy); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 4; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    init(translations: [FilmixTranslation], activeStudio: String, accentColor: UIColor) {
        self.translations = translations
        self.activeStudio = activeStudio
        self.accentColor  = accentColor
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
        containerView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 580),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),

            contentStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -28),
        ])

        for t in translations {
            let row = PickerRow(
                primary: t.studio,
                secondary: t.bestQuality.map { "до \($0)" },
                icon: "›",
                accentColor: accentColor,
                isHighlighted: t.studio == activeStudio
            )
            row.onSelect = { [weak self] in
                self?.dismiss(animated: true) { self?.onSelect?(t) }
            }
            contentStack.addArrangedSubview(row)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [contentStack.arrangedSubviews.first(where: {
            ($0 as? PickerRow) != nil
        })].compactMap { $0 }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true) }
        else { super.pressesBegan(presses, with: event) }
    }
}
