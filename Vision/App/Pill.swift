import UIKit

final class Pill: UIView {
    init(text: String, color: UIColor, cornerRadius: CGFloat = 8, fontSize: CGFloat = 22) {
        super.init(frame: .zero)
        backgroundColor = color;
        layer.cornerRadius = cornerRadius;
        layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        
        let l = UILabel();
        l.text = text;
        l.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        l.textColor = .white;
        l.translatesAutoresizingMaskIntoConstraints = false;
        addSubview(l)
        
        NSLayoutConstraint.activate([
            l.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            l.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            l.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            l.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
