import Foundation
import Alamofire

// MARK: - RezkaFetcher

final class RezkaFetcher {

    static let shared = RezkaFetcher()

    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"

    // Alamofire session with shared HTTPCookieStorage so cookies persist between requests
    private let session: Session = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        return Session(configuration: config)
    }()

    private let parser = RezkaParser()

    // MARK: - Search

    /// Search for films/series.
    /// - Parameters:
    ///   - query: search string, e.g. "Звёздные войны"
    ///   - page:  page number, starts at 1
    func search(
        baseURL: String = "https://rezka.ag",
        query: String,
        page: Int = 1,
        completion: @escaping (Result<[RezkaSearchResult], Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/search/")!
        components.queryItems = [
            URLQueryItem(name: "do",         value: "search"),
            URLQueryItem(name: "subaction",  value: "search"),
            URLQueryItem(name: "q",          value: query),
            URLQueryItem(name: "page",       value: page > 1 ? "\(page)" : nil)
        ].compactMap { $0.value != nil ? $0 : nil }

        guard let url = components.url else {
            completion(.failure(NSError(domain: "RezkaFetcher", code: -2,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])))
            return
        }

        let headers: HTTPHeaders = [
            "User-Agent":     userAgent,
            "Accept":         "text/html,application/xhtml+xml,*/*;q=0.9",
            "Accept-Language":"ru-RU,ru;q=0.9,en;q=0.8",
            "Referer":        baseURL
        ]

        session.request(url, headers: headers)
            .validate()
            .responseString(encoding: .utf8) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let html):
                    do {
                        let results = try self.parser.parseSearch(html: html)
                        DispatchQueue.main.async { completion(.success(results)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                case .failure(let error):
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
    }

    // MARK: - Fetch page

    /// Fetch a film/series page and parse it.
    /// - Parameters:
    ///   - url: Full page URL, e.g. "https://rezka.ag/films/horror/13885-vatikanskie-zapisi-2015.html"
    ///   - completion: Called on main thread with Result<RezkaPlayerData, Error>
    func fetchPlayerData(url: String, completion: @escaping (Result<RezkaPlayerData, Error>) -> Void) {
        let headers: HTTPHeaders = [
            "User-Agent": userAgent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
            "Referer": "https://rezka.ag/"
        ]

        session.request(url, headers: headers)
            .validate()
            .responseString(encoding: .utf8) { [weak self] response in
                guard let self else { return }
                switch response.result {
                case .success(let html):
                    do {
                        let data = try self.parser.parse(html: html)
                        DispatchQueue.main.async { completion(.success(data)) }
                    } catch {
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                case .failure(let error):
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
    }

    // MARK: - Get streams for a specific translator (AJAX)

    /// When user taps a different translator, call this to get fresh streams.
    /// - Parameters:
    ///   - baseURL:      e.g. "https://rezka.ag"
    ///   - movieId:      e.g. 13885
    ///   - translatorId: e.g. 391
    ///   - favs:         value from <input id="ctrl_favs"> parsed from page HTML
    ///   - isCamrip / isAds / isDirector: from the translator's data-* attributes
    ///   - completion:   [RezkaStream]
    func fetchStreams(
        baseURL: String = "https://rezka.ag",
        movieId: Int,
        translatorId: Int,
        favs: String,
        isCamrip: Bool = false,
        isAds: Bool = false,
        isDirector: Bool = false,
        completion: @escaping (Result<[RezkaStream], Error>) -> Void
    ) {
        // Timestamp param like the browser sends: ?t=<unix ms>
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        let fullURL = "\(baseURL)/ajax/get_cdn_series/?t=\(ts)"

        let parameters: [String: Any] = [
            "id":            movieId,
            "translator_id": translatorId,
            "is_camrip":     isCamrip ? 1 : 0,
            "is_ads":        isAds ? 1 : 0,
            "is_director":   isDirector ? 1 : 0,
            "favs":          favs,
            "action":        "get_movie"
        ]

        let headers: HTTPHeaders = [
            "User-Agent":         userAgent,
            "X-Requested-With":   "XMLHttpRequest",
            "Accept":             "application/json, text/javascript, */*; q=0.01",
            "Content-Type":       "application/x-www-form-urlencoded; charset=UTF-8",
            "Origin":             baseURL,
            "Referer":            baseURL
        ]

        session.request(
            fullURL,
            method: .post,
            parameters: parameters,
            encoding: URLEncoding.httpBody,
            headers: headers
        )
        .validate()
        .responseString { response in
            if let raw = response.value {
                print("📦 RAW AJAX:", raw.prefix(500))
            }
        }
        .responseDecodable(of: RezkaAjaxResponse.self) { [weak self] response in
            guard let self else { return }
            switch response.result {
            case .success(let ajaxResp):
                guard ajaxResp.success, let streamsRaw = ajaxResp.url else {
                    let msg = ajaxResp.message ?? "Unknown error"
                    let err = NSError(domain: "RezkaFetcher", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: msg])
                    DispatchQueue.main.async { completion(.failure(err)) }
                    return
                }
                let streams = self.parser.parseStreams(from: streamsRaw)
                DispatchQueue.main.async { completion(.success(streams)) }
            case .failure(let error):
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
}


struct RezkaAjaxResponse: nonisolated Decodable {
    let success: Bool
    let message: String?
    let url: String?       // the "streams" string
    let quality: String?
    let subtitle: Bool?

    enum CodingKeys: String, CodingKey {
        case success, message, url, quality, subtitle
    }
}
