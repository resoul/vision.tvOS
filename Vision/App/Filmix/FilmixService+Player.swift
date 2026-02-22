import Foundation
import Alamofire

extension FilmixService {
    private static let playerHeaders: HTTPHeaders = [
        "x-requested-with": "XMLHttpRequest",
        "Cookie": "x-a-key=sinatra; minotaurs=WAeThQWgnpYqm287TO84UQ%2BRHWGlEVrIuzxgE42xIDQ%3D; FILMIXNET=eriurkv36fs65t4ekqsc68rd55; _listView=line; ishimura=fef06ce407e0bc6fa90ba5196af2d24933239a90; alora=WAeThQWgnpYqm287TO84UQ%2BRHWGlEVrIuzxgE42xIDQ%3D",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36"
    ]

    func fetchPlayerData(postId: Int,
                         isSeries: Bool,
                         completion: @escaping (Result<[FilmixTranslation], Error>) -> Void) {
        let ts  = Int(Date().timeIntervalSince1970)
        let url = "\(baseURL)/api/movies/player-data?t=\(ts)"
        let params: Parameters = ["post_id": "\(postId)", "showfull": "true"]

        session.request(url, method: .post, parameters: params, headers: Self.playerHeaders)
            .responseDecodable(of: _FilmixPlayerResponse.self) { response in
                switch response.result {
                case .failure(let error):
                    completion(.failure(error))

                case .success(let data):
                    let entries = data.message.translations.video
                        .sorted { $0.key < $1.key }

                    if isSeries {
                        self.resolveSeriesTranslations(entries: entries, completion: completion)
                    } else {
                        let translations = entries.compactMap { studio, encoded -> FilmixTranslation? in
                            let raw     = FilmixHelper.decodeStringTokens(encoded)
                            let parts   = raw.split(separator: ",").map(String.init)
                            let streams = FilmixHelper.decodeString(list: parts)
                            guard !streams.isEmpty else { return nil }
                            return FilmixTranslation(studio: studio, streams: streams, seasons: [])
                        }
                        completion(.success(translations))
                    }
                }
            }
    }

    // MARK: - Series helper

    private func resolveSeriesTranslations(
        entries: [(key: String, value: String)],
        completion: @escaping (Result<[FilmixTranslation], Error>) -> Void
    ) {
        var results: [FilmixTranslation] = []
        let group = DispatchGroup()
        let lock  = NSLock()

        for (studio, encoded) in entries {
            let secondURL = FilmixHelper.decodeStringTokens(encoded)
            guard !secondURL.isEmpty else { continue }

            group.enter()
            session.request(secondURL, method: .get).responseString { response in
                defer { group.leave() }
                switch response.result {
                case .failure:
                    break

                case .success(let string):
                    let json = FilmixHelper.decodeStringTokens(string)
                    guard
                        let data    = json.data(using: .utf8),
                        let seasons = try? JSONDecoder().decode([_FilmixPlayerSerial].self, from: data)
                    else { return }

                    let translation = FilmixTranslation(studio: studio, streams: [:], seasons: seasons)
                    lock.lock()
                    results.append(translation)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            completion(.success(results.sorted { $0.studio < $1.studio }))
        }
    }
}
