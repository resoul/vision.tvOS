import UIKit

struct ThemeStyle {
    let background: UIColor
    let surface: UIColor
    let accent: UIColor
    let textPrimary: UIColor
    let textSecondary: UIColor
}

extension Theme {
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark, .midnight:
            return .dark
        }
    }

    var style: ThemeStyle {
        switch self {
        case .dark:
            return ThemeStyle(
                background: UIColor(hex: "#0D0D0D"),
                surface: UIColor(hex: "#1C1C1E"),
                accent: UIColor(hex: "#0A84FF"),
                textPrimary: UIColor(hex: "#FFFFFF"),
                textSecondary: UIColor(hex: "#8E8E93")
            )
        case .light:
            return ThemeStyle(
                background: UIColor(hex: "#F2F2F7"),
                surface: UIColor(hex: "#FFFFFF"),
                accent: UIColor(hex: "#007AFF"),
                textPrimary: UIColor(hex: "#000000"),
                textSecondary: UIColor(hex: "#6C6C70")
            )
        case .midnight:
            return ThemeStyle(
                background: UIColor(hex: "#0A0015"),
                surface: UIColor(hex: "#1A0030"),
                accent: UIColor(hex: "#BF5AF2"),
                textPrimary: UIColor(hex: "#FFFFFF"),
                textSecondary: UIColor(hex: "#9A9ABF")
            )
        }
    }
}
