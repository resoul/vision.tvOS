import UIKit

final class CategorySettingsButton: TVFocusControl {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "gearshape.fill")
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor(white: 0.45, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),

            bgView.widthAnchor.constraint(equalToConstant: 52),
            bgView.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func applyFocusAppearance(focused: Bool) {
        iconView.tintColor = focused ? .white : UIColor(white: 0.45, alpha: 1)
    }
}
