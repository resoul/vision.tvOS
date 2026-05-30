import Alamofire
import Foundation

final class FilmixMovieRepository: FilmixMovieRepositoryProtocol {
    private let client: FilmixNetworkClient
    
    init(client: FilmixNetworkClient) {
        self.client = client
    }
    
    private static let searchHeaders: HTTPHeaders = [
        "x-requested-with": "XMLHttpRequest",
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
        "origin": "https://filmix.my",
        "referer": "https://filmix.my/search/",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"
    ]
    
    func search(query: String) async throws -> ContentPage {
        let url = "\(client.baseURL)/engine/ajax/sphinx_search.php"
        let params: Parameters = [
            "scf": "fx",
            "story": query,
            "search_start": "0",
            "do": "search",
            "subaction": "search",
            "years_ot": "1902",
            "years_do": "2026",
            "kpi_ot": "1",
            "kpi_do": "10",
            "imdb_ot": "1",
            "imdb_do": "10",
            "sort_name": "",
            "sort_date": "",
            "sort_favorite": "",
            "simple": "1"
        ]

        let data = try await client.post(url: url, parameters: params, headers: Self.searchHeaders)
        let dto = try FilmixHTMLParser.parseListing(html: FilmixHTMLParser.decodeData(data))
        return dto.toEntity()
    }
    
    func fetchTranslations(postId: Int, isSeries: Bool) async throws -> [Translation] {
        let ts = Int(Date().timeIntervalSince1970)
        let url = "\(client.baseURL)/api/movies/player-data?t=\(ts)"
        let params: Parameters = ["post_id": "\(postId)", "showfull": "true"]
        let headers: HTTPHeaders = [
            "x-requested-with": "XMLHttpRequest",
            "Cookie": client.cookiesString(for: client.baseURL),
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"
        ]

        let dto: FilmixVideoDTO = try await client.postDecodable(url: url, parameters: params, headers: headers)
        let entries = dto.message.translations.video.sorted { $0.key < $1.key }

        if isSeries {
            let dtos = try await resolveSeriesTranslations(entries: entries)
            return dtos.map { $0.toEntity() }
        }

        return entries.compactMap { studio, encoded in
            let raw = FilmixStreamDecoder.decodeTokens(encoded)
            let parts = raw.split(separator: ",").map(String.init)
            let streams = FilmixStreamDecoder.decodeQualityMap(from: parts)
            guard !streams.isEmpty else { return nil }
            return FilmixTranslationDTO(studio: studio, streams: streams, seasons: []).toEntity()
        }
    }
    
    func fetchDetail(path: String) async throws -> ContentDetail {
        let url = path.hasPrefix("http") ? path : "\(client.baseURL)\(path)"
        let data = try await client.get(url: url)
        let dto = try FilmixHTMLParser.parseDetail(html: FilmixHTMLParser.decodeData(data))
        return dto.toDetailEntity()
    }
    
    func fetchPage(url: URL?) async throws -> ContentPage {
        let target = url?.absoluteString ?? client.baseURL
        let data = try await client.get(url: target)
        let dto = try FilmixHTMLParser.parseListing(html: FilmixHTMLParser.decodeData(data))
        return dto.toEntity()
    }
    
    private func resolveSeriesTranslations(entries: [(key: String, value: String)]) async throws -> [FilmixTranslationDTO] {
        let client = self.client

        return try await withThrowingTaskGroup(of: FilmixTranslationDTO?.self) { group in
            for (studio, encoded) in entries {
                group.addTask {
                    let secondURL = FilmixStreamDecoder.decodeTokens(encoded)
                    guard !secondURL.isEmpty else { return nil }

                    let string = try await client.getString(url: secondURL)
                    let json = FilmixStreamDecoder.decodeTokens(string)

                    guard
                        let data = json.data(using: .utf8),
                        let serials = try? JSONDecoder().decode([FilmixSerialDTO].self, from: data)
                    else {
                        return nil
                    }

                    let seasons: [FilmixSeasonDTO] = serials.map { serial in
                        let episodes: [FilmixEpisodeDTO] = serial.folder.map { folder in
                            let streams = FilmixStreamDecoder.decodeQualityMap(
                                from: folder.file.split(separator: ",").map(String.init)
                            )
                            return FilmixEpisodeDTO(title: folder.title, id: folder.id, streams: streams)
                        }
                        return FilmixSeasonDTO(title: serial.title, episodes: episodes)
                    }

                    return FilmixTranslationDTO(studio: studio, streams: [:], seasons: seasons)
                }
            }

            var results: [FilmixTranslationDTO] = []
            for try await translation in group {
                if let translation {
                    results.append(translation)
                }
            }
            return results.sorted { $0.studio < $1.studio }
        }
    }
}
