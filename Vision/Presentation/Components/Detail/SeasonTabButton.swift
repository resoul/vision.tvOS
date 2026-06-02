import UIKit

final class SeasonTabButton: TVFocusControl {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    private var widthConstraint: NSLayoutConstraint?
    
    var isActive: Bool = false {
        didSet { updateAppearance() }
    }
    
    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        setup(title: title, subtitle: subtitle)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup(title: String, subtitle: String) {
        focusScale = 1.1 
        
        titleLabel.text = title
        titleLabel.font = .montserrat(.bold, size: 20)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = subtitle
        subtitleLabel.font = .montserrat(.regular, size: 12)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        widthConstraint = widthAnchor.constraint(equalToConstant: 160)
        
        NSLayoutConstraint.activate([
            widthConstraint!,
            heightAnchor.constraint(equalToConstant: 60),
            
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }
    
    func setThemeStyle(_ style: ThemeStyle) {
        updateAppearance()
    }
    
    private func updateAppearance() {
        let isFocused = self.isFocused
        
        bgView.layer.borderColor = isFocused ? UIColor.white.cgColor : UIColor.clear.cgColor
        bgView.layer.borderWidth = isFocused ? 4 : 0
        
        if isActive {
            bgView.backgroundColor = .systemBlue
            titleLabel.alpha = 1.0
            subtitleLabel.alpha = 0.8
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            // Bring to front so scaling doesn't go under other views
            superview?.bringSubviewToFront(self)
        } else {
            bgView.backgroundColor = isFocused ? UIColor.white.withAlphaComponent(0.2) : UIColor.white.withAlphaComponent(0.1)
            titleLabel.alpha = isFocused ? 1.0 : 0.7
            subtitleLabel.alpha = isFocused ? 0.8 : 0.4
            transform = isFocused ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
        }
    }
    
    override func applyFocusAppearance(focused: Bool) {
        updateAppearance()
    }
}
