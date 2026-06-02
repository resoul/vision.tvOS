import UIKit

final class SettingsValueRow: SettingsRowBase {
    private let iconView: UIImageView = {
        let iv = UIImageView()
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
        l.font = .montserrat(.regular, size: 26)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    var valueText: String? {
        valueLabel.text
    }

    
    private let chevron: UILabel = {
        let l = UILabel()
        l.text = "›"
        l.font = .montserrat(.light, size: 30)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    init(title: String, icon: String? = nil, value: String? = nil) {
        super.init(frame: .zero)
        setupUI()
        configure(title: title, icon: icon, value: value)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(chevron)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    
    func configure(title: String, icon: String?, value: String?) {
        titleLabel.text = title
        if let icon = icon {
            iconView.image = UIImage(systemName: icon)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
        valueLabel.text = value
    }
    
    func updateValue(_ value: String) {
        valueLabel.text = value
    }
    
    override func updateColors(style: ThemeStyle) {
        super.updateColors(style: style)
        titleLabel.textColor = style.textPrimary
        iconView.tintColor = style.textPrimary
        valueLabel.textColor = isFocused ? style.textPrimary : style.textSecondary
        chevron.textColor = isFocused ? style.textPrimary.withAlphaComponent(0.8) : style.textSecondary.withAlphaComponent(0.5)
    }
}
