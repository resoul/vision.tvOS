import UIKit

final class DotView: UIView {
    private let circle: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(circle)
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 10),
            circle.heightAnchor.constraint(equalToConstant: 10),
            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: 10),
            heightAnchor.constraint(equalToConstant: 10),
        ])
        setActive(false, isCurrent: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setActive(_ active: Bool, isCurrent: Bool) {
        if isCurrent {
            circle.backgroundColor = .white
            circle.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        } else if active {
            circle.backgroundColor = UIColor(white: 0.75, alpha: 1)
            circle.transform = .identity
        } else {
            circle.backgroundColor = UIColor(white: 0.25, alpha: 1)
            circle.transform = .identity
        }
    }
}
