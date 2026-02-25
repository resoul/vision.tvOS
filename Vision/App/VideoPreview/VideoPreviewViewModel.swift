import UIKit

struct VideoPreviewViewModel {
    let title: String
    let accentColor: UIColor
    let rating: String
    let year: String
    let genres: [String]
    let description: String
    let lastAdded: String?

    init(movie: Movie) {
        self.title       = movie.title
        self.accentColor = movie.accentColor
        self.rating      = "★ \(movie.rating)"
        self.year        = movie.year
        self.genres      = movie.genreList.isEmpty ? [movie.genre] : movie.genreList
        self.description = movie.description
        self.lastAdded   = movie.lastAdded
    }
}
