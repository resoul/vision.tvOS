import UIKit

final class GradientView: UIView {
    private let colors: [CGColor]
    private let locations: [NSNumber]

    init(colors: [CGColor], locations: [NSNumber]) {
        self.colors = colors
        self.locations = locations
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let gradient = layer as? CAGradientLayer else { return }
        gradient.colors = colors
        gradient.locations = locations
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
    }
}
