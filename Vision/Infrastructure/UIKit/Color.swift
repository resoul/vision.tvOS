import UIKit

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255
        let b = CGFloat(rgb & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
    
    func lighter(by f: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r + (1-r)*f, 1), green: min(g + (1-g)*f, 1), blue: min(b + (1-b)*f, 1), alpha: a)
    }

    var isDark: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.5
    }

    var isLight: Bool { !isDark }
}
