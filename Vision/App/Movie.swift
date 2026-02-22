import UIKit

struct Movie {
    let id: Int
    let title: String
    let year: String
    let description: String
    let imageName: String
    let genre: String
    let rating: String
    let duration: String
    let type: ContentType
    let translate: String
    let isAdIn: Bool
    let audioTracks: [AudioTrack]

    let movieURL: String
    let posterURL: String
    let actors: [String]
    let directors: [String]
    let genreList: [String]
    let lastAdded: String?

    enum ContentType {
        case movie
        case series(seasons: [Season])
    }

    var accentColor: UIColor {
        let palette: [UIColor] = [
            UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1),
            UIColor(red: 0.10, green: 0.28, blue: 0.55, alpha: 1),
            UIColor(red: 0.35, green: 0.12, blue: 0.45, alpha: 1),
            UIColor(red: 0.08, green: 0.35, blue: 0.28, alpha: 1),
            UIColor(red: 0.50, green: 0.10, blue: 0.10, alpha: 1),
        ]
        return palette[abs(id) % palette.count]
    }
}

extension Movie {
    init(id: Int, title: String, year: String, description: String,
         imageName: String, genre: String, rating: String, duration: String,
         type: ContentType, audioTracks: [AudioTrack]) {
        self.init(id: id, title: title, year: year, description: description,
                  imageName: imageName, genre: genre, rating: rating, duration: duration,
                  type: type, translate: "", isAdIn: false, audioTracks: audioTracks,
                  movieURL: "", posterURL: "", actors: [], directors: [], genreList: [],
                  lastAdded: nil)
    }
}
