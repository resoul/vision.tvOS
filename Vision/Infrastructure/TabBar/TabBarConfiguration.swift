import UIKit

protocol TabBarDelegate: AnyObject {
    func tabBar(_ tabBar: TabBarView, didSelectItem item: TabItem)
    func tabBar(_ tabBar: TabBarView, didSelectGenre genre: GenreItem, inItem item: TabItem)
    func tabBarDidSelectSearch(_ tabBar: TabBarView)
    func tabBarDidSelectSettings(_ tabBar: TabBarView)
}

struct GenreItem: Equatable {
    let id: String
    let title: String
}

struct TabItem: Equatable {
    let id: String
    let title: String
    let icon: String
    let genres: [GenreItem]

    init(id: String, title: String, icon: String, genres: [GenreItem] = []) {
        self.id = id
        self.title = title
        self.icon = icon
        self.genres = genres
    }
}

struct TabBarConfiguration {
    var mainRowHeight: CGFloat
    var genreRowHeight: CGFloat
    var backgroundColor: UIColor
    var separatorColor: UIColor
    var activeColor: UIColor
    var inactiveColor: UIColor
    var focusedBgAlpha: CGFloat
    var items: [TabItem]

    static func standard(items: [TabItem], style: ThemeStyle) -> TabBarConfiguration {
        TabBarConfiguration(
            items: items,
            backgroundColor: style.background.withAlphaComponent(0.95),
            separatorColor: style.textPrimary.withAlphaComponent(0.08),
            activeColor: style.textPrimary,
            inactiveColor: style.textSecondary,
            focusedBgAlpha: 0.18
        )
    }

    init(
        items: [TabItem],
        mainRowHeight: CGFloat = 76,
        genreRowHeight: CGFloat = 58,
        backgroundColor: UIColor = UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 1),
        separatorColor: UIColor = UIColor(white: 1, alpha: 0.07),
        activeColor: UIColor = .white,
        inactiveColor: UIColor = UIColor(white: 0.45, alpha: 1),
        focusedBgAlpha: CGFloat = 0.18
    ) {
        self.items = items
        self.mainRowHeight = mainRowHeight
        self.genreRowHeight = genreRowHeight
        self.backgroundColor = backgroundColor
        self.separatorColor = separatorColor
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.focusedBgAlpha = focusedBgAlpha
    }
}
