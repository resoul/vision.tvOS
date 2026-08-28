import Foundation

struct Genre: Hashable {
    let title: String
    let url: String

    static var movies: [Genre] {[
        Genre(title: L10n.Genre.Movies.action,      url: "https://filmix.my/film/?genre=action"),
        Genre(title: L10n.Genre.Movies.comedy,      url: "https://filmix.my/film/?genre=comedy"),
        Genre(title: L10n.Genre.Movies.drama,       url: "https://filmix.my/film/?genre=drama"),
        Genre(title: L10n.Genre.Movies.thriller,    url: "https://filmix.my/film/?genre=thriller"),
        Genre(title: L10n.Genre.Movies.horror,      url: "https://filmix.my/film/?genre=horror"),
        Genre(title: L10n.Genre.Movies.scifi,       url: "https://filmix.my/film/?genre=sci-fi"),
        Genre(title: L10n.Genre.Movies.fantasy,     url: "https://filmix.my/film/?genre=fantasy"),
        Genre(title: L10n.Genre.Movies.adventure,   url: "https://filmix.my/film/?genre=adventure"),
        Genre(title: L10n.Genre.Movies.animation,   url: "https://filmix.my/film/?genre=animation"),
        Genre(title: L10n.Genre.Movies.documentary, url: "https://filmix.my/film/?genre=documentary"),
        Genre(title: L10n.Genre.Movies.crime,       url: "https://filmix.my/film/?genre=crime"),
        Genre(title: L10n.Genre.Movies.romance,     url: "https://filmix.my/film/?genre=romance"),
        Genre(title: L10n.Genre.Movies.biography,   url: "https://filmix.my/film/?genre=biography"),
        Genre(title: L10n.Genre.Movies.history,     url: "https://filmix.my/film/?genre=history"),
        Genre(title: L10n.Genre.Movies.sport,       url: "https://filmix.my/film/?genre=sport"),
    ]}

    static var series: [Genre] {[
        Genre(title: L10n.Genre.Series.action,      url: "https://filmix.my/seria/?genre=action"),
        Genre(title: L10n.Genre.Series.comedy,      url: "https://filmix.my/seria/?genre=comedy"),
        Genre(title: L10n.Genre.Series.drama,       url: "https://filmix.my/seria/?genre=drama"),
        Genre(title: L10n.Genre.Series.thriller,    url: "https://filmix.my/seria/?genre=thriller"),
        Genre(title: L10n.Genre.Series.horror,      url: "https://filmix.my/seria/?genre=horror"),
        Genre(title: L10n.Genre.Series.scifi,       url: "https://filmix.my/seria/?genre=sci-fi"),
        Genre(title: L10n.Genre.Series.fantasy,     url: "https://filmix.my/seria/?genre=fantasy"),
        Genre(title: L10n.Genre.Series.crime,       url: "https://filmix.my/seria/?genre=crime"),
        Genre(title: L10n.Genre.Series.romance,     url: "https://filmix.my/seria/?genre=romance"),
        Genre(title: L10n.Genre.Series.anime,       url: "https://filmix.my/seria/?genre=anime"),
        Genre(title: L10n.Genre.Series.documentary, url: "https://filmix.my/seria/?genre=documentary"),
        Genre(title: L10n.Genre.Series.reality,     url: "https://filmix.my/seria/?genre=reality"),
    ]}

    static var cartoons: [Genre] {[
        Genre(title: L10n.Genre.Cartoons.kids,      url: "https://filmix.my/mults/?genre=kids"),
        Genre(title: L10n.Genre.Cartoons.anime,     url: "https://filmix.my/mults/?genre=anime"),
        Genre(title: L10n.Genre.Cartoons.adventure, url: "https://filmix.my/mults/?genre=adventure"),
        Genre(title: L10n.Genre.Cartoons.comedy,    url: "https://filmix.my/mults/?genre=comedy"),
        Genre(title: L10n.Genre.Cartoons.scifi,     url: "https://filmix.my/mults/?genre=sci-fi"),
        Genre(title: L10n.Genre.Cartoons.fantasy,   url: "https://filmix.my/mults/?genre=fantasy"),
        Genre(title: L10n.Genre.Cartoons.family,    url: "https://filmix.my/mults/?genre=family"),
        Genre(title: L10n.Genre.Cartoons.series,    url: "https://filmix.my/mults/?genre=series"),
    ]}
}
