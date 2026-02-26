import UIKit

struct PickerConfig {
    var widthFraction:  CGFloat = 0.50
    var heightFraction: CGFloat = 0.50
    var overlayAlpha:   CGFloat = 0.75
    var containerColor: UIColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
    var cornerRadius:   CGFloat = 24

    static let `default` = PickerConfig()
}
