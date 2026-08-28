import UIKit

final class BadgeView: UIView {
    private let label = UILabel()

    init(text: String, background: UIColor, font: UIFont) {
        super.init(frame: .zero)

        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        self.backgroundColor = background

        label.text = text
        label.textColor = .white
        label.font = font

        addSubview(label)
        label.constraints(
            top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor,
            padding: .init(top: 4, left: 6, bottom: 4, right: 6)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(text: String, background: UIColor? = nil) {
        label.text = text
        if let bg = background {
            self.backgroundColor = bg
        }
    }
}
