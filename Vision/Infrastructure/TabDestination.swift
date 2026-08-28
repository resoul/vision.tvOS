enum TabDestination: Equatable {
    case home
    case movies(path: String?)
    case series(path: String?)
    case cartoons(path: String?)
    case tvShows(path: String?)
    case favorites
    case watchHistory
}
