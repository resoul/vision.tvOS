import UIKit

extension UIFont {
    static func amazon(_ style: Fonts.Amazon, size: CGFloat) -> UIFont? {
        return UIFont(name: style.rawValue, size: size)
    }

    static func montserrat(_ style: Fonts.Montserrat, size: CGFloat) -> UIFont? {
        return UIFont(name: style.rawValue, size: size)
    }

    static func roboto(_ style: Fonts.Roboto, size: CGFloat) -> UIFont? {
        return UIFont(name: style.rawValue, size: size)
    }

    static func poppins(_ style: Fonts.Poppins, size: CGFloat) -> UIFont? {
        return UIFont(name: style.rawValue, size: size)
    }

    static func lato(_ style: Fonts.Lato, size: CGFloat) -> UIFont? {
        return UIFont(name: style.rawValue, size: size)
    }

    static func amazonWithFallback(
        _ style: Fonts.Amazon,
        size: CGFloat,
        fallback: UIFont.Weight = .regular
    ) -> UIFont {
        return amazon(style, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallback)
    }

    static func montserratWithFallback(
        _ style: Fonts.Montserrat,
        size: CGFloat,
        fallback: UIFont.Weight = .regular
    ) -> UIFont {
        return montserrat(style, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallback)
    }

    static func robotoWithFallback(
        _ style: Fonts.Roboto,
        size: CGFloat,
        fallback: UIFont.Weight = .regular
    ) -> UIFont {
        return roboto(style, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallback)
    }

    static func poppinsWithFallback(
        _ style: Fonts.Poppins,
        size: CGFloat,
        fallback: UIFont.Weight = .regular
    ) -> UIFont {
        return poppins(style, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallback)
    }

    static func latoWithFallback(
        _ style: Fonts.Lato,
        size: CGFloat,
        fallback: UIFont.Weight = .regular
    ) -> UIFont {
        return lato(style, size: size) ?? UIFont.systemFont(ofSize: size, weight: fallback)
    }
}
