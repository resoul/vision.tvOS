import UIKit

final class NoTranslationAlert: UIViewController {

    var onSwitchTranslation: (() -> Void)?

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24; v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.85; v.layer.shadowRadius = 60
        v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.text = "⚠︎"
        l.font = UIFont.systemFont(ofSize: 48)
        l.textColor = UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Озвучка закончилась"
        l.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Эта озвучка не содержит следующих серий.\nПопробуйте выбрать другую озвучку."
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var switchButton: DetailButton = {
        let b = DetailButton(title: "Выбрать озвучку", style: .primary)
        b.addTarget(self, action: #selector(switchTapped), for: .primaryActionTriggered)
        return b
    }()

    private lazy var closeButton: DetailButton = {
        let b = DetailButton(title: "Закрыть", style: .secondary)
        b.addTarget(self, action: #selector(closeTapped), for: .primaryActionTriggered)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.80)

        view.addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(switchButton)
        containerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 620),

            iconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 48),
            iconLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -44),

            switchButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 36),
            switchButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            switchButton.widthAnchor.constraint(equalToConstant: 320),

            closeButton.topAnchor.constraint(equalTo: switchButton.bottomAnchor, constant: 12),
            closeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 320),
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -44),
        ])
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] { [switchButton] }

    @objc private func switchTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onSwitchTranslation?()
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true) }
        else { super.pressesBegan(presses, with: event) }
    }
}
