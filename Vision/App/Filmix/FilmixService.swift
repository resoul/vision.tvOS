import UIKit
import Alamofire
import SwiftSoup

final class FilmixService {

    static let shared = FilmixService()
    private init() {}

    let baseURL = "https://filmix.my"

    // MARK: - Fetch listing

    func fetchPage(url: URL? = nil,
                   completion: @escaping (Result<FilmixPage, Error>) -> Void) {
        let targetURL = url?.absoluteString ?? baseURL
        AF.request(targetURL, method: .get).responseData { response in
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

    // MARK: - Fetch detail

    /// Pass either a relative path (/film/…/xxx.html) or a full URL.
    func fetchDetail(path: String,
                     completion: @escaping (Result<FilmixDetail, Error>) -> Void) {
        let fullURL = path.hasPrefix("http") ? path : "\(baseURL)\(path)"
        AF.request(fullURL, method: .get).responseData { response in
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

    // MARK: - Listing parser

    private static func parseListing(html: String) throws -> FilmixPage {
        let doc      = try SwiftSoup.parse(html)
        let articles = try doc.select("#dle-content article.shortstory")

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

        // Title: prefer itemprop content on h2, fall back to visible text
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

        // Rating from user thumbs
        let up    = Double((try? article.select("span.counter span.hand-up span").text()) ?? "") ?? 0
        let down  = Double((try? article.select("span.counter span.hand-down span").text()) ?? "") ?? 0
        let total = up + down
        let rating = total > 0 ? String(format: "%.1f", up / total * 10) : "—"

        let directors = personNames(in: article, selector: ".item:contains(Режиссер) .item-content span")
        let actors    = personNames(in: article, selector: ".item:contains(В ролях) .item-content span")

        // "Добавлена" for series
        let lastAdded: String? = {
            guard isSeries,
                  let span  = try? article.select(".added-info").first(),
                  let clone = span.copy() as? Element else { return nil }
            try? clone.select("i").remove()
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
            isAdIn: isAdIn, audioTracks: AudioTrack.movieTracks,
            movieURL: movieURL, posterURL: posterURL,
            actors: actors, directors: directors,
            genreList: genreList, lastAdded: lastAdded
        )
    }

    // MARK: - Detail page parser

    static func parseDetail(html: String) throws -> FilmixDetail {
        let doc = try SwiftSoup.parse(html)

        // Detail page uses article.fullstory (not .shortstory)
        guard let article = try? doc.select("#dle-content article.fullstory").first()
                         ?? doc.select("#dle-content article").first()
        else { throw FilmixError.articleNotFound }

        let id       = Int((try? article.attr("data-id")) ?? "") ?? 0
        let movieURL = (try? article.select(".short a.watch").attr("href")) ?? ""

        // ── Poster ─────────────────────────────────────────────────────────
        let posterThumb: String = {
            guard let src = try? article.select(".short img.poster").attr("src"), !src.isEmpty else { return "" }
            return src.hasPrefix("http") ? src : "https://filmix.my\(src)"
        }()
        let posterFull: String = {
            guard let href = try? article.select(".short a.fancybox").attr("href"), !href.isEmpty else { return posterThumb }
            return href.hasPrefix("http") ? href : "https://filmix.my\(href)"
        }()

        // ── Titles ──────────────────────────────────────────────────────────
        let title         = (try? article.select("h1.name").text()) ?? ""
        let originalTitle = labeledItemContent(in: article, label: "Название:")

        // ── Date / Quality ──────────────────────────────────────────────────
        let quality = (try? article.select(".quality").first()?.text()) ?? ""
        let date    = (try? article.select("time.date").first()?.text()) ?? ""
        let dateISO = (try? article.select("meta[itemprop=dateCreated]").attr("content")) ?? ""

        // ── Description ─────────────────────────────────────────────────────
        // .about .full-story has the clean full text; strip the "Больше" button
        var description = ""
        if let fullStory = try? article.select(".about .full-story").first() {
            description = (try? fullStory.text()) ?? ""
        }
        if description.isEmpty {
            description = (try? article.select("[itemprop=description]").first()?.text()) ?? ""
        }

        // ── isAdIn ──────────────────────────────────────────────────────────
        let isAdIn = !(try article.select("span.video-in").isEmpty())

        // ── People ──────────────────────────────────────────────────────────
        let directors = personNames(in: article, selector: ".item.directors .item-content span")
        let actors    = actorNames(in: article)
        let writers   = personNames(in: article, labelText: "Сценарист:")
        let producers = personNames(in: article, labelText: "Продюсер:")

        // ── Taxonomy ────────────────────────────────────────────────────────
        let genres    = (try? article.select("a[itemprop=genre]").array().map { try $0.text() }) ?? []
        let countries = (try? article.select(".item.contry .item-content a").array().map { try $0.text() }) ?? []
        let year      = (try? article.select(".item.year .item-content").text()) ?? "—"

        // Duration: prefer itemprop attr "content"="110", fallback parse text
        let durationMinutes: Int? = {
            if let v = Int((try? article.select(".item.durarion").attr("content")) ?? "") { return v }
            let text   = (try? article.select(".item.durarion .item-content").text()) ?? ""
            let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(digits)
        }()

        let translate = labeledItemContent(in: article, label: "Перевод:")
        let mpaa      = labeledItemContent(in: article, label: "MPAA:")
        let slogan    = labeledItemContent(in: article, label: "Слоган:")

        // ── Series-specific ─────────────────────────────────────────────────
        // "В эфире" badge from .status span; its title attr = hint text
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

        // "Добавлена" on detail page lives in .item.xfgiven_added .added-info
        let lastAdded: String? = {
            guard let span  = try? article.select(".item.xfgiven_added .added-info").first(),
                  let clone = span.copy() as? Element else { return nil }
            try? clone.select("i").remove()
            let t = (try? clone.text())?.trimmingCharacters(in: .whitespaces) ?? ""
            return t.isEmpty ? nil : t
        }()

        // ── Ratings ─────────────────────────────────────────────────────────
        // Kinopoisk — span.kinopoisk contains two <p>: rating, votes
        let kpPs      = (try? article.select("span.kinopoisk p").array()) ?? []
        let kpRating  = (try? kpPs[safe: 0]?.text()) ?? "—"
        let kpVotes   = (try? kpPs[safe: 1]?.text()) ?? "—"

        // IMDB — span.imdb contains two <p>: rating, votes
        let imdbPs    = (try? article.select("span.imdb p").array()) ?? []
        let imdbRating = (try? imdbPs[safe: 0]?.text()) ?? "—"
        let imdbVotes  = (try? imdbPs[safe: 1]?.text()) ?? "—"

        // User percent slider
        let userPositive = Int((try? article.select(".percent-p").attr("data-percent-p")) ?? "") ?? 0

        // Thumb up / down counts
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
            kinopoiskRating: kpRating, kinopoiskVotes: kpVotes,
            imdbRating: imdbRating, imdbVotes: imdbVotes,
            userPositivePercent: userPositive,
            userLikes: userLikes, userDislikes: userDislikes
        )
    }

    // MARK: - Next page URL

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

    // MARK: - Encoding

    static func decode(_ data: Data) -> String {
        String(data: data, encoding: .windowsCP1251)
            ?? String(data: data, encoding: .utf8)
            ?? ""
    }

    // MARK: - DOM helpers

    /// Finds the .item whose .label text equals `label:` and returns trimmed .item-content text.
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

    /// Person names from a CSS selector, stripping commas and whitespace.
    private static func personNames(in el: Element, selector: String) -> [String] {
        (try? el.select(selector).array()
            .compactMap { try? $0.text() }
            .map { $0.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        ) ?? []
    }

    /// Person names by label — finds .item by .label text, then reads spans.
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

    /// Actors: collects itemprop=name actors first, then plain inline spans.
    private static func actorNames(in el: Element) -> [String] {
        guard let actorItem = try? el.select(".item.actors").first() else { return [] }

        // itemprop actors (linked)
        var names = (try? actorItem.select("span[itemprop=name]").array()
            .compactMap { try? $0.text() }
            .filter { !$0.isEmpty }
        ) ?? []

        // Plain non-itemprop spans (unlisted actors)
        let plain = (try? actorItem.select(".item-content > span:not([itemprop])").array()
            .compactMap { try? $0.text() }
            .map { $0.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        ) ?? []
        names.append(contentsOf: plain)
        return names
    }
}
