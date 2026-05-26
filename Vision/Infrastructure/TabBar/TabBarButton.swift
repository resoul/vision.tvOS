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
        iconView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        accentDot.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: item.icon)
        iconView.tintColor = config.inactiveColor
        label.text = item.title
        label.font = .montserrat(.semiBold, size: 24)
        accentDot.backgroundColor = .white
        accentDot.layer.cornerRadius = 3
        addSubview(iconView)
        addSubview(label)
        addSubview(accentDot)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -18),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            accentDot.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentDot.centerXAnchor.constraint(equalTo: centerXAnchor),
            accentDot.widthAnchor.constraint(equalToConstant: 20),
            accentDot.heightAnchor.constraint(equalToConstant: 4),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -12),
        ])
        updateLook(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func applyFocusAppearance(focused: Bool) {
        label.textColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : config.inactiveColor)
        iconView.tintColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : config.inactiveColor)
        
        // Use active color for focus background with low alpha
        let bgAlpha = focused ? config.focusedBgAlpha : (isActiveTab ? 0.08 : 0)
        let bgColor = focused ? config.activeColor : (isActiveTab ? config.activeColor : .clear)
        bgView.backgroundColor = bgColor.withAlphaComponent(bgAlpha)
    }

    private func updateLook(animated: Bool) {
        let block = {
            self.label.textColor = self.isActiveTab ? self.config.activeColor : self.config.inactiveColor
            self.iconView.tintColor = self.isActiveTab ? self.config.activeColor : self.config.inactiveColor
            self.label.font = UIFont.systemFont(ofSize: 24, weight: self.isActiveTab ? .bold : .semibold)
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
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "gearshape.fill")
        addSubview(iconView)
        NSLayoutConstraint.activate([
            bgView.widthAnchor.constraint(equalToConstant: 52),
            bgView.heightAnchor.constraint(equalToConstant: 48),
            iconView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
        ])
        applyFocusAppearance(focused: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        iconView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: "magnifyingglass")
        label.text = searchTitle
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        addSubview(iconView)
        addSubview(label)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -18),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
        ])
        applyFocusAppearance(focused: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = genre.title
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -10),
        ])
        updateLook(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
