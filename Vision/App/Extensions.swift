import UIKit

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}

extension UIColor {
    func lighter(by f: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r + (1-r)*f, 1), green: min(g + (1-g)*f, 1), blue: min(b + (1-b)*f, 1), alpha: a)
    }
}
