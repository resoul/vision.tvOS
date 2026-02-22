import UIKit
import Alamofire
import SwiftSoup

// MARK: - FilmixPage

struct FilmixPage {
    let movies: [Movie]
    let nextPageURL: URL?
}

// MARK: - FilmixService

final class FilmixService {

    static let shared = FilmixService()
    private init() {}

    private let baseURL = "https://filmix.my"

    // MARK: - Fetch page
    func fetchPage(url: URL? = nil, completion: @escaping (Result<FilmixPage, Error>) -> Void) {
        let targetURL = url?.absoluteString ?? baseURL

        AF.request(targetURL, method: .get).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let html = String(data: data, encoding: .windowsCP1251)
                        ?? String(data: data, encoding: .utf8)
                        ?? ""
                    let page = try Self.parse(html: html)
                    completion(.success(page))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Parser

    private static func parse(html: String) throws -> FilmixPage {
        let doc = try SwiftSoup.parse(html)
        let articles = try doc.select("#dle-content article.shortstory")

        var movies: [Movie] = []
        for (index, article) in articles.enumerated() {
            if let movie = try? parseMovie(article: article, index: index) {
                movies.append(movie)
            }
        }

        let nextPageURL = try parseNextPageURL(doc: doc)
        return FilmixPage(movies: movies, nextPageURL: nextPageURL)
    }

    private static func parseMovie(article: Element, index: Int) throws -> Movie {
        let movieIdStr = try article.attr("data-id")
        let movieId = Int(movieIdStr) ?? index

        let movieTitle = try article.select("div.full div.title-one-line h2.name").attr("content")
        let finalTitle = movieTitle.isEmpty
            ? (try? article.select("h2.name").text()) ?? "Unknown"
            : movieTitle

        let year = try article.select(".item.year .item-content").text()
        let finalYear = year.isEmpty ? "—" : year

        let isAdIn = (try? article.select("div.short span.like-count-wrap span.video-in").text() == "") ?? true
        let description = (try? article.select("p[itemprop=description]").text()) ?? ""

        let genreList = try article.select("div.full .item.category a").array().map { try $0.text() }
        let genre = genreList.first ?? "—"

        let quality = (try? article.select("div.full div.title-one-line div.top-date div.quality").text()) ?? ""

        let ratingUpStr   = (try? article.select("div.short span.counter span.hand-up span").text()) ?? "0"
        let ratingDownStr = (try? article.select("div.short span.counter span.hand-down span").text()) ?? "0"
        let ratingUp   = Double(ratingUpStr)   ?? 0
        let ratingDown = Double(ratingDownStr) ?? 0
        let totalVotes = ratingUp + ratingDown
        let ratingValue: Double
        if totalVotes > 0 {
            ratingValue = (ratingUp / totalVotes) * 10
        } else {
            ratingValue = 0
        }
        let rating = totalVotes > 0 ? String(format: "%.1f", ratingValue) : "—"

        let movieURL = (try? article.select("div.short a.watch").attr("href")) ?? ""

        let translate = (try? article.select(".item.translate .item-content").text()) ?? ""
        
        let actors = (try? article
            .select(".item:contains(В ролях) .item-content span")
            .array()
            .map { try $0.text().replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces) }
        ) ?? []
        let directors = (try? article
            .select(".item:contains(Режиссер) .item-content span")
            .array()
            .map { try $0.text().replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces) }
        ) ?? []

        let isSeries = quality.lowercased().contains("сезон")
            || quality.lowercased().contains("serial")
            || finalTitle.lowercased().contains("сезон")

        let contentType: Movie.ContentType = isSeries
            ? .series(seasons: [])
            : .movie

        let duration: String
        if isSeries {
            duration = quality.isEmpty ? "Series" : quality
        } else {
            duration = quality.isEmpty ? "—" : quality
        }
        
        let posterURL: String = {
            if let a    = try? article.select("div.short span.like-count-wrap a.fancybox").first(),
               let href = try? a.attr("href"), !href.isEmpty {
                if href.hasPrefix("http") { return href }
                return "https://filmix.my\(href)"
            }

            if let img = try? article.select("div.short img").first(),
               let src = try? img.attr("src"), !src.isEmpty {
                if src.hasPrefix("http") { return src }
                return "https://filmix.my\(src)"
            }
            return ""
        }()

        return Movie(
            id: movieId,
            title: finalTitle,
            year: finalYear,
            description: description,
            imageName: "",
            genre: genre,
            rating: rating,
            duration: duration,
            type: contentType,
            translate: translate,
            isAdIn: isAdIn,
            audioTracks: AudioTrack.movieTracks,
            movieURL: movieURL,
            posterURL: posterURL,
            actors: actors,
            directors: directors,
            genreList: genreList
        )
    }

    private static func parseNextPageURL(doc: Document) throws -> URL? {
        if let nextA = try? doc.select("div.navigation a.next").first(),
           let href = try? nextA.attr("href"),
           !href.isEmpty {
            return URL(string: href)
        }

        let navLinks = try doc.select("div.navigation a[data-number]").array()
        for link in navLinks {
            let pageNum = (try? link.attr("data-number")).flatMap(Int.init) ?? 0
            let href    = (try? link.attr("href")) ?? ""
            if pageNum > 1, !href.isEmpty {
                return URL(string: href)
            }
        }
        return nil
    }
}
