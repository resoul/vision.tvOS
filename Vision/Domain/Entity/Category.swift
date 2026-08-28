import Foundation

struct Category: Identifiable, Hashable {
    let id: String
    let title: String
    let url: String
    let icon: String
    let kind: Kind
    var genres: [Genre] = []

    enum Kind: Hashable {
        case home
        case movies
        case series
        case cartoons
        case tvShows
        case favorites
        case watchHistory
    }

    static var defaultCategories: [Category] {[
        Category(id: "home",
                 title: L10n.Tab.home,
                 url: "",
                 icon: "house.fill",
                 kind: .home),

        Category(id: "movies",
                 title: L10n.Tab.movies,
                 url: "",
                 icon: "film.fill",
                 kind: .movies,
                 genres: Genre.movies),

        Category(id: "series",
                 title: L10n.Tab.series,
                 url: "",
                 icon: "tv.fill",
                 kind: .series,
                 genres: Genre.series),

        Category(id: "cartoons",
                 title: L10n.Tab.cartoons,
                 url: "",
                 icon: "sparkles.tv.fill",
                 kind: .cartoons,
                 genres: Genre.cartoons),

        Category(id: "favorites",
                 title: L10n.Tab.favorites,
                 url: "favorites://",
                 icon: "star.fill",
                 kind: .favorites),

        Category(id: "history",
                 title: L10n.Tab.watchHistory,
                 url: "history://",
                 icon: "play.circle.fill",
                 kind: .watchHistory),
    ]}
}
