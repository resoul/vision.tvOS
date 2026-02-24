import UIKit
import Alamofire
import SwiftSoup

final class FilmixService {

    static let shared = FilmixService()
    private init() {}

    let baseURL = "https://filmix.my"
    let session: Session = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        return Session(configuration: config)
    }()

    func fetchPage(url: URL? = nil,
                   completion: @escaping (Result<FilmixPage, Error>) -> Void) {
        let targetURL = url?.absoluteString ?? baseURL
        session.request(targetURL, method: .get).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let page = try Self.parseListing(html: Self.decode(data))
                    completion(.success(page))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchDetail(path: String,
                     completion: @escaping (Result<FilmixDetail, Error>) -> Void) {
        let fullURL = path.hasPrefix("http") ? path : "\(baseURL)\(path)"
        session.request(fullURL, method: .get).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let detail = try Self.parseDetail(html: Self.decode(data))
                    completion(.success(detail))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    static func parseListing(html: String) throws -> FilmixPage {
        let doc = try SwiftSoup.parse(html)
        var articles = try doc.select("#dle-content article.shortstory")
        if articles.isEmpty() {
            articles = try doc.select("article.shortstory")
        }

        var movies: [Movie] = []
        for (index, article) in articles.enumerated() {
            if let m = try? parseListingMovie(article: article, index: index) {
                movies.append(m)
            }
        }
        return FilmixPage(movies: movies, nextPageURL: try parseNextPageURL(doc: doc))
    }

    private static func parseListingMovie(article: Element, index: Int) throws -> Movie {
        let id  = Int(try article.attr("data-id")) ?? index
        let titleRaw  = try article.select("div.full div.title-one-line h2.name").attr("content")
        let title     = titleRaw.isEmpty
            ? (try? article.select("h2.name").text()) ?? "Unknown"
            : titleRaw

        let year      = (try? article.select(".item.year .item-content").text()).map { $0.isEmpty ? "—" : $0 } ?? "—"
        let isAdIn    = !(try article.select("span.video-in").isEmpty())
        let desc      = (try? article.select("p[itemprop=description]").text()) ?? ""
        let genreList = try article.select("div.full .item.category a").array().map { try $0.text() }
        let quality   = (try? article.select("div.full div.title-one-line div.top-date div.quality").text()) ?? ""
        let movieURL  = (try? article.select("div.short a.watch").attr("href")) ?? ""
        let isSeries  = movieURL.contains("/seria/")
        let translate = (try? article.select(".item.translate .item-content").text()) ?? ""

        let up    = Double((try? article.select("span.counter span.hand-up span").text()) ?? "") ?? 0
        let down  = Double((try? article.select("span.counter span.hand-down span").text()) ?? "") ?? 0
        let total = up + down
        let rating = total > 0 ? String(format: "%.1f", up / total * 10) : "—"

        let directors = personNames(in: article, selector: ".item:contains(Режиссер) .item-content span")
        let actors    = personNames(in: article, selector: ".item:contains(В ролях) .item-content span")

        let lastAdded: String? = {
            guard isSeries,
                  let span  = try? article.select(".added-info").first(),
                  let clone = span.copy() as? Element else { return nil }
            let _ = try? clone.select("i").remove()
            let t = (try? clone.text())?.trimmingCharacters(in: .whitespaces) ?? ""
            return t.isEmpty ? nil : t
        }()

        let posterURL: String = {
            if let href = (try? article.select("div.short a.fancybox").attr("href")), !href.isEmpty {
                return href.hasPrefix("http") ? href : "https://filmix.my\(href)"
            }
            if let src = (try? article.select("div.short img").attr("src")), !src.isEmpty {
                return src.hasPrefix("http") ? src : "https://filmix.my\(src)"
            }
            return ""
        }()

        let type     = isSeries ? Movie.ContentType.series(seasons: []) : .movie
        let duration = isSeries ? (quality.isEmpty ? "Series" : quality) : (quality.isEmpty ? "—" : quality)

        return Movie(
            id: id, title: title, year: year,
            description: desc, imageName: "",
            genre: genreList.first ?? "—",
            rating: rating, duration: duration,
            type: type, translate: translate,
            isAdIn: isAdIn,
            movieURL: movieURL, posterURL: posterURL,
            actors: actors, directors: directors,
            genreList: genreList, lastAdded: lastAdded
        )
    }

    static func parseDetail(html: String) throws -> FilmixDetail {
        let doc = try SwiftSoup.parse(html)
        guard let article = try? doc.select("#dle-content article.fullstory").first()
                         ?? doc.select("#dle-content article").first()
        else { throw FilmixError.articleNotFound }

        let id       = Int((try? article.attr("data-id")) ?? "") ?? 0
        let movieURL = (try? article.select(".short a.watch").attr("href")) ?? ""

        let posterThumb: String = {
            guard let src = try? article.select(".short img.poster").attr("src"), !src.isEmpty else { return "" }
            return src.hasPrefix("http") ? src : "https://filmix.my\(src)"
        }()
        let posterFull: String = {
            guard let href = try? article.select(".short a.fancybox").attr("href"), !href.isEmpty else { return posterThumb }
            return href.hasPrefix("http") ? href : "https://filmix.my\(href)"
        }()

        let title         = (try? article.select("h1.name").text()) ?? ""
        let originalTitle = labeledItemContent(in: article, label: "Название:")

        let quality = (try? article.select(".quality").first()?.text()) ?? ""
        let date    = (try? article.select("time.date").first()?.text()) ?? ""
        let dateISO = (try? article.select("meta[itemprop=dateCreated]").attr("content")) ?? ""

        var description = ""
        if let fullStory = try? article.select(".about .full-story").first() {
            description = (try? fullStory.text()) ?? ""
        }
        if description.isEmpty {
            description = (try? article.select("[itemprop=description]").first()?.text()) ?? ""
        }

        let isAdIn = !(try article.select("span.video-in").isEmpty())
        
        let isNotMovie = !(try article.select(".short .not-movie").isEmpty())

        let frames: [FilmixFrame] = {
            let base = "https://filmix.my"
            return (try? article.select(".frames ul.frames-list li a").array().compactMap { el -> FilmixFrame? in
                var full  = (try? el.attr("href")) ?? ""
                var thumb = (try? el.select("img").attr("src")) ?? ""
                guard !thumb.isEmpty else { return nil }
                if !full.isEmpty  && !full.hasPrefix("http")  { full  = "\(base)\(full)" }
                if !thumb.hasPrefix("http") { thumb = "\(base)\(thumb)" }
                return FilmixFrame(thumbURL: thumb, fullURL: full)
            }) ?? []
        }()

        let directors = personNames(in: article, selector: ".item.directors .item-content span")
        let actors    = actorNames(in: article)
        let writers   = personNames(in: article, labelText: "Сценарист:")
        let producers = personNames(in: article, labelText: "Продюсер:")

        let genres    = (try? article.select("a[itemprop=genre]").array().map { try $0.text() }) ?? []
        let countries = (try? article.select(".item.contry .item-content a").array().map { try $0.text() }) ?? []
        let year      = (try? article.select(".item.year .item-content").text()) ?? "—"

        let durationMinutes: Int? = {
            if let v = Int((try? article.select(".item.durarion").attr("content")) ?? "") { return v }
            let text   = (try? article.select(".item.durarion .item-content").text()) ?? ""
            let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(digits)
        }()

        let translate = labeledItemContent(in: article, label: "Перевод:")
        let mpaa      = labeledItemContent(in: article, label: "MPAA:")
        let slogan    = labeledItemContent(in: article, label: "Слоган:")

        let statusOnAir: String? = {
            guard let el = try? article.select(".top-date .status").first() else { return nil }
            let text = (try? el.select(".ico").text()) ?? ""
            return text.isEmpty ? nil : text
        }()
        let statusHint: String? = {
            guard let el = try? article.select(".top-date .status").first() else { return nil }
            let hint = (try? el.attr("title")) ?? ""
            return hint.isEmpty ? nil : hint
        }()

        let lastAdded: String? = {
            guard let span  = try? article.select(".item.xfgiven_added .added-info").first(),
                  let clone = span.copy() as? Element else { return nil }
            let _ = try? clone.select("i").remove()
            let t = (try? clone.text())?.trimmingCharacters(in: .whitespaces) ?? ""
            return t.isEmpty ? nil : t
        }()

        let kpPs      = (try? article.select("span.kinopoisk p").array()) ?? []
        let kpRating  = (try? kpPs[safe: 0]?.text()) ?? "—"
        let kpVotes   = (try? kpPs[safe: 1]?.text()) ?? "—"

        let imdbPs    = (try? article.select("span.imdb p").array()) ?? []
        let imdbRating = (try? imdbPs[safe: 0]?.text()) ?? "—"
        let imdbVotes  = (try? imdbPs[safe: 1]?.text()) ?? "—"

        let userPositive = Int((try? article.select(".percent-p").attr("data-percent-p")) ?? "") ?? 0
        let userLikes    = Int((try? article.select(".rateinf.ratePos").text()) ?? "") ?? 0
        let userDislikes = Int((try? article.select(".rateinf.rateNeg").text()) ?? "") ?? 0

        return FilmixDetail(
            id: id, movieURL: movieURL,
            posterThumb: posterThumb, posterFull: posterFull,
            title: title, originalTitle: originalTitle,
            quality: quality, date: date, dateISO: dateISO,
            year: year, durationMinutes: durationMinutes,
            mpaa: mpaa, slogan: slogan,
            statusOnAir: statusOnAir, statusHint: statusHint, lastAdded: lastAdded,
            directors: directors, actors: actors,
            writers: writers, producers: producers,
            genres: genres, countries: countries,
            translate: translate,
            description: description, isAdIn: isAdIn,
            isNotMovie: isNotMovie,
            frames: frames,
            kinopoiskRating: kpRating, kinopoiskVotes: kpVotes,
            imdbRating: imdbRating, imdbVotes: imdbVotes,
            userPositivePercent: userPositive,
            userLikes: userLikes, userDislikes: userDislikes
        )
    }

    private static func parseNextPageURL(doc: Document) throws -> URL? {
        if let href = try? doc.select("div.navigation a.next").first()?.attr("href"),
           !href.isEmpty { return URL(string: href) }
        for link in try doc.select("div.navigation a[data-number]").array() {
            let n    = (try? link.attr("data-number")).flatMap(Int.init) ?? 0
            let href = (try? link.attr("href")) ?? ""
            if n > 1, !href.isEmpty { return URL(string: href) }
        }
        return nil
    }

    static func decode(_ data: Data) -> String {
        String(data: data, encoding: .windowsCP1251)
            ?? String(data: data, encoding: .utf8)
            ?? ""
    }

    private static func labeledItemContent(in el: Element, label: String) -> String {
        guard let items = try? el.select(".item").array() else { return "" }
        for item in items {
            let lbl = (try? item.select(".label").first()?.text()) ?? ""
            if lbl == label {
                return ((try? item.select(".item-content").text()) ?? "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }
        return ""
    }

    private static func personNames(in el: Element, selector: String) -> [String] {
        (try? el.select(selector).array()
            .compactMap { try? $0.text() }
            .map { $0.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        ) ?? []
    }

    private static func personNames(in el: Element, labelText: String) -> [String] {
        guard let items = try? el.select(".item").array() else { return [] }
        for item in items {
            let lbl = (try? item.select(".label").first()?.text()) ?? ""
            if lbl == labelText {
                return personNames(in: item, selector: ".item-content span")
            }
        }
        return []
    }

    private static func actorNames(in el: Element) -> [String] {
        guard let actorItem = try? el.select(".item.actors").first() else { return [] }

        var names = (try? actorItem.select("span[itemprop=name]").array()
            .compactMap { try? $0.text() }
            .filter { !$0.isEmpty }
        ) ?? []

        let plain = (try? actorItem.select(".item-content > span:not([itemprop])").array()
            .compactMap { try? $0.text() }
            .map { $0.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        ) ?? []
        names.append(contentsOf: plain)
        return names
    }
}
