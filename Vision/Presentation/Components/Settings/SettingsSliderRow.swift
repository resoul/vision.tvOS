import UIKit

final class SettingsSliderRow: SettingsRowBase {
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "memorychip")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.medium, size: 28)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.bold, size: 26)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let trackView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let progressView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 3
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private var progressWidthConstraint: NSLayoutConstraint?
    
    private var steps: [String] = []
    private var currentIndex: Int = 0
    
    var onValueChange: ((Int) -> Void)?
    
    init(title: String, steps: [String], initialIndex: Int) {
        self.steps = steps
        self.currentIndex = initialIndex
        super.init(frame: .zero)
        setupUI(title: title)
        updateValue()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(title: String) {
        titleLabel.text = title
        
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(trackView)
        trackView.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            trackView.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -30),
            trackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackView.widthAnchor.constraint(equalToConstant: 200),
            trackView.heightAnchor.constraint(equalToConstant: 6),
            
            progressView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            progressView.topAnchor.constraint(equalTo: trackView.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor)
        ])
        
        progressWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
        progressWidthConstraint?.isActive = true
    }
    
    private func updateValue() {
        guard currentIndex < steps.count else { return }
        valueLabel.text = steps[currentIndex]
        
        let progress = CGFloat(currentIndex) / CGFloat(max(1, steps.count - 1))
        progressWidthConstraint?.constant = 200 * progress
        
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
    
    func setIndex(_ index: Int) {
        currentIndex = max(0, min(index, steps.count - 1))
        updateValue()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard isFocused else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        for press in presses {
            switch press.type {
            case .leftArrow:
                if currentIndex > 0 {
                    currentIndex -= 1
                    updateValue()
                    onValueChange?(currentIndex)
                }
            case .rightArrow:
                if currentIndex < steps.count - 1 {
                    currentIndex += 1
                    updateValue()
                    onValueChange?(currentIndex)
                }
            default:
                super.pressesBegan(presses, with: event)
            }
        }
    }
    
    override func updateColors(style: ThemeStyle) {
        super.updateColors(style: style)
        titleLabel.textColor = style.textPrimary
        iconView.tintColor = style.textPrimary
        valueLabel.textColor = style.accent
        trackView.backgroundColor = style.textSecondary.withAlphaComponent(0.2)
        progressView.backgroundColor = style.accent
    }
}
