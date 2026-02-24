import Foundation
import SwiftSoup

// MARK: - Models

struct RezkaTranslator {
    let movieId: Int
    let translatorId: Int
    let title: String
    let isCamrip: Bool
    let hasAds: Bool
    let isDirector: Bool
    let isActive: Bool
}

struct RezkaStream {
    let quality: String
    let hlsURL: URL?
    let directURL: URL?
}

struct RezkaSearchResult {
    let id: Int
    let title: String
    let url: URL
    let posterURL: URL?
    let info: String
    let category: String
    let status: String?
}

struct RezkaPlayerData {
    let movieId: Int
    let activeTranslatorId: Int
    let defaultQuality: String
    let streams: [RezkaStream]
    let translators: [RezkaTranslator]
    let favs: String
}

// MARK: - Parser

final class RezkaParser {

    // MARK: - Search results

    /// Parse search results HTML (the `div.b-content__inline_items` block).
    /// Works both for full page HTML and for partial HTML returned by AJAX.
    func parseSearch(html: String) throws -> [RezkaSearchResult] {
        let doc = try SwiftSoup.parse(html)
        let items = try doc.select("div.b-content__inline_item")

        return items.compactMap { el in
            guard
                let idStr = try? el.attr("data-id"), let id = Int(idStr),
                let urlStr = try? el.attr("data-url"), let url = URL(string: urlStr)
            else { return nil }

            let imgSrc = try? el.select("div.b-content__inline_item-cover img").first()?.attr("src")
            let posterURL = imgSrc.flatMap { URL(string: $0) }
            let title = (try? el.select("div.b-content__inline_item-link a").first()?.text()) ?? ""
            let info = (try? el.select("div.b-content__inline_item-link div").first()?.text()) ?? ""
            let category = (try? el.select("span.cat i.entity").first()?.text()) ?? ""
            let statusText = try? el.select("span.info").first()?.text()
            let status = statusText.flatMap { $0.isEmpty ? nil : $0 }

            return RezkaSearchResult(
                id: id,
                title: title,
                url: url,
                posterURL: posterURL,
                info: info,
                category: category,
                status: status
            )
        }
    }

    // MARK: Public

    /// Parse full page HTML into RezkaPlayerData
    func parse(html: String) throws -> RezkaPlayerData {
        let doc = try SwiftSoup.parse(html)

        let translators = try parseTranslators(doc: doc)
        let (movieId, translatorId, streamsString, defaultQuality) = try parseInitCall(html: html)
        let favs = try parseFavs(doc: doc)
        let streams = parseStreams(from: streamsString)

        return RezkaPlayerData(
            movieId: movieId,
            activeTranslatorId: translatorId,
            defaultQuality: defaultQuality,
            streams: streams,
            translators: translators,
            favs: favs
        )
    }

    // MARK: - Favs

    /// Extracts the value of <input type="hidden" id="ctrl_favs">
    /// Required as the `favs` parameter in AJAX translator requests.
    private func parseFavs(doc: Document) throws -> String {
        let el = try doc.select("input#ctrl_favs").first()
        return try el?.val() ?? ""
    }

    // MARK: - Translators

    private func parseTranslators(doc: Document) throws -> [RezkaTranslator] {
        let items = try doc.select("li.b-translator__item")
        return try items.map { el in
            RezkaTranslator(
                movieId:      Int(try el.attr("data-id")) ?? 0,
                translatorId: Int(try el.attr("data-translator_id")) ?? 0,
                title:        try el.text(),
                isCamrip:     (try el.attr("data-camrip")) == "1",
                hasAds:       (try el.attr("data-ads")) == "1",
                isDirector:   (try el.attr("data-director")) == "1",
                isActive:     el.hasClass("active")
            )
        }
    }

    // MARK: - initCDNMoviesEvents

