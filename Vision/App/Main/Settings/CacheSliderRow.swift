import UIKit

final class CacheSliderRow: UIView {
    
    var onChange: ((Int) -> Void)?
    private let steps = CacheSettings.steps
    private var currentStep: Int {
        didSet { updateUI() }
    }

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "memorychip.fill")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Лимит кэша в памяти"
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let trackBg: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.10)
        v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let trackFill: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var trackFillWidthConstraint: NSLayoutConstraint!

    private let dotsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 14
        v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(stepIndex: Int) {
        self.currentStep = stepIndex
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 110).isActive = true
        build()
        updateUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        addSubview(bg)
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(trackBg)
        trackBg.addSubview(trackFill)
        addSubview(dotsStack)

        for i in 0..<steps.count {
            let dot = DotView()
            dot.tag = i
            dotsStack.addArrangedSubview(dot)
        }

        trackFillWidthConstraint = trackFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            iconView.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 24),
            iconView.topAnchor.constraint(equalTo: bg.topAnchor, constant: 22),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -24),
            valueLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),

            trackBg.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 24),
            trackBg.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -24),
            trackBg.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -22),
            trackBg.heightAnchor.constraint(equalToConstant: 6),

            trackFill.leadingAnchor.constraint(equalTo: trackBg.leadingAnchor),
            trackFill.topAnchor.constraint(equalTo: trackBg.topAnchor),
            trackFill.bottomAnchor.constraint(equalTo: trackBg.bottomAnchor),
            trackFillWidthConstraint,

            dotsStack.leadingAnchor.constraint(equalTo: trackBg.leadingAnchor),
            dotsStack.trailingAnchor.constraint(equalTo: trackBg.trailingAnchor),
            dotsStack.centerYAnchor.constraint(equalTo: trackBg.centerYAnchor),
        ])
    }

    private func updateUI() {
        let step = steps[currentStep]
        valueLabel.text = step.label

        layoutIfNeeded()
        let totalW = trackBg.bounds.width
        let fraction: CGFloat = steps.count > 1
            ? CGFloat(currentStep) / CGFloat(steps.count - 1)
            : 1
        trackFillWidthConstraint.constant = totalW * fraction

        UIView.animate(withDuration: 0.20, delay: 0,
                       usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.layoutIfNeeded()
        }

        for (i, dotView) in dotsStack.arrangedSubviews.enumerated() {
            guard let dot = dotView as? DotView else { continue }
            dot.setActive(i <= currentStep, isCurrent: i == currentStep)
        }

        let isUnlimited = step.bytes == 0
        valueLabel.textColor = isUnlimited
            ? UIColor(red: 0.4, green: 0.85, blue: 0.55, alpha: 1)
            : UIColor(white: 0.55, alpha: 1)
    }

    override var canBecomeFocused: Bool { true }
    override func didUpdateFocus(in ctx: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.12) : .clear
            self.trackFill.backgroundColor = self.isFocused
                ? UIColor(red: 0.4, green: 0.75, blue: 1.0, alpha: 1) : .white
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }, completion: nil)
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            switch press.type {
            case .leftArrow:
                if currentStep > 0 {
                    currentStep -= 1
                    onChange?(currentStep)
                }
                handled = true
            case .rightArrow:
                if currentStep < steps.count - 1 {
                    currentStep += 1
                    onChange?(currentStep)
                }
                handled = true
            default:
                break
            }
        }
        if !handled { super.pressesBegan(presses, with: event) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let arrows = presses.filter { $0.type == .leftArrow || $0.type == .rightArrow }
        if arrows.isEmpty { super.pressesEnded(presses, with: event) }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        let arrows = presses.filter { $0.type == .leftArrow || $0.type == .rightArrow }
        if arrows.isEmpty { super.pressesCancelled(presses, with: event) }
    }
}
