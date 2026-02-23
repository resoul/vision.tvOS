import Foundation
import Alamofire

struct FilmixSuggestion {
    let id: Int
    let title: String
    let year: Int
    let link: String
    let poster: String
    let lastSerie: String
    let categories: String
    let letter: String

    var isSeries: Bool { !lastSerie.isEmpty }
    var cleanCategories: String {
        categories.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
    var path: String {
        guard let url = URL(string: link) else { return link }
        return url.path
    }
}

private struct _SuggestionsResponse: nonisolated Decodable {
    let posts: [_SuggestionPost]
}

private struct _SuggestionPost: Decodable {
    let id: Int
    let title: String
    let year: Int
    let link: String
    let poster: String
    let last_serie: String
    let categories: String
    let letter: String

    enum CodingKeys: String, CodingKey {
        case id, title, year, link, poster, letter, categories
        case last_serie
    }
}

extension FilmixService {
    func fetchSuggestions(query: String,
                          completion: @escaping (Result<[FilmixSuggestion], Error>) -> Void) {
        completion(.success([]))
    }

    private static let searchHeaders: HTTPHeaders = [
        "x-requested-with": "XMLHttpRequest",
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
        "origin": "https://filmix.my",
        "referer": "https://filmix.my/search/",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"
    ]

    func fetchSearchResults(query: String,
                            completion: @escaping (Result<FilmixPage, Error>) -> Void) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            completion(.success(FilmixPage(movies: [], nextPageURL: nil)))
            return
        }

        let url = "\(baseURL)/engine/ajax/sphinx_search.php"
        let params: [String: String] = [
            "scf":          "fx",
            "story":        trimmed,
            "search_start": "0",
            "do":           "search",
            "subaction":    "search",
            "years_ot":     "1902",
            "years_do":     "2026",
            "kpi_ot":       "1",
            "kpi_do":       "10",
            "imdb_ot":      "1",
            "imdb_do":      "10",
            "sort_name":    "",
            "sort_date":    "",
            "sort_favorite":"",
            "simple":       "1"
        ]

        session.request(
            url,
            method: .post,
            parameters: params,
            encoding: URLEncoding.httpBody,
            headers: Self.searchHeaders
        ).responseData { response in
            switch response.result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    let html  = FilmixService.decode(data)
                    let page  = try FilmixService.parseListing(html: html)
                    completion(.success(page))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}
