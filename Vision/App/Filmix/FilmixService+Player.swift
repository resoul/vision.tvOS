import Foundation
import Alamofire

// MARK: - Player Data

extension FilmixService {

    private static let playerHeaders: HTTPHeaders = [
        "x-requested-with": "XMLHttpRequest",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36",
        // TODO: вынести куки в конфиг / Keychain
        "Cookie": "x-a-key=sinatra; minotaurs=WAeThQWgnpYqm287TO84UQ%2BRHWGlEVrIuzxgE42xIDQ%3D; FILMIXNET=eriurkv36fs65t4ekqsc68rd55; ishimura=fef06ce407e0bc6fa90ba5196af2d24933239a90; alora=WAeThQWgnpYqm287TO84UQ%2BRHWGlEVrIuzxgE42xIDQ%3D"
    ]

    func fetchPlayerData(postId: Int,
                         completion: @escaping (Result<[FilmixTranslation], Error>) -> Void) {
        let ts  = Int(Date().timeIntervalSince1970)
        let url = "\(baseURL)/api/movies/player-data?t=\(ts)"
        let params: Parameters = ["post_id": "\(postId)", "showfull": "true"]

        AF.request(url, method: .post,
                   parameters: params,
                   headers: Self.playerHeaders)
          .responseDecodable(of: _FilmixPlayerResponse.self) { response in
              switch response.result {
              case .success(let data):
                  let translations = data.message.translations.video
                      .compactMap { studio, encoded -> FilmixTranslation? in
                          let raw    = FilmixHelper.decodeStringTokens(encoded)
                          let parts  = raw.split(separator: ",").map(String.init)
                          let streams = FilmixHelper.decodeString(list: parts)
                          guard !streams.isEmpty else { return nil }
                          return FilmixTranslation(studio: studio, streams: streams)
                      }
                      .sorted { $0.studio < $1.studio }
                  completion(.success(translations))

              case .failure(let error):
                  completion(.failure(error))
              }
          }
    }
}
