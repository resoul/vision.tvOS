import UIKit

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

extension UIColor {
    func lighter(by f: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r + (1-r)*f, 1), green: min(g + (1-g)*f, 1), blue: min(b + (1-b)*f, 1), alpha: a)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
