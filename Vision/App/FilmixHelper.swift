import Foundation
import UIKit
import Alamofire
import SwiftSoup

func fetch() {
    AF.request("https://filmix.my", method: .get).responseData { response in
        switch response.result {
            case .success(let value):
            
            do {
                let doc = try SwiftSoup.parse(String(data: value, encoding: .windowsCP1251)!)
                let articles = try doc.select("#dle-content article.shortstory")
                let pagination = try doc.select("#dle-content div.navigation a")
                for nav in pagination {
                    let page = try nav.attr("data-number")
                    let pageUri = try nav.attr("href")
                }
                
                for article in articles {
                    let movieId = try article.attr("data-id")
                    
                    let rating = try article.select("div.short span.like-count-wrap span.like span.count").text()
                    let ratingUp = try article.select("div.short span.counter span.hand-up span").text()
                    let ratingDown = try article.select("div.short span.counter span.hand-down span").text()
                    let imgSrc = try article.select("div.short span.like-count-wrap a.fancybox").text()
                    let movieUri = try article.select("div.short a.watch").attr("href")
                    
                    let movieTitle = try article.select("div.full div.title-one-line h2.name").attr("content")
                    let movieQuality = try article.select("div.full div.title-one-line div.top-date div.quality").text()
                    let genres = try article.select("div.full .item.category a").array().map { try $0.text() }
                    let year = try article.select(".item.year .item-content").text()
                    let translate = try article.select(".item.translate .item-content").text()
                    let actors = try article
                        .select(".item:contains(В ролях) .item-content span")
                        .array()
                        .map {
                            try $0.text()
                                .replacingOccurrences(of: ",", with: "")
                                .trimmingCharacters(in: .whitespaces)
                        }
                    let directors = try article
                        .select(".item:contains(Режиссер) .item-content span")
                        .array()
                        .map {
                            try $0.text()
                                .replacingOccurrences(of: ",", with: "")
                                .trimmingCharacters(in: .whitespaces)
                        }
                    let description = try article
                        .select("p[itemprop=description]")
                        .text()
                }
            } catch {
                print(error.localizedDescription)
            }
        case .failure(let error):
            print(error)
        }
    }
}
func parseMovie(_ article: Element) throws -> Title {
   let title = try article.select("h2.name a").text()
   let poster = try article.select("img.poster").attr("src")
   let link = try article.select("a.watch").attr("href")
   let quality = try article.select(".quality").text()
   let date = try article.select("time.date").text()

   // GENRES
   let genres = try article
       .select(".item.category a")
       .array()
       .map { try $0.text() }

   // YEAR
   let year = try article
       .select(".item.year .item-content")
       .text()

   // TRANSLATE
   let translate = try article
       .select(".item.translate .item-content")
       .text()

   // DIRECTOR
   let director = try article
       .select(".item:contains(Режиссер) .item-content")
       .text()

   // ACTORS
   let actors = try article
       .select(".item:contains(В ролях) .item-content span")
       .array()
       .map {
           try $0.text()
               .replacingOccurrences(of: ",", with: "")
               .trimmingCharacters(in: .whitespaces)
       }

   // DESCRIPTION
   let description = try article
       .select("p[itemprop=description]")
       .text()

   return Title(
       title: title,
       poster: poster,
       link: link,
       quality: quality,
       date: date,
       genres: genres,
       year: year,
       translate: translate,
       director: director,
       actors: actors,
       description: description
   )
}

struct Title {
   let title: String
   let poster: String
   let link: String
   let quality: String
   let date: String

   let genres: [String]
   let year: String
   let translate: String
   let director: String
   let actors: [String]
   let description: String
}


class FilmixHelper {
    static func decodeString(list: [String]) -> [String: String] {
        var qualityList: [String: String] = [:]
            let regex = try! NSRegularExpression(pattern: "\\[(.*?)\\]", options: [])
            for item in list {
                if let match = regex.firstMatch(in: item, options: [], range: NSRange(location: 0, length: item.utf16.count)) {
                    if let range = Range(match.range(at: 1), in: item) {
                        let key = String(item[range])
                        let value = item.replacingOccurrences(of: "[\(key)]", with: "").trimmingCharacters(in: .whitespaces)
                        qualityList[key] = value
                    }
                }
            }
            return qualityList
    }
    
    static func decodeStringTokens(_ s: String) -> String {
        let tokens = [
                ":<:bzl3UHQwaWk0MkdXZVM3TDdB",
                ":<:SURhQnQwOEM5V2Y3bFlyMGVI",
                ":<:bE5qSTlWNVUxZ01uc3h0NFFy",
                ":<:Mm93S0RVb0d6c3VMTkV5aE54",
                ":<:MTluMWlLQnI4OXVic2tTNXpU"
            ]

            var clean = String(s.dropFirst(2))
            clean = clean.replacingOccurrences(of: "\\/", with: "/")

            while true {
                var modified = false
                for token in tokens {
                    if clean.contains(token) {
                        clean = clean.replacingOccurrences(of: token, with: "")
                        modified = true
                    }
                }
                if !modified { break }
            }

            if let data = Data(base64Encoded: clean) {
                return String(data: data, encoding: .utf8) ?? ""
            }
            return ""
    }
}