    /// Extract args from:
    /// sof.tv.initCDNMoviesEvents(13885, 56, 0, 0, 0, 'rezka.ag', false, false, { ... "streams": "...", "default_quality": "480p" ... });
    private func parseInitCall(html: String) throws -> (movieId: Int, translatorId: Int, streams: String, defaultQuality: String) {

        // 1. Extract the JS call arguments line
        guard let callRange = html.range(of: "sof.tv.initCDNMoviesEvents(") else {
            throw RezkaParserError.initCallNotFound
        }
        let afterCall = String(html[callRange.upperBound...])

        // 2. movieId and translatorId from positional args
        let argsLine = afterCall.prefix(200)
        let positionalPattern = #"^(\d+),\s*(\d+)"#
        var movieId = 0
        var translatorId = 0
        if let regex = try? NSRegularExpression(pattern: positionalPattern),
           let match = regex.firstMatch(in: String(argsLine), range: NSRange(argsLine.startIndex..., in: argsLine)) {
            movieId      = Int(argsLine[Range(match.range(at: 1), in: argsLine)!]) ?? 0
            translatorId = Int(argsLine[Range(match.range(at: 2), in: argsLine)!]) ?? 0
        }

        // 3. Find JSON object boundary { ... }
        guard let braceStart = afterCall.firstIndex(of: "{") else {
            throw RezkaParserError.jsonNotFound
        }
        var depth = 0
        var braceEnd = braceStart
        for idx in afterCall[braceStart...].indices {
            let ch = afterCall[idx]
            if ch == "{" { depth += 1 }
            else if ch == "}" {
                depth -= 1
                if depth == 0 { braceEnd = idx; break }
            }
        }
        let jsonString = String(afterCall[braceStart...braceEnd])

        // 4. Decode JSON
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw RezkaParserError.jsonDecodeFailed
        }

        let streamsRaw    = json["streams"] as? String ?? ""
        let defaultQuality = json["default_quality"] as? String ?? "480p"

        return (movieId, translatorId, streamsRaw, defaultQuality)
    }

    // MARK: - Streams string parser

    /// Format: "[360p]hlsUrl:hls:manifest.m3u8 or directUrl,[480p]..."
    func parseStreams(from raw: String) -> [RezkaStream] {
        // Split by ",[quality]" keeping the quality tag with each segment
        // Strategy: split on comma that is immediately followed by '['
        var segments: [String] = []
        var current = ""
        var i = raw.startIndex
        while i < raw.endIndex {
            let ch = raw[i]
            if ch == "," {
                let next = raw.index(after: i)
                if next < raw.endIndex && raw[next] == "[" {
                    segments.append(current)
                    current = ""
                    i = next
                    continue
                }
            }
            current.append(ch)
            i = raw.index(after: i)
        }
        if !current.isEmpty { segments.append(current) }

        return segments.compactMap { parseSegment($0) }
    }

    /// Parse a single segment like "[720p]hlsUrl:hls:manifest.m3u8 or directUrl"
    private func parseSegment(_ segment: String) -> RezkaStream? {
        // Extract quality label [...]
        guard segment.hasPrefix("["),
              let closeBracket = segment.firstIndex(of: "]") else { return nil }

        let quality = String(segment[segment.index(after: segment.startIndex)..<closeBracket])
        let rest = String(segment[segment.index(after: closeBracket)...])

        // Split on " or "
        let parts = rest.components(separatedBy: " or ")

        var hlsURL: URL? = nil
        var directURL: URL? = nil

        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.contains(":hls:") {
                // Remove the ":hls:manifest.m3u8" suffix and reconstruct as proper HLS URL
                // e.g. "https://stream.voidboost.cc/.../file.mp4:hls:manifest.m3u8"
                // The actual HLS playlist is: base + "/manifest.m3u8" after stripping :hls:manifest.m3u8
                if let hlsRange = trimmed.range(of: ":hls:manifest.m3u8") {
                    let baseURL = String(trimmed[..<hlsRange.lowerBound])
                    // HLS URL = base/:hls:manifest.m3u8 → typically baseURL + "/manifest.m3u8"
                    hlsURL = URL(string: baseURL + "/manifest.m3u8")
                }
            } else if trimmed.hasSuffix(".mp4") {
                directURL = URL(string: trimmed)
            }
        }

        return RezkaStream(quality: quality, hlsURL: hlsURL, directURL: directURL)
    }
}

// MARK: - Errors

enum RezkaParserError: Error, LocalizedError {
    case initCallNotFound
    case jsonNotFound
    case jsonDecodeFailed

    var errorDescription: String? {
        switch self {
        case .initCallNotFound: return "sof.tv.initCDNMoviesEvents not found in HTML"
        case .jsonNotFound:     return "JSON object not found in initCDNMoviesEvents call"
        case .jsonDecodeFailed: return "Failed to decode JSON from initCDNMoviesEvents"
        }
    }
}
