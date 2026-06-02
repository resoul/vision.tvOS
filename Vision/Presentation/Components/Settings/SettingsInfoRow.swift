import UIKit

final class SettingsInfoRow: SettingsRowBase {
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.medium, size: 28)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.regular, size: 26)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    override var canBecomeFocused: Bool { false }
    
    init(title: String, value: String) {
        super.init(frame: .zero)
        setupUI(title: title, value: value)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(title: String, value: String) {
        titleLabel.text = title

        valueLabel.text = value
        
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func updateValue(_ value: String) {
        valueLabel.text = value
    }
    
    override func updateColors(style: ThemeStyle) {
        super.updateColors(style: style)
        titleLabel.textColor = style.textPrimary
        valueLabel.textColor = style.textSecondary
    }
}

final class SettingsHintRow: UIView {
    private let label: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.regular, size: 22)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    init(text: String) {
        super.init(frame: .zero)
        setupUI(text: text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(text: String) {
        label.text = text
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func updateColors(style: ThemeStyle) {
        label.textColor = style.textSecondary.withAlphaComponent(0.7)
    }
}
