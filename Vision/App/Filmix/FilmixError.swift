import Foundation

enum FilmixError: LocalizedError {
    case articleNotFound

    var errorDescription: String? {
        switch self {
        case .articleNotFound: return "Can not find article. Try to reload the page or try another search query."
        }
    }
}
