import UIKit

final class QualityPickerViewController: UIViewController {

    var onSelect: ((String, String) -> Void)?

    private let translation: FilmixTranslation
    private let accentColor: UIColor

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24; v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.85; v.layer.shadowRadius = 60
        v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Качество"
        l.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var qualityStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 8; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    init(translation: FilmixTranslation, accentColor: UIColor) {
        self.translation = translation
        self.accentColor = accentColor
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
        containerView.addSubview(qualityStack)

        subtitleLabel.text = translation.studio

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 580),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            qualityStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 28),
            qualityStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            qualityStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            qualityStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32),
        ])

        for key in translation.sortedQualities {
            guard let url = translation.streams[key] else { continue }
            let capturedKey = key
            let capturedURL = url
            let row = QualityPickerRow(quality: key, accentColor: accentColor)
            row.onSelect = { [weak self] in
                self?.dismiss(animated: true) {
                    self?.onSelect?(capturedKey, capturedURL)
                }
            }
            qualityStack.addArrangedSubview(row)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [qualityStack.arrangedSubviews.first].compactMap { $0 }
    }
}
