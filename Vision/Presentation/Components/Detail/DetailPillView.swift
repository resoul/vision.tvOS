import UIKit

final class DetailPillView: UIView {
    private let label = UILabel()
    var text: String? { label.text }
    
    init(text: String, color: UIColor) {
        super.init(frame: .zero)
        setup(text: text, color: color)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup(text: String, color: UIColor) {
        backgroundColor = color
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        
        label.text = text
        label.font = .montserrat(.bold, size: 22)
        label.textColor = .white
        
        addSubview(label)
        label.constraints(
            top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor,
            padding: .init(top: 4, left: 12, bottom: 4, right: 12)
        )
    }
}
