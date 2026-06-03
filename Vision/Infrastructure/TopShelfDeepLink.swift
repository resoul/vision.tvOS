import Foundation

struct TopShelfDeepLink {
    let id: Int
    let title: String
    let type: String
    let movieURL: String
    let posterURL: String

    init?(url: URL) {
        guard url.scheme == "vision", url.host == "movie" else { return nil }

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(for name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard
            let idValue = value(for: "id"),
            let id = Int(idValue),
            let movieURL = value(for: "url"),
            !movieURL.isEmpty
        else {
            return nil
        }

        self.id = id
        self.title = value(for: "title") ?? ""
        self.type = value(for: "type") ?? "movie"
        self.movieURL = movieURL
        self.posterURL = value(for: "poster") ?? ""
    }
}
