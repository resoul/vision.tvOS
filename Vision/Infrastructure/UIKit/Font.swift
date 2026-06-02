import UIKit

extension UIFont {
    static func montserrat(_ style: Fonts.Montserrat, size: CGFloat) -> UIFont? {
        return UIFont(name: style.rawValue, size: size)
    }

    static func montserratWithFallback(
        _ style: Fonts.Montserrat,
        size: CGFloat,
        fallback: UIFont.Weight = .regular
    ) -> UIFont {
        return montserrat(style, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallback)
    }
}
