import Foundation

enum Theme: String, CaseIterable {
    case dark
    case light
    case midnight

    var displayName: String {
        switch self {
        case .dark:     return L10n.Settings.Theme.dark
        case .light:    return L10n.Settings.Theme.light
        case .midnight: return L10n.Settings.Theme.midnight
        }
    }
}
