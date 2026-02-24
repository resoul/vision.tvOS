import UIKit

// MARK: - NextEpisodeOverlay
//
// Показывается в правом нижнем углу экрана когда эпизод подходит к концу.
// НЕ переключает эпизод автоматически — пользователь нажимает кнопку сам.
// Кнопка "Следующая серия" вызывает onNext.
// Кнопка "✕" или нажатие Menu — скрывает оверлей, вызывает onDismiss.

final class NextEpisodeOverlay: UIView {

    // MARK: - Callbacks
    var onNext: (() -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - UI

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let v = UIVisualEffectView(effect: blur)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 20
        v.layer.cornerCurve  = .continuous
        v.clipsToBounds = true
        return v
    }()

    private let labelStack: UIStackView = {
        let s = UIStackView()
        s.axis    = .vertical
        s.spacing = 4
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let eyebrowLabel: UILabel = {
        let l = UILabel()
        l.text          = "Следующая серия"
        l.font          = UIFont.systemFont(ofSize: 17, weight: .semibold)
        l.textColor     = UIColor(white: 1.0, alpha: 0.55)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 26, weight: .bold)
        l.textColor     = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private(set) lazy var nextButton: _OverlayButton = {
        let b = _OverlayButton()
        b.setTitle("Смотреть", for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let dismissButton: _OverlayDismissButton = {
        let b = _OverlayDismissButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init

    init(nextTitle: String, countdown: Int = 0) {
        super.init(frame: .zero)
        titleLabel.text = nextTitle
        setupLayout()
        setupActions()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func setupLayout() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.7
        layer.shadowRadius  = 40
        layer.shadowOffset  = CGSize(width: 0, height: 10)

        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let vibrancy = UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark))
        let vibrancyView = UIVisualEffectView(effect: vibrancy)
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false

        let divider = UIView()
        divider.backgroundColor = UIColor(white: 1.0, alpha: 0.12)
        divider.translatesAutoresizingMaskIntoConstraints = false

        labelStack.addArrangedSubview(eyebrowLabel)
        labelStack.addArrangedSubview(titleLabel)

        let hStack = UIStackView(arrangedSubviews: [labelStack, nextButton, dismissButton])
        hStack.axis      = .horizontal
        hStack.spacing   = 28
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false

        blurView.contentView.addSubview(divider)
        blurView.contentView.addSubview(hStack)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            divider.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            hStack.topAnchor.constraint(equalTo: blurView.contentView.topAnchor, constant: 28),
            hStack.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: 36),
            hStack.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -36),
            hStack.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor, constant: -28),
        ])
    }

    private func setupActions() {
        nextButton.addTarget(self, action: #selector(nextTapped), for: .primaryActionTriggered)
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .primaryActionTriggered)
    }

    // MARK: - Actions

    @objc private func nextTapped() {
        hide(animated: true)
        onNext?()
    }

    @objc private func dismissTapped() {
        hide(animated: true)
        onDismiss?()
    }

    // MARK: - Show / Hide

    func show(in parentView: UIView, focusedIn viewController: UIViewController? = nil) {
        parentView.addSubview(self)

        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -80),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -80),
            widthAnchor.constraint(lessThanOrEqualToConstant: 780),
        ])

        alpha     = 0
        transform = CGAffineTransform(translationX: 0, y: 20)

        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut]
        ) {
            self.alpha     = 1
            self.transform = .identity
        } completion: { _ in
            // Явно перемещаем фокус на кнопку "Смотреть"
            let vc = viewController ?? parentView.window?.rootViewController
            vc?.setNeedsFocusUpdate()
            vc?.updateFocusIfNeeded()
        }
    }

    func hide(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn]) {
                self.alpha     = 0
                self.transform = CGAffineTransform(translationX: 0, y: 12)
            } completion: { _ in
                self.removeFromSuperview()
            }
        } else {
            removeFromSuperview()
        }
    }

    // MARK: - Focus

    override var canBecomeFocused: Bool { false }

    override var preferredFocusEnvironments: [UIFocusEnvironment] { [nextButton] }
}

// MARK: - _OverlayButton

final class _OverlayButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        configuration = makeConfig(focused: false)
        layer.cornerRadius = 14
        layer.cornerCurve  = .continuous
    }

    private func makeConfig(focused: Bool) -> UIButton.Configuration {
        var c = UIButton.Configuration.filled()
        c.baseBackgroundColor = focused
            ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)   // золотистый акцент при фокусе
            : UIColor(white: 1.0, alpha: 0.18)
        c.baseForegroundColor = focused ? .black : .white
        c.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        c.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attr in
            var a = attr
            a.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
            return a
        }
        return c
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            let focused = self.isFocused
            self.configuration = self.makeConfig(focused: focused)
            self.transform = focused
                ? CGAffineTransform(scaleX: 1.06, y: 1.06)
                : .identity
        }
    }

    override var canBecomeFocused: Bool { true }
}

// MARK: - _OverlayDismissButton

final class _OverlayDismissButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        configuration = makeConfig(focused: false)
    }

    private func makeConfig(focused: Bool) -> UIButton.Configuration {
        var c = UIButton.Configuration.plain()
        c.image = UIImage(systemName: "xmark.circle.fill",
                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium))
        c.baseForegroundColor = focused
            ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
            : UIColor(white: 1.0, alpha: 0.45)
        c.contentInsets = .zero
        return c
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            self.configuration = self.makeConfig(focused: self.isFocused)
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.15, y: 1.15)
                : .identity
        }
    }

    override var canBecomeFocused: Bool { true }
}
