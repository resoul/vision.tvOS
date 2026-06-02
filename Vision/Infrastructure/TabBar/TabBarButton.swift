import UIKit

final class TabButton: TVFocusControl {
    var isActiveTab: Bool = false {
        didSet { updateLook(animated: true) }
    }

    private let config: TabBarConfiguration
    private let iconView = UIImageView()
    private let label = UILabel()
    private let accentDot = UIView()

    init(item: TabItem, config: TabBarConfiguration) {
        self.config = config
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: item.icon)
        iconView.tintColor = config.inactiveColor
        label.text = item.title
        label.font = .montserrat(.semiBold, size: 24)
        
        accentDot.backgroundColor = .white
        accentDot.layer.cornerRadius = 3
        addSubviews(iconView, label, accentDot)
        iconView.constraints(
            top: nil, leading: bgView.leadingAnchor, bottom: nil, trailing: nil,
            padding: .init(top: 0, left: 16, bottom: 0, right: 0),
            size: .init(width: 22, height: 22)
        )
        label.constraints(
            top: bgView.topAnchor, leading: iconView.trailingAnchor, bottom: bgView.bottomAnchor, trailing: bgView.trailingAnchor,
            padding: .init(top: 12, left: 10, bottom: 12, right: 18)
        )
        accentDot.constraints(
            top: nil, leading: nil, bottom: bottomAnchor, trailing: nil,
            size: .init(width: 20, height: 4)
        )
        
        NSLayoutConstraint.activate([
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            accentDot.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        
        updateLook(animated: false)
    }

    override func applyFocusAppearance(focused: Bool) {
        label.textColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : config.inactiveColor)
        iconView.tintColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : config.inactiveColor)
        
        let bgAlpha = focused ? config.focusedBgAlpha : (isActiveTab ? 0.08 : 0)
        let bgColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : .clear)
        bgView.backgroundColor = bgColor.withAlphaComponent(bgAlpha)
    }

    private func updateLook(animated: Bool) {
        let block = {
            self.label.textColor = self.isActiveTab ? self.config.activeColor : self.config.inactiveColor
            self.iconView.tintColor = self.isActiveTab ? self.config.activeColor : self.config.inactiveColor
            self.label.font = .montserrat(self.isActiveTab ? .bold : .semiBold, size: 24)
            self.accentDot.alpha = self.isActiveTab ? 1 : 0
            self.accentDot.backgroundColor = self.config.activeColor
            
            let bgAlpha: CGFloat = self.isActiveTab ? 0.08 : 0
            self.bgView.backgroundColor = self.config.activeColor.withAlphaComponent(bgAlpha)
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: block)
        } else {
            block()
        }
    }
}

final class SettingsButton: TVFocusControl {
    var canFocusAfterDismiss: Bool = true
    override var canBecomeFocused: Bool { canFocusAfterDismiss }
    private let config: TabBarConfiguration
    private let iconView = UIImageView()

    init(config: TabBarConfiguration) {
        self.config = config
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: "gearshape.fill")
        addSubview(iconView)
        
        iconView.constraints(
            top: nil, leading: nil, bottom: nil, trailing: nil,
            size: .init(width: 24, height: 24)
        )
        iconView.constraintToCenter(in: bgView)
        
        NSLayoutConstraint.activate([
            bgView.widthAnchor.constraint(equalToConstant: 52),
            bgView.heightAnchor.constraint(equalToConstant: 48),
        ])
        applyFocusAppearance(focused: false)
    }

    override func applyFocusAppearance(focused: Bool) {
        iconView.tintColor = focused ? config.activeColor : config.inactiveColor
    }
}

final class SearchButton: TVFocusControl {
    private let config: TabBarConfiguration
    private let iconView = UIImageView()
    private let label = UILabel()

    init(config: TabBarConfiguration, searchTitle: String) {
        self.config = config
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: "magnifyingglass")
        label.text = searchTitle
        label.font = .montserrat(.semiBold, size: 24)
        addSubviews(iconView, label)
        
        iconView.constraints(
            top: nil, leading: bgView.leadingAnchor, bottom: nil, trailing: nil,
            padding: .init(top: 0, left: 16, bottom: 0, right: 0),
            size: .init(width: 22, height: 22)
        )
        label.constraints(
            top: bgView.topAnchor, leading: iconView.trailingAnchor, bottom: bgView.bottomAnchor, trailing: bgView.trailingAnchor,
            padding: .init(top: 12, left: 10, bottom: 12, right: 18)
        )
        
        NSLayoutConstraint.activate([
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
        ])
        
        applyFocusAppearance(focused: false)
    }

    override func applyFocusAppearance(focused: Bool) {
        label.textColor = focused ? config.activeColor : config.inactiveColor
        iconView.tintColor = focused ? config.activeColor : config.inactiveColor
    }
}

final class GenreButton: TVFocusControl {
    var isActiveTab: Bool = false {
        didSet { updateLook(animated: true) }
    }

    private let config: TabBarConfiguration
    private let label = UILabel()

    init(genre: GenreItem, config: TabBarConfiguration) {
        self.config = config
        super.init(frame: .zero)
        label.text = genre.title
        label.font = .montserrat(.semiBold, size: 20)
        addSubview(label)
        
        label.constraints(
            top: bgView.topAnchor, leading: bgView.leadingAnchor, bottom: bgView.bottomAnchor, trailing: bgView.trailingAnchor,
            padding: .init(top: 10, left: 14, bottom: 10, right: 14)
        )

        updateLook(animated: false)
    }

    override func applyFocusAppearance(focused: Bool) {
        label.textColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : config.inactiveColor)
        
        let bgAlpha = focused ? config.focusedBgAlpha : (isActiveTab ? 0.08 : 0)
        let bgColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : .clear)
        bgView.backgroundColor = bgColor.withAlphaComponent(bgAlpha)
    }

    private func updateLook(animated: Bool) {
        let block = {
            self.label.textColor = self.isActiveTab ? self.config.activeColor : self.config.inactiveColor
            self.bgView.backgroundColor = self.config.activeColor.withAlphaComponent(self.isActiveTab ? 0.08 : 0)
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: block)
        } else {
            block()
        }
    }
}
