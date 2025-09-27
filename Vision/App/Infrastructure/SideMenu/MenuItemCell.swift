import UIKit

class MenuItemCell: UITableViewCell {
    
    let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        return label
    }()
    
    private var iconLeadingConstraint: NSLayoutConstraint!
    private var iconCenterConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        iconLeadingConstraint = iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        iconCenterConstraint = iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with title: String, icon: String, isExpanded: Bool) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: icon)
        
        if isExpanded {
            titleLabel.isHidden = false
            iconLeadingConstraint.isActive = true
            iconCenterConstraint.isActive = false
        } else {
            titleLabel.isHidden = true
            iconLeadingConstraint.isActive = false
            iconCenterConstraint.isActive = true
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            } else {
                self.backgroundColor = .clear
            }
        }, completion: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.transform = .identity
    }
}
