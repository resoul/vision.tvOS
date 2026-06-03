import Foundation
import TVServices
import Filmix

final class ContentProvider: TVTopShelfContentProvider {
    private let service: FilmixService = FilmixServiceImpl()
    private enum Constants {
        static let feedPath = "https://filmix.my/"
        static let appName = "Vision"
        static let deepLinkScheme = "vision"
        static let maxItems = 10
    }

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        Task {
            do {
                let dto = try await service.fetchPage(url: URL(string: Constants.feedPath))
                let items = dto.movies.prefix(Constants.maxItems).map { toSectionItem(dto: $0) }

                guard !items.isEmpty else {
                    completionHandler(nil)
                    return
                }

                let section = TVTopShelfItemCollection(items: items)
                section.title = Constants.appName
                completionHandler(TVTopShelfSectionedContent(sections: [section]))
            } catch {
                completionHandler(nil)
            }
        }
    }
    
    private func toSectionItem(dto: FilmixMovieDTO) -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: String(dto.id))
        item.title = dto.title
        item.imageShape = .poster
        
        if let imageURL = URL(string: dto.posterURL) {
            item.setImageURL(imageURL, for: .screenScale1x)
            item.setImageURL(imageURL, for: .screenScale2x)
        }
        
        guard let actionURL = makeActionURL(dto: dto) else {
            return item
        }
        
        let action = TVTopShelfAction(url: actionURL)
        item.displayAction = action
        item.playAction = action
        return item
    }

    private func makeActionURL(dto: FilmixMovieDTO) -> URL? {
        var components = URLComponents()
        components.scheme = Constants.deepLinkScheme
        components.host = "movie"
        let type: String = dto.type.isSeries ? "series" : "movie"
        
        components.queryItems = [
            URLQueryItem(name: "id", value: String(dto.id)),
            URLQueryItem(name: "title", value: dto.title),
            URLQueryItem(name: "url", value: dto.movieURL),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "poster", value: dto.posterURL)
        ]
        
        return components.url
    }
}
