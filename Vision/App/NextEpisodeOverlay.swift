import UIKit

// MARK: - NextEpisodeOverlay
// Показывается поверх AVPlayerViewController когда просмотрено 95–99% эпизода.
// Автоматически переходит к следующей серии через countdownSeconds (по умолчанию 10).

final class NextEpisodeOverlay: UIView {

    var onNext:   (() -> Void)?
    var onDismiss: (() -> Void)?

    private let countdownTotal: Int
    private var countdownRemaining: Int
    private var countdownTimer: Timer?

    // MARK: - Subviews

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 0.95)
        v.layer.cornerRadius = 20
        v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 1, alpha: 0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.text = "Следующая серия"
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var nextButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(red: 0.23, green: 0.62, blue: 0.96, alpha: 1)
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 28, bottom: 14, trailing: 28)
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(nextTapped), for: .primaryActionTriggered)
        return b
    }()

    private lazy var skipButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = UIColor(white: 0.50, alpha: 1)
        config.title = "Пропустить"
        let b = UIButton(configuration: config)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(skipTapped), for: .primaryActionTriggered)
        return b
    }()

    // Circular countdown ring
    private let ringLayer = CAShapeLayer()
    private let ringTrackLayer = CAShapeLayer()

    private let countdownNumberLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        l.textColor = UIColor(red: 0.23, green: 0.62, blue: 0.96, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let ringContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Init

    init(nextTitle: String, countdown: Int = 10) {
        self.countdownTotal     = countdown
        self.countdownRemaining = countdown
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        alpha = 0

        titleLabel.text = nextTitle
        updateButtonTitle()
        buildLayout()
        buildRing()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func buildLayout() {
        addSubview(containerView)
        containerView.addSubview(hintLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(ringContainerView)
        containerView.addSubview(nextButton)
        containerView.addSubview(skipButton)
        ringContainerView.addSubview(countdownNumberLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            hintLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 28),
            hintLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 28),

            titleLabel.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: ringContainerView.leadingAnchor, constant: -16),

            ringContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            ringContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -28),
            ringContainerView.widthAnchor.constraint(equalToConstant: 64),
            ringContainerView.heightAnchor.constraint(equalToConstant: 64),

            countdownNumberLabel.centerXAnchor.constraint(equalTo: ringContainerView.centerXAnchor),
            countdownNumberLabel.centerYAnchor.constraint(equalTo: ringContainerView.centerYAnchor),

            nextButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            nextButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 28),
            nextButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),

            skipButton.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor),
            skipButton.leadingAnchor.constraint(equalTo: nextButton.trailingAnchor, constant: 16),
        ])
    }

    private func buildRing() {
        let rect = CGRect(x: 0, y: 0, width: 64, height: 64)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius: CGFloat = 26
        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: -.pi / 2, endAngle: .pi * 1.5,
                                clockwise: true)

        ringTrackLayer.path        = path.cgPath
        ringTrackLayer.fillColor   = UIColor.clear.cgColor
        ringTrackLayer.strokeColor = UIColor(white: 1, alpha: 0.10).cgColor
        ringTrackLayer.lineWidth   = 4

        ringLayer.path        = path.cgPath
        ringLayer.fillColor   = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor(red: 0.23, green: 0.62, blue: 0.96, alpha: 1).cgColor
        ringLayer.lineWidth   = 4
        ringLayer.lineCap     = .round
        ringLayer.strokeEnd   = 1.0

        ringContainerView.layer.addSublayer(ringTrackLayer)
        ringContainerView.layer.addSublayer(ringLayer)
    }

    // MARK: - Public API

    func show(in parent: UIView) {
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -40),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -60),
            widthAnchor.constraint(equalToConstant: 440),
        ])
        parent.layoutIfNeeded()

        UIView.animate(withDuration: 0.30, delay: 0,
                       usingSpringWithDamping: 0.80, initialSpringVelocity: 0.2) {
            self.alpha = 1
        }
        startCountdown()
    }

    func hide(animated: Bool = true) {
        stopCountdown()
        if animated {
            UIView.animate(withDuration: 0.20) { self.alpha = 0 } completion: { _ in
                self.removeFromSuperview()
            }
        } else {
            alpha = 0
            removeFromSuperview()
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        countdownRemaining = countdownTotal
        updateCountdownUI()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.countdownRemaining -= 1
            self.updateCountdownUI()
            if self.countdownRemaining <= 0 {
                self.nextTapped()
            }
        }
    }

    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateCountdownUI() {
        countdownNumberLabel.text = "\(countdownRemaining)"
        updateButtonTitle()

        // Animate ring strokeEnd
        let fraction = CGFloat(countdownRemaining) / CGFloat(countdownTotal)
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.toValue   = fraction
        anim.duration  = 0.9
        anim.fillMode  = .forwards
        anim.isRemovedOnCompletion = false
        ringLayer.add(anim, forKey: "countdown")
        ringLayer.strokeEnd = fraction
    }

    private func updateButtonTitle() {
        var config = nextButton.configuration ?? UIButton.Configuration.filled()
        config.title = "▶  Следующая серия"
        nextButton.configuration = config
    }

    // MARK: - Actions

    @objc private func nextTapped() {
        hide()
        onNext?()
    }

    @objc private func skipTapped() {
        hide()
        onDismiss?()
    }
}
