import UIKit

final class DetailInfoRow: UIView {
    private let keyLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        keyLabel.font = .montserrat(.regular, size: 24)
        keyLabel.textColor = UIColor(white: 1, alpha: 0.45)
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        valueLabel.font = .montserrat(.medium, size: 24)
        valueLabel.textColor = .white
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(keyLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyLabel.topAnchor.constraint(equalTo: topAnchor),
            
            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 12),
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func set(key: String, value: String, lines: Int = 1) {
        keyLabel.text = "\(key):"
        valueLabel.text = value
        valueLabel.numberOfLines = lines
        isHidden = value.isEmpty || value == "—"
    }
    
    func updateColors(textPrimary: UIColor, textSecondary: UIColor) {
        keyLabel.textColor = textSecondary
        valueLabel.textColor = textPrimary
    }
}
