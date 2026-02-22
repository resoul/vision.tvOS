import UIKit

final class ThinLine: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame); translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.07)
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
}
