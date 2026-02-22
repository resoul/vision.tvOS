import UIKit

// MARK: - Models

struct Movie {
    let id: Int
    let title: String
    let year: String
    let description: String
    let imageName: String
    let genre: String
    let rating: String
    let duration: String
    let type: ContentType
    let audioTracks: [AudioTrack]

    enum ContentType {
        case movie
        case series(seasons: [Season])
    }

    var accentColor: UIColor {
        let palette: [UIColor] = [
            UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1),
            UIColor(red: 0.10, green: 0.28, blue: 0.55, alpha: 1),
            UIColor(red: 0.35, green: 0.12, blue: 0.45, alpha: 1),
            UIColor(red: 0.08, green: 0.35, blue: 0.28, alpha: 1),
            UIColor(red: 0.50, green: 0.10, blue: 0.10, alpha: 1),
        ]
        return palette[id % palette.count]
    }
}

struct Season {
    let number: Int
    let year: String
    let episodes: [Episode]
}

struct Episode {
    let number: Int
    let title: String
    let duration: String
    let description: String
}

struct AudioTrack: Equatable {
    let id: String
    let language: String   // "Русский", "English", etc.
    let kind: Kind
    let flag: String       // emoji flag

    enum Kind {
        case original
        case dubbing(studio: String)
        case voiceover(studio: String)
    }

    var displayTitle: String {
        switch kind {
        case .original:             return "\(flag)  \(language)  · Оригинал"
        case .dubbing(let s):       return "\(flag)  \(language)  · \(s)"
        case .voiceover(let s):     return "\(flag)  \(language)  · \(s) (Закадр)"
        }
    }

    static func == (lhs: AudioTrack, rhs: AudioTrack) -> Bool { lhs.id == rhs.id }
}

// MARK: - Watch State

final class WatchStore {
    static let shared = WatchStore()
    private let defaults = UserDefaults.standard

    // MARK: Watched episodes
    private func watchedKey(movieId: Int, season: Int, episode: Int) -> String {
        "watched_\(movieId)_s\(season)_e\(episode)"
    }

    func isWatched(movieId: Int, season: Int, episode: Int) -> Bool {
        defaults.bool(forKey: watchedKey(movieId: movieId, season: season, episode: episode))
    }

    func setWatched(_ watched: Bool, movieId: Int, season: Int, episode: Int) {
        defaults.set(watched, forKey: watchedKey(movieId: movieId, season: season, episode: episode))
    }

    func firstUnwatchedIndex(movieId: Int, season: Season) -> Int? {
        for (i, ep) in season.episodes.enumerated() {
            if !isWatched(movieId: movieId, season: season.number, episode: ep.number) { return i }
        }
        return nil
    }

    // MARK: Selected audio track
    private func audioKey(movieId: Int) -> String { "audio_\(movieId)" }

    func selectedAudioId(movieId: Int) -> String? {
        defaults.string(forKey: audioKey(movieId: movieId))
    }

    func setSelectedAudioId(_ id: String, movieId: Int) {
        defaults.set(id, forKey: audioKey(movieId: movieId))
    }
}

// MARK: - Sample Audio Tracks

extension AudioTrack {
    static let originalEn  = AudioTrack(id: "en_orig",  language: "English",  kind: .original,              flag: "🇺🇸")
    static let originalFr  = AudioTrack(id: "fr_orig",  language: "Français", kind: .original,              flag: "🇫🇷")
    static let rubDubbing  = AudioTrack(id: "ru_dub",   language: "Русский",  kind: .dubbing(studio: "Дублированный"),  flag: "🇷🇺")
    static let ruVoiceover = AudioTrack(id: "ru_vo",    language: "Русский",  kind: .voiceover(studio: "LostFilm"),     flag: "🇷🇺")
    static let ruAmedia    = AudioTrack(id: "ru_amedia",language: "Русский",  kind: .dubbing(studio: "Amedia"),         flag: "🇷🇺")
    static let ruCub       = AudioTrack(id: "ru_cub",   language: "Русский",  kind: .voiceover(studio: "Кубик в Кубе"), flag: "🇷🇺")
    static let deDub       = AudioTrack(id: "de_dub",   language: "Deutsch",  kind: .dubbing(studio: "Dублированный"),  flag: "🇩🇪")

    static let movieTracks: [AudioTrack] = [originalEn, rubDubbing, ruVoiceover]
    static let seriesTracks: [AudioTrack] = [originalEn, ruVoiceover, ruAmedia, ruCub]
    static let europeanTracks: [AudioTrack] = [originalFr, rubDubbing, deDub]
}

// MARK: - Sample Data

extension Movie {
    static let samples: [Movie] = [
        Movie(id: 1,  title: "Oppenheimer",              year: "2023", description: "The story of J. Robert Oppenheimer's role in the development of the atomic bomb during World War II.",                                                       imageName: "oppenheimer",      genre: "Drama",     rating: "8.9", duration: "3h 0m",    type: .movie,                                              audioTracks: AudioTrack.movieTracks),
        Movie(id: 2,  title: "Dune: Part Two",           year: "2024", description: "Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.",                                       imageName: "dune2",            genre: "Sci-Fi",    rating: "8.6", duration: "2h 46m",   type: .movie,                                              audioTracks: AudioTrack.movieTracks),
        Movie(id: 3,  title: "The Last Kingdom",         year: "2015", description: "A dispossessed Saxon nobleman fights to reclaim his birthright while serving King Alfred the Great in 9th century England.",                                    imageName: "lastkingdom",      genre: "Historical",rating: "8.5", duration: "5 Seasons",type: .series(seasons: Season.lastKingdomSeasons),          audioTracks: AudioTrack.seriesTracks),
        Movie(id: 4,  title: "Past Lives",               year: "2023", description: "Two childhood friends are separated for 20 years and reunite in New York City for one fateful week.",                                                          imageName: "pastlives",        genre: "Romance",   rating: "8.0", duration: "1h 46m",   type: .movie,                                              audioTracks: AudioTrack.movieTracks),
        Movie(id: 5,  title: "The Zone of Interest",     year: "2023", description: "The commandant of Auschwitz and his wife build their dream life next to the concentration camp.",                                                              imageName: "zone",             genre: "History",   rating: "7.9", duration: "1h 45m",   type: .movie,                                              audioTracks: AudioTrack.europeanTracks),
        Movie(id: 6,  title: "Silo",                     year: "2023", description: "In a ruined and toxic future, thousands live in a giant silo underground, where they believe the outside world is deadly.",                                     imageName: "silo",             genre: "Sci-Fi",    rating: "8.2", duration: "2 Seasons",type: .series(seasons: Season.siloSeasons),                audioTracks: AudioTrack.seriesTracks),
        Movie(id: 7,  title: "Saltburn",                 year: "2023", description: "A student at Oxford University finds himself drawn into the magnetic world of a charming and mysterious aristocrat.",                                          imageName: "saltburn",         genre: "Thriller",  rating: "7.3", duration: "2h 11m",   type: .movie,                                              audioTracks: [.originalEn, .rubDubbing]),
        Movie(id: 8,  title: "Maestro",                  year: "2023", description: "A complex love story portraying the lifelong relationship between Leonard Bernstein and Felicia Montealegre Cohn Bernstein.",                                  imageName: "maestro",          genre: "Biography", rating: "6.8", duration: "2h 9m",    type: .movie,                                              audioTracks: AudioTrack.movieTracks),
        Movie(id: 9,  title: "Severance",                year: "2022", description: "Mark leads a team of office workers whose memories have been surgically divided between their work and personal lives.",                                        imageName: "severance",        genre: "Thriller",  rating: "8.7", duration: "2 Seasons",type: .series(seasons: Season.severanceSeasons),           audioTracks: AudioTrack.seriesTracks),
        Movie(id: 10, title: "All of Us Strangers",      year: "2023", description: "A screenwriter begins a relationship with his mysterious neighbor, while also visiting his childhood home and the ghosts within.",                             imageName: "strangers",        genre: "Drama",     rating: "7.9", duration: "1h 42m",   type: .movie,                                              audioTracks: [.originalEn, .rubDubbing]),
        Movie(id: 11, title: "The Bear",                 year: "2022", description: "A young chef from the fine dining world comes to run his family's sandwich shop in Chicago, navigating grief, chaos, and excellence.",                         imageName: "thebear",          genre: "Drama",     rating: "8.7", duration: "3 Seasons",type: .series(seasons: Season.bearSeasons),                audioTracks: AudioTrack.seriesTracks),
        Movie(id: 12, title: "Ferrari",                  year: "2023", description: "Enzo Ferrari faces a pivotal summer that could redefine his legacy as the iconic race car manufacturer.",                                                      imageName: "ferrari",          genre: "Biography", rating: "6.8", duration: "2h 10m",   type: .movie,                                              audioTracks: AudioTrack.europeanTracks),
        Movie(id: 13, title: "Napoleon",                 year: "2023", description: "A personal look at the origins of Napoleon Bonaparte and his ambitious, relentless rise to emperor of France.",                                               imageName: "napoleon",         genre: "History",   rating: "6.4", duration: "2h 38m",   type: .movie,                                              audioTracks: AudioTrack.europeanTracks),
        Movie(id: 14, title: "Fallout",                  year: "2024", description: "In a post-apocalyptic future, a Vault dweller ventures into the brutal wasteland of Los Angeles.",                                                             imageName: "fallout",          genre: "Sci-Fi",    rating: "8.5", duration: "2 Seasons",type: .series(seasons: Season.falloutSeasons),             audioTracks: AudioTrack.seriesTracks),
        Movie(id: 15, title: "Society of the Snow",      year: "2024", description: "A Uruguayan rugby team crashes into the Andes and must fight to survive the brutal, unforgiving conditions.",                                                  imageName: "societyofsnow",    genre: "Survival",  rating: "7.9", duration: "2h 24m",   type: .movie,                                              audioTracks: AudioTrack.movieTracks),
        Movie(id: 16, title: "American Fiction",         year: "2023", description: "A frustrated novelist uses a pen name to write a book that satirizes the very racial stereotypes he despises.",                                               imageName: "americanfiction",  genre: "Comedy",    rating: "7.5", duration: "1h 52m",   type: .movie,                                              audioTracks: [.originalEn, .rubDubbing]),
        Movie(id: 17, title: "House of the Dragon",      year: "2022", description: "The story of House Targaryen, set 200 years before the events of Game of Thrones.",                                                                           imageName: "hotd",             genre: "Fantasy",   rating: "8.4", duration: "2 Seasons",type: .series(seasons: Season.hotdSeasons),                audioTracks: [.originalEn, .ruAmedia, .ruCub]),
        Movie(id: 18, title: "Rustin",                   year: "2023", description: "The story of Bayard Rustin, the brilliant strategist and activist who organized the legendary 1963 March on Washington.",                                      imageName: "rustin",           genre: "Biography", rating: "6.9", duration: "1h 46m",   type: .movie,                                              audioTracks: [.originalEn, .rubDubbing]),
        Movie(id: 19, title: "The Holdovers",            year: "2023", description: "A curmudgeonly instructor at a New England prep school is forced to remain on campus during Christmas break with a troubled student.",                          imageName: "holdovers",        genre: "Drama",     rating: "7.9", duration: "2h 13m",   type: .movie,                                              audioTracks: AudioTrack.movieTracks),
        Movie(id: 20, title: "Slow Horses",              year: "2022", description: "A team of British intelligence officers serve in a dumping ground for MI5 misfits, led by the brilliant but slovenly Jackson Lamb.",                           imageName: "slowhorses",       genre: "Spy",       rating: "8.2", duration: "4 Seasons",type: .series(seasons: Season.slowHorsesSeasons),          audioTracks: [.originalEn, .ruVoiceover, .ruCub]),
    ]
}

extension Season {
    static let severanceSeasons: [Season] = [
        Season(number: 1, year: "2022", episodes: [
            Episode(number: 1, title: "Good News About Hell",                    duration: "1h 1m",  description: "Mark begins a new chapter by taking a job at Lumon Industries."),
            Episode(number: 2, title: "Half Loop",                               duration: "52m",    description: "Mark's innie tries to acclimate to Lumon life."),
            Episode(number: 3, title: "In Perpetuity",                           duration: "52m",    description: "A formal work event is announced that compels reflection."),
            Episode(number: 4, title: "The You You Are",                         duration: "51m",    description: "After a breakthrough, the team is rewarded."),
            Episode(number: 5, title: "The Grim Barbarity of Optics and Design", duration: "54m",    description: "Helly questions her choices. Irving finds something disturbing."),
            Episode(number: 6, title: "Hide and Seek",                           duration: "58m",    description: "Cobel makes her intentions known."),
            Episode(number: 7, title: "Defiant Jazz",                            duration: "47m",    description: "The team prepares a plan of action."),
            Episode(number: 8, title: "What's for Dinner?",                      duration: "50m",    description: "Kier Eagan Appreciation Day culminates in a harrowing performance."),
            Episode(number: 9, title: "The We We Are",                           duration: "1h 10m", description: "Helly makes a drastic move. Mark faces a devastating revelation."),
        ]),
        Season(number: 2, year: "2025", episodes: [
            Episode(number: 1, title: "Hello, Ms. Cobel",    duration: "1h 5m", description: "Mark returns to Lumon. The innies discover startling truths."),
            Episode(number: 2, title: "Goodbye, Mrs. Selvig",duration: "56m",   description: "Cobel fights for survival. Dylan protects his family."),
            Episode(number: 3, title: "Who Is Alive?",       duration: "54m",   description: "The tempos receive an unexpected message."),
            Episode(number: 4, title: "Woe's Hollow",        duration: "58m",   description: "A field trip reveals Lumon's true nature."),
            Episode(number: 5, title: "Trojan's Horse",      duration: "53m",   description: "Mark's outie gets closer to the truth."),
        ]),
    ]

    static let bearSeasons: [Season] = [
        Season(number: 1, year: "2022", episodes: [
            Episode(number: 1, title: "System",   duration: "35m",    description: "Carmy arrives to run the family sandwich shop."),
            Episode(number: 2, title: "Hands",    duration: "30m",    description: "Carmy tries to implement fine dining practices in a chaotic kitchen."),
            Episode(number: 3, title: "Brigade",  duration: "30m",    description: "The crew struggles with Carmy's new systems."),
            Episode(number: 4, title: "Dogs",     duration: "28m",    description: "Carmy deals with a supplier dispute."),
            Episode(number: 5, title: "Sheridan", duration: "30m",    description: "Personal demons surface for several members of the team."),
            Episode(number: 6, title: "Ceres",    duration: "30m",    description: "The restaurant faces a health inspection."),
            Episode(number: 7, title: "Review",   duration: "29m",    description: "A critical review looms. Pressure reaches a breaking point."),
            Episode(number: 8, title: "Braciole", duration: "1h 8m",  description: "In real time, the kitchen descends into chaos during a brutal service."),
        ]),
        Season(number: 2, year: "2023", episodes: [
            Episode(number: 1,  title: "Beef",      duration: "39m",    description: "The restaurant is closed for renovation."),
            Episode(number: 2,  title: "Pasta",     duration: "28m",    description: "Marcus trains in Copenhagen."),
            Episode(number: 5,  title: "Forks",     duration: "55m",    description: "Richie's transformative stage at a Michelin-starred restaurant."),
            Episode(number: 6,  title: "Fishes",    duration: "1h 14m", description: "A Christmas Eve dinner reveals the Berzatto family's turbulent history."),
            Episode(number: 10, title: "The Bear",  duration: "46m",    description: "Opening night arrives. Everything could fall apart."),
        ]),
        Season(number: 3, year: "2024", episodes: [
            Episode(number: 1,  title: "Tomorrow", duration: "50m",  description: "The restaurant is open. Success brings new pressure."),
            Episode(number: 2,  title: "Next Week",duration: "31m",  description: "Carmy's obsession with perfection starts to isolate him."),
            Episode(number: 10, title: "Forever",  duration: "44m",  description: "The season culminates with questions about what it all means."),
        ]),
    ]

    static let lastKingdomSeasons: [Season] = [
        Season(number: 1, year: "2015", episodes: (1...8).map  { Episode(number: $0, title: "Episode \($0)", duration: "59m", description: "Uhtred fights for his place between Saxon and Danish worlds.") }),
        Season(number: 2, year: "2017", episodes: (1...8).map  { Episode(number: $0, title: "Episode \($0)", duration: "59m", description: "Uhtred serves King Alfred while seeking Bebbanburg.") }),
        Season(number: 3, year: "2018", episodes: (1...10).map { Episode(number: $0, title: "Episode \($0)", duration: "59m", description: "War rages across the kingdoms of England.") }),
        Season(number: 4, year: "2020", episodes: (1...10).map { Episode(number: $0, title: "Episode \($0)", duration: "59m", description: "Uhtred forges his own path toward destiny.") }),
        Season(number: 5, year: "2022", episodes: (1...10).map { Episode(number: $0, title: "Episode \($0)", duration: "59m", description: "The final battle for Bebbanburg and England begins.") }),
    ]

    static let siloSeasons: [Season] = [
        Season(number: 1, year: "2023", episodes: [
            Episode(number: 1,  title: "Freedom Day",       duration: "57m",    description: "Sheriff Holston makes a fateful request to go outside."),
            Episode(number: 2,  title: "Holston's Pick",    duration: "52m",    description: "Juliette is appointed the new sheriff."),
            Episode(number: 3,  title: "Execution",         duration: "49m",    description: "Juliette digs into the murder of the former sheriff."),
            Episode(number: 4,  title: "Truth",             duration: "51m",    description: "Juliette gets closer to the truth about the silo's origins."),
            Episode(number: 5,  title: "The Janitor's Boy", duration: "54m",    description: "A dangerous artifact surfaces."),
            Episode(number: 6,  title: "The Relic",         duration: "55m",    description: "Bernhard's past is explored."),
            Episode(number: 7,  title: "The Flamekeepers",  duration: "50m",    description: "The rebellion takes shape."),
            Episode(number: 8,  title: "Hanna",             duration: "56m",    description: "A sacrifice changes the course of events."),
            Episode(number: 9,  title: "The Getaway",       duration: "58m",    description: "Juliette is forced to make the most dangerous decision."),
            Episode(number: 10, title: "Outside",           duration: "1h 4m",  description: "Juliette steps into the unknown in the stunning finale."),
        ]),
        Season(number: 2, year: "2024", episodes: [
            Episode(number: 1, title: "The Stairs",   duration: "1h 2m", description: "Juliette navigates a hostile world outside."),
            Episode(number: 2, title: "Barricades",   duration: "55m",   description: "Sides are drawn inside the silo as the rebellion grows."),
            Episode(number: 3, title: "The Swamp",    duration: "52m",   description: "Juliette discovers something that changes everything."),
        ]),
    ]

    static let falloutSeasons: [Season] = [
        Season(number: 1, year: "2024", episodes: [
            Episode(number: 1, title: "The End",       duration: "1h 4m", description: "Lucy leaves Vault 33 to rescue her father in the wasteland."),
            Episode(number: 2, title: "The Target",    duration: "55m",   description: "Lucy crosses paths with The Ghoul and a Brotherhood soldier."),
            Episode(number: 3, title: "The Head",      duration: "52m",   description: "The search for a severed head leads deeper into danger."),
            Episode(number: 4, title: "The Ghouls",    duration: "49m",   description: "Lucy learns a devastating truth about her family."),
            Episode(number: 5, title: "The Past",      duration: "53m",   description: "Flashbacks reveal the origins of the apocalypse."),
            Episode(number: 6, title: "The Trap",      duration: "55m",   description: "Maximus faces a test of loyalty."),
            Episode(number: 7, title: "The Radio",     duration: "57m",   description: "Lucy, Maximus, and The Ghoul converge."),
            Episode(number: 8, title: "The Beginning", duration: "1h 6m", description: "The truth about New California is finally revealed."),
        ]),
        Season(number: 2, year: "2025", episodes: [
            Episode(number: 1, title: "New Vegas", duration: "1h 5m", description: "Lucy arrives in the neon wasteland of New Vegas."),
            Episode(number: 2, title: "The Pit",   duration: "54m",   description: "The Ghoul confronts his past in the city's underbelly."),
            Episode(number: 3, title: "War",       duration: "56m",   description: "Factions collide as the battle for New Vegas begins."),
        ]),
    ]

    static let hotdSeasons: [Season] = [
        Season(number: 1, year: "2022", episodes: [
            Episode(number: 1,  title: "The Heirs of the Dragon",    duration: "1h 6m",  description: "King Viserys hosts a tournament to celebrate the birth of his heir."),
            Episode(number: 2,  title: "The Rogue Prince",           duration: "57m",    description: "Daemon seizes Dragonstone. Viserys must choose a new queen."),
            Episode(number: 3,  title: "Second of His Name",         duration: "1h 3m",  description: "A hunt is held to celebrate the new prince."),
            Episode(number: 4,  title: "King of the Narrow Sea",     duration: "1h 1m",  description: "Daemon returns to King's Landing with an unexpected gift."),
            Episode(number: 5,  title: "We Light the Way",           duration: "1h 12m", description: "A royal betrothal causes a rift as the king travels north."),
            Episode(number: 6,  title: "The Princess and the Queen", duration: "1h 3m",  description: "A decade later, rivals jostle for position in a changed court."),
            Episode(number: 7,  title: "Driftmark",                  duration: "1h 5m",  description: "The funeral of Laena Velaryon tears the family apart."),
            Episode(number: 8,  title: "The Lord of the Tides",      duration: "1h 4m",  description: "The Driftmark succession threatens the realm."),
            Episode(number: 9,  title: "The Green Council",          duration: "59m",    description: "The greens convene to claim the throne."),
            Episode(number: 10, title: "The Black Queen",            duration: "1h 2m",  description: "Rhaenyra decides her next move."),
        ]),
        Season(number: 2, year: "2024", episodes: [
            Episode(number: 1, title: "A Son for a Son",             duration: "1h 0m", description: "The Dance of the Dragons begins with a brutal act of vengeance."),
            Episode(number: 2, title: "Rhaenyra the Cruel",          duration: "57m",   description: "Rhaenyra is blamed for the attack."),
            Episode(number: 3, title: "The Burning Mill",            duration: "1h 0m", description: "The river lords go to war."),
            Episode(number: 4, title: "The Red Dragon and the Gold", duration: "57m",   description: "The first great dragon battle of the Dance."),
            Episode(number: 5, title: "Regent",                      duration: "58m",   description: "A power vacuum at court sees unlikely figures rise."),
            Episode(number: 6, title: "Smallfolk",                   duration: "55m",   description: "The war takes its toll on common people."),
            Episode(number: 7, title: "The Red Sowing",              duration: "56m",   description: "Rhaenyra seeks new dragonriders."),
            Episode(number: 8, title: "The Lifetime of the Day",     duration: "1h 3m", description: "The season reaches its explosive conclusion."),
        ]),
    ]

    static let slowHorsesSeasons: [Season] = [
        Season(number: 1, year: "2022", episodes: [
            Episode(number: 1, title: "Failure to Fail",       duration: "46m", description: "Slough House receives a kidnapping case designed to embarrass MI5."),
            Episode(number: 2, title: "Work Placement",        duration: "42m", description: "The slow horses dig deeper into the conspiracy."),
            Episode(number: 3, title: "Cleaning Up",           duration: "43m", description: "The stakes escalate as a body turns up."),
            Episode(number: 4, title: "Visiting Hours",        duration: "45m", description: "River attempts to save the hostage before time runs out."),
            Episode(number: 5, title: "Negotiating from Strength", duration: "44m", description: "Lamb maneuvers against both the kidnappers and the Park."),
            Episode(number: 6, title: "The Merry Circus",      duration: "46m", description: "The truth behind the kidnapping is revealed."),
        ]),
        Season(number: 2, year: "2022", episodes: [
            Episode(number: 1, title: "Last Rites",    duration: "44m", description: "A suspicious death at Slough House kicks off a new investigation."),
            Episode(number: 2, title: "Sugar",         duration: "42m", description: "River uncovers a Cold War secret MI5 wants buried."),
            Episode(number: 3, title: "The Drop",      duration: "45m", description: "A Russian asset makes contact."),
            Episode(number: 4, title: "Cicada",        duration: "44m", description: "Sleeper agents are activated."),
            Episode(number: 5, title: "Slough House",  duration: "46m", description: "Loyalties are tested as the conspiracy reaches its peak."),
            Episode(number: 6, title: "Old Scores",    duration: "48m", description: "Lamb faces his own past to save his team."),
        ]),
        Season(number: 3, year: "2023", episodes: (1...6).map { Episode(number: $0, title: "Real Tigers Ep. \($0)",   duration: "44m", description: "A hostage situation forces Slough House into an impossible mission.") }),
        Season(number: 4, year: "2023", episodes: (1...6).map { Episode(number: $0, title: "Spook Street Ep. \($0)",  duration: "46m", description: "Lamb's past resurfaces with deadly consequences.") }),
    ]
}

// MARK: - Placeholder Art

private enum PlaceholderArt {
    static func generate(for movie: Movie, size: CGSize = CGSize(width: 440, height: 626)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        let accent = movie.accentColor
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        accent.getRed(&r, green: &g, blue: &b, alpha: nil)

        let topColor = UIColor(red: r * 0.9 + 0.05, green: g * 0.9 + 0.03, blue: b * 0.9 + 0.05, alpha: 1).cgColor
        let midColor = UIColor(red: r * 0.5 + 0.04, green: g * 0.5 + 0.03, blue: b * 0.5 + 0.06, alpha: 1).cgColor
        let botColor = UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1).cgColor
        let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [topColor, midColor, botColor] as CFArray, locations: [0, 0.5, 1.0])!
        ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: size.width * 0.3, y: size.height), options: [])

        ctx.saveGState()
        let orbRect = CGRect(x: -size.width * 0.1, y: -size.height * 0.05, width: size.width * 0.9, height: size.height * 0.65)
        let orbGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [UIColor(red: r, green: g, blue: b, alpha: 0.30).cgColor,
                                          UIColor(red: r, green: g, blue: b, alpha: 0.0).cgColor] as CFArray,
                                 locations: [0, 1])!
        ctx.addEllipse(in: orbRect); ctx.clip()
        ctx.drawRadialGradient(orbGrad,
                               startCenter: CGPoint(x: orbRect.midX, y: orbRect.midY), startRadius: 0,
                               endCenter: CGPoint(x: orbRect.midX, y: orbRect.midY),
                               endRadius: max(orbRect.width, orbRect.height) / 2, options: [])
        ctx.restoreGState()

        ctx.setStrokeColor(UIColor(white: 1, alpha: 0.04).cgColor); ctx.setLineWidth(1)
        let step: CGFloat = size.width / 6
        for i in 0...6 { ctx.move(to: CGPoint(x: step * CGFloat(i), y: 0)); ctx.addLine(to: CGPoint(x: step * CGFloat(i), y: size.height)) }
        ctx.strokePath()

        ctx.saveGState()
        let smallOrb = CGRect(x: size.width * 0.55, y: size.height * 0.6, width: size.width * 0.8, height: size.width * 0.8)
        let sg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: [UIColor(red: r * 0.7, green: g * 0.7, blue: b * 0.7, alpha: 0.18).cgColor, UIColor.clear.cgColor] as CFArray,
                            locations: [0, 1])!
        ctx.addEllipse(in: smallOrb); ctx.clip()
        ctx.drawRadialGradient(sg, startCenter: CGPoint(x: smallOrb.midX, y: smallOrb.midY), startRadius: 0,
                               endCenter: CGPoint(x: smallOrb.midX, y: smallOrb.midY), endRadius: max(smallOrb.width, smallOrb.height) / 2, options: [])
        ctx.restoreGState()
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Audio Track Picker

protocol AudioTrackPickerDelegate: AnyObject {
    func audioPicker(_ picker: AudioTrackPickerViewController, didSelect track: AudioTrack)
}

final class AudioTrackPickerViewController: UIViewController {

    weak var delegate: AudioTrackPickerDelegate?

    private let movie: AudioTrack?          // currently selected
    private let tracks: [AudioTrack]
    private let movieId: Int
    private var selectedId: String?

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1)
        v.layer.cornerRadius = 24; v.layer.cornerCurve = .continuous
        v.layer.shadowColor = UIColor.black.cgColor; v.layer.shadowOpacity = 0.8
        v.layer.shadowRadius = 60; v.layer.shadowOffset = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.text = "Озвучка"
        l.font = UIFont.systemFont(ofSize: 32, weight: .heavy); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private lazy var stackView: UIStackView = {
        let sv = UIStackView(); sv.axis = .vertical; sv.spacing = 8; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    init(tracks: [AudioTrack], movieId: Int, selectedId: String?) {
        self.tracks = tracks; self.movieId = movieId; self.selectedId = selectedId
        self.movie = tracks.first { $0.id == selectedId }
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.72)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 640),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 44),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -32),
        ])

        for track in tracks {
            let row = AudioTrackRow(track: track, isSelected: track.id == selectedId)
            row.onSelect = { [weak self] in self?.select(track) }
            stackView.addArrangedSubview(row)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        // focus on currently selected row
        stackView.arrangedSubviews.first(where: {
            ($0 as? AudioTrackRow)?.isCurrentlySelected == true
        }).map { [$0] } ?? [stackView.arrangedSubviews.first].compactMap { $0 }
    }

    private func select(_ track: AudioTrack) {
        selectedId = track.id
        WatchStore.shared.setSelectedAudioId(track.id, movieId: movieId)
        stackView.arrangedSubviews.forEach { ($0 as? AudioTrackRow)?.isCurrentlySelected = ($0 as? AudioTrackRow)?.trackId == track.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.dismiss(animated: true)
            self.delegate?.audioPicker(self, didSelect: track)
        }
    }
}

// MARK: - AudioTrackRow

final class AudioTrackRow: UIControl {

    let trackId: String
    var isCurrentlySelected: Bool { didSet { updateAppearance() } }
    var onSelect: (() -> Void)?

    private let flagLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 30); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 26, weight: .medium); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let checkIcon: UILabel = {
        let l = UILabel(); l.text = "✓"; l.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        l.textColor = .white; l.alpha = 0; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bgView: UIView = {
        let v = UIView(); v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(track: AudioTrack, isSelected: Bool) {
        self.trackId = track.id; self.isCurrentlySelected = isSelected
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        addSubview(bgView); addSubview(flagLabel); addSubview(titleLabel); addSubview(checkIcon)

        flagLabel.text = track.flag
        // Build title without flag (flag shown separately)
        switch track.kind {
        case .original:           titleLabel.text = "\(track.language)  ·  Оригинал"
        case .dubbing(let s):     titleLabel.text = "\(track.language)  ·  \(s)"
        case .voiceover(let s):   titleLabel.text = "\(track.language)  ·  \(s)  (Закадр)"
        }

        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),

            flagLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            flagLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            checkIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            checkIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        addTarget(self, action: #selector(tapped), for: .primaryActionTriggered)
        updateAppearance()
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onSelect?() }

    private func updateAppearance() {
        bgView.backgroundColor = isCurrentlySelected ? UIColor(white: 1, alpha: 0.14) : .clear
        checkIcon.alpha = isCurrentlySelected ? 1 : 0
        titleLabel.textColor = isCurrentlySelected ? .white : UIColor(white: 0.70, alpha: 1)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bgView.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.20)
                : (self.isCurrentlySelected ? UIColor(white: 1, alpha: 0.14) : .clear)
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.03, y: 1.03) : .identity
        }, completion: nil)
    }

    override var canBecomeFocused: Bool { true }
}

// MARK: - Shared UI

enum DetailButtonStyle { case primary, secondary }

final class DetailButton: UIButton {
    init(title: String, style: DetailButtonStyle) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 26, bottom: 0, trailing: 26)
        config.background.backgroundColor = .clear
        switch style {
        case .primary:   config.baseForegroundColor = .black
        case .secondary: config.baseForegroundColor = .white
        }
        configuration = config
        layer.cornerRadius = 12; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true
        switch style {
        case .primary:   backgroundColor = .white
        case .secondary:
            backgroundColor = UIColor(white: 1, alpha: 0.13)
            layer.borderWidth = 1; layer.borderColor = UIColor(white: 1, alpha: 0.2).cgColor
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.06, y: 1.06) : .identity
            self.layer.shadowOpacity = self.isFocused ? 0.28 : 0
            self.layer.shadowColor = UIColor.white.cgColor; self.layer.shadowRadius = 16; self.layer.shadowOffset = .zero
        }, completion: nil)
    }
}

final class MetaPill: UIView {
    init(text: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = color; layer.cornerRadius = 8; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        let l = UILabel(); l.text = text; l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = .white; l.translatesAutoresizingMaskIntoConstraints = false; addSubview(l)
        NSLayoutConstraint.activate([l.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
                                     l.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
                                     l.topAnchor.constraint(equalTo: topAnchor, constant: 6),
                                     l.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - MovieCell

final class MovieCell: UICollectionViewCell {
    static let reuseID = "MovieCell"

    private let posterImageView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.layer.cornerRadius = 14; iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let scrimLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.5).cgColor, UIColor.black.withAlphaComponent(0.92).cgColor]
        l.locations = [0.35, 0.65, 1.0]; return l
    }()
    private let rankLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        l.textColor = UIColor(white: 1, alpha: 0.18); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let seriesBadge: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.85)
        v.layer.cornerRadius = 6; v.isHidden = true; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let seriesBadgeLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 16, weight: .bold); l.textColor = .white
        l.text = "SERIES"; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let ratingPill: UIView = {
        let v = UIView(); v.layer.cornerRadius = 7; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let ratingLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 17, weight: .bold); l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 24, weight: .bold); l.textColor = .white
        l.numberOfLines = 2; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor = UIColor(white: 0.65, alpha: 1); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let focusBorderView: UIView = {
        let v = UIView(); v.backgroundColor = .clear; v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 3.5; v.layer.borderColor = UIColor.white.cgColor; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let focusGlowLayer: CALayer = {
        let l = CALayer(); l.cornerRadius = 14; l.borderWidth = 1
        l.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor; l.opacity = 0; return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 14; contentView.layer.cornerCurve = .continuous; contentView.clipsToBounds = false
        contentView.addSubview(posterImageView); contentView.layer.addSublayer(scrimLayer); contentView.layer.addSublayer(focusGlowLayer)
        contentView.addSubview(rankLabel); contentView.addSubview(seriesBadge); seriesBadge.addSubview(seriesBadgeLabel)
        contentView.addSubview(ratingPill); ratingPill.addSubview(ratingLabel)
        contentView.addSubview(titleLabel); contentView.addSubview(subtitleLabel); contentView.addSubview(focusBorderView)
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            rankLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            ratingPill.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            ratingPill.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            ratingPill.heightAnchor.constraint(equalToConstant: 30),
            ratingLabel.leadingAnchor.constraint(equalTo: ratingPill.leadingAnchor, constant: 8),
            ratingLabel.trailingAnchor.constraint(equalTo: ratingPill.trailingAnchor, constant: -8),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingPill.centerYAnchor),
            seriesBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            seriesBadge.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -8),
            seriesBadgeLabel.leadingAnchor.constraint(equalTo: seriesBadge.leadingAnchor, constant: 8),
            seriesBadgeLabel.trailingAnchor.constraint(equalTo: seriesBadge.trailingAnchor, constant: -8),
            seriesBadgeLabel.topAnchor.constraint(equalTo: seriesBadge.topAnchor, constant: 4),
            seriesBadgeLabel.bottomAnchor.constraint(equalTo: seriesBadge.bottomAnchor, constant: -4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            titleLabel.leadingAnchor.constraint(equalTo: subtitleLabel.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -5),
            titleLabel.trailingAnchor.constraint(equalTo: subtitleLabel.trailingAnchor),
            focusBorderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            focusBorderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            focusBorderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            focusBorderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.45; layer.shadowRadius = 14; layer.shadowOffset = CGSize(width: 0, height: 10)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrimLayer.frame = contentView.bounds; focusGlowLayer.frame = contentView.bounds.insetBy(dx: 1, dy: 1)
        let mask = CAShapeLayer(); mask.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 14).cgPath; scrimLayer.mask = mask
    }

    func configure(with movie: Movie, rank: Int) {
        titleLabel.text = movie.title; subtitleLabel.text = "\(movie.year)  ·  \(movie.genre)"
        rankLabel.text = "#\(rank)"; ratingLabel.text = "★ \(movie.rating)"
        ratingPill.backgroundColor = movie.accentColor.lighter(by: 0.5)
        posterImageView.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 440, height: 626))
        if case .series = movie.type { seriesBadge.isHidden = false } else { seriesBadge.isHidden = true }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.09, y: 1.09); self.layer.shadowOpacity = 0.9
                self.layer.shadowRadius = 32; self.layer.shadowOffset = CGSize(width: 0, height: 22)
                self.focusBorderView.alpha = 1; self.focusGlowLayer.opacity = 1
                self.titleLabel.alpha = 1; self.subtitleLabel.alpha = 1
            } else {
                self.transform = .identity; self.layer.shadowOpacity = 0.45; self.layer.shadowRadius = 14
                self.layer.shadowOffset = CGSize(width: 0, height: 10); self.focusBorderView.alpha = 0
                self.focusGlowLayer.opacity = 0; self.titleLabel.alpha = 0.85; self.subtitleLabel.alpha = 0.65
            }
        }, completion: nil)
    }
}

// MARK: - HeroPanel (info only — no buttons, focus cannot reach top panel)

final class HeroPanel: UIView {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))
    private let accentGlow: UIView = { let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    private let accentGlowLayer = CAGradientLayer()
    private let accentLine: UIView = { let v = UIView(); v.layer.cornerRadius = 2; v.translatesAutoresizingMaskIntoConstraints = false; return v }()
    private let posterView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.layer.cornerRadius = 12; iv.layer.cornerCurve = .continuous; iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 50, weight: .heavy); l.textColor = .white
        l.numberOfLines = 2; l.adjustsFontSizeToFitWidth = true; l.minimumScaleFactor = 0.75
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let metaStack: UIStackView = {
        let sv = UIStackView(); sv.axis = .horizontal; sv.spacing = 8; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()
    private let descLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        l.textColor = UIColor(white: 0.80, alpha: 1); l.numberOfLines = 3
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let hintLabel: UILabel = {
        let l = UILabel(); l.text = "Press  ◉  to open"
        l.font = UIFont.systemFont(ofSize: 22, weight: .medium); l.textColor = UIColor(white: 0.40, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let separator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.10)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let bottomFade: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]; l.locations = [0.7, 1.0]; return l
    }()

    override init(frame: CGRect) { super.init(frame: frame); build() }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        accentGlowLayer.type = .radial; accentGlowLayer.startPoint = CGPoint(x: 0, y: 0.5); accentGlowLayer.endPoint = CGPoint(x: 1, y: 0.5)
        accentGlow.layer.addSublayer(accentGlowLayer)
        blurView.contentView.addSubview(accentGlow); blurView.contentView.addSubview(accentLine); blurView.contentView.addSubview(posterView)
        blurView.contentView.addSubview(titleLabel); blurView.contentView.addSubview(metaStack)
        blurView.contentView.addSubview(descLabel); blurView.contentView.addSubview(hintLabel)
        blurView.contentView.addSubview(separator); layer.addSublayer(bottomFade)

        let inset: CGFloat = 72, pW: CGFloat = 186, pH = pW * 313 / 220
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor), blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor), blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            accentGlow.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            accentGlow.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            accentGlow.widthAnchor.constraint(equalToConstant: 500), accentGlow.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
            accentLine.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor, constant: inset),
            accentLine.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            accentLine.widthAnchor.constraint(equalToConstant: 4), accentLine.heightAnchor.constraint(equalToConstant: pH * 0.75),
            posterView.leadingAnchor.constraint(equalTo: accentLine.trailingAnchor, constant: 20),
            posterView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            posterView.widthAnchor.constraint(equalToConstant: pW), posterView.heightAnchor.constraint(equalToConstant: pH),
            titleLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 44),
            titleLabel.topAnchor.constraint(equalTo: posterView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor, constant: -inset),
            metaStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: metaStack.bottomAnchor, constant: 18),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            hintLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            hintLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor), separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor), separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        accentGlowLayer.frame = accentGlow.bounds
        bottomFade.frame = CGRect(x: 0, y: bounds.height - 60, width: bounds.width, height: 60)
    }

    func configure(with movie: Movie) {
        titleLabel.text = movie.title; descLabel.text = movie.description
        posterView.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 372, height: 530))
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let pills: [(String, UIColor)]
        if case .series(let seasons) = movie.type {
            pills = [("★ \(movie.rating)", UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)),
                     ("\(movie.year)–",    UIColor(white: 0.35, alpha: 1)),
                     (movie.genre,         movie.accentColor.withAlphaComponent(0.9)),
                     ("\(seasons.count) Seasons", UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.85))]
        } else {
            pills = [("★ \(movie.rating)", UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)),
                     (movie.year,          UIColor(white: 0.35, alpha: 1)),
                     (movie.genre,         movie.accentColor.withAlphaComponent(0.9)),
                     (movie.duration,      UIColor(white: 0.25, alpha: 1))]
        }
        pills.forEach { metaStack.addArrangedSubview(MetaPill(text: $0.0, color: $0.1)) }
        accentLine.backgroundColor = movie.accentColor.lighter(by: 0.6)
        accentGlowLayer.colors = [movie.accentColor.withAlphaComponent(0.28).cgColor, movie.accentColor.withAlphaComponent(0).cgColor]
    }
}

// MARK: - SeasonTabButton

final class SeasonTabButton: UIButton {

    private let accentBar: UIView = {
        let v = UIView(); v.layer.cornerRadius = 2; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    var accentColor: UIColor = .white { didSet { accentBar.backgroundColor = accentColor } }
    var isActiveSeason: Bool = false { didSet { updateLook(animated: true) } }

    init(season: Season) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("Season \(season.number)  ·  \(season.year)", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor(white: 0.50, alpha: 1)
        ]))
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 14, trailing: 20)
        config.background.backgroundColor = .clear
        configuration = config
        layer.cornerRadius = 10; layer.cornerCurve = .continuous
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)
        NSLayoutConstraint.activate([
            accentBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            accentBar.centerXAnchor.constraint(equalTo: centerXAnchor),
            accentBar.heightAnchor.constraint(equalToConstant: 3),
            accentBar.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.65),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private func updateLook(animated: Bool) {
        let color: UIColor = isActiveSeason ? .white : UIColor(white: 0.50, alpha: 1)
        let block = {
            var c = self.configuration ?? UIButton.Configuration.plain()
            c.baseForegroundColor = color
            self.configuration = c
            self.backgroundColor = self.isActiveSeason ? UIColor(white: 1, alpha: 0.10) : .clear
            self.accentBar.alpha = self.isActiveSeason ? 1 : 0
        }
        animated ? UIView.animate(withDuration: 0.2, animations: block) : block()
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            var c = self.configuration ?? UIButton.Configuration.plain()
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
                self.backgroundColor = UIColor(white: 1, alpha: 0.14)
                c.baseForegroundColor = .white
                self.layer.shadowColor = UIColor.white.cgColor; self.layer.shadowOpacity = 0.12
                self.layer.shadowRadius = 10; self.layer.shadowOffset = .zero
            } else {
                self.transform = .identity
                self.backgroundColor = self.isActiveSeason ? UIColor(white: 1, alpha: 0.10) : .clear
                c.baseForegroundColor = self.isActiveSeason ? .white : UIColor(white: 0.50, alpha: 1)
                self.layer.shadowOpacity = 0
            }
            self.configuration = c
        }, completion: nil)
    }
}

// MARK: - AudioTabButton

final class AudioTabButton: UIControl {

    var accentColor: UIColor = .white { didSet { updateAppearance() } }

    private let flagLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 24)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let trackLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let chevron: UILabel = {
        let l = UILabel(); l.text = "⌄"; l.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let leftSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.10)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let bgView: UIView = {
        let v = UIView(); v.layer.cornerRadius = 10; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let accentBarBottom: UIView = {
        let v = UIView(); v.layer.cornerRadius = 2; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftSeparator); addSubview(bgView)
        addSubview(flagLabel); addSubview(trackLabel); addSubview(chevron)
        addSubview(accentBarBottom)

        NSLayoutConstraint.activate([
            leftSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftSeparator.widthAnchor.constraint(equalToConstant: 1),
            leftSeparator.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            leftSeparator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leftSeparator.trailingAnchor, constant: 8),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),

            flagLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            flagLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            trackLabel.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 8),
            trackLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.leadingAnchor.constraint(equalTo: trackLabel.trailingAnchor, constant: 6),
            chevron.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -14),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2),

            accentBarBottom.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            accentBarBottom.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            accentBarBottom.heightAnchor.constraint(equalToConstant: 3),
            accentBarBottom.widthAnchor.constraint(equalTo: bgView.widthAnchor, multiplier: 0.65),
        ])

        addTarget(self, action: #selector(handleTap), for: .primaryActionTriggered)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with track: AudioTrack?) {
        guard let track else { return }
        flagLabel.text = track.flag
        switch track.kind {
        case .original:         trackLabel.text = track.language
        case .dubbing(let s):   trackLabel.text = "\(track.language) · \(s)"
        case .voiceover(let s): trackLabel.text = "\(track.language) · \(s)"
        }
        accentBarBottom.backgroundColor = accentColor
    }

    private func updateAppearance() {
        accentBarBottom.backgroundColor = accentColor
    }

    @objc private func handleTap() { sendActions(for: .primaryActionTriggered) }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
                self.bgView.backgroundColor = UIColor(white: 1, alpha: 0.14)
                self.trackLabel.textColor = .white
                self.chevron.textColor = UIColor(white: 0.65, alpha: 1)
                self.accentBarBottom.alpha = 1
                self.layer.shadowColor = UIColor.white.cgColor
                self.layer.shadowOpacity = 0.10; self.layer.shadowRadius = 10; self.layer.shadowOffset = .zero
            } else {
                self.transform = .identity
                self.bgView.backgroundColor = .clear
                self.trackLabel.textColor = UIColor(white: 0.55, alpha: 1)
                self.chevron.textColor = UIColor(white: 0.35, alpha: 1)
                self.accentBarBottom.alpha = 0
                self.layer.shadowOpacity = 0
            }
        }, completion: nil)
    }

    override var canBecomeFocused: Bool { true }
}



final class EpisodeCell: UICollectionViewCell {
    static let reuseID = "EpisodeCell"

    private let thumbView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.layer.cornerRadius = 10; iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let playCircle: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 0, alpha: 0.55); v.layer.cornerRadius = 26; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let playIcon: UILabel = {
        let l = UILabel(); l.text = "▶"; l.font = UIFont.systemFont(ofSize: 26, weight: .bold); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let numberLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
        l.textColor = UIColor(white: 0.40, alpha: 1); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 24, weight: .semibold); l.textColor = .white
        l.numberOfLines = 2; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let durationLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1); l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let descLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.62, alpha: 1); l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let watchedOverlay: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 0, alpha: 0.52)
        v.layer.cornerRadius = 10; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false; v.isHidden = true; return v
    }()
    private let watchedBadge: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 0.15, alpha: 0.92)
        v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false; v.isHidden = true; return v
    }()
    private let watchedIcon: UILabel = {
        let l = UILabel(); l.text = "✓"; l.font = UIFont.systemFont(ofSize: 18, weight: .heavy)
        l.textColor = UIColor(red: 0.25, green: 0.85, blue: 0.50, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let watchedLabel: UILabel = {
        let l = UILabel(); l.text = "Просмотрено"
        l.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        l.textColor = UIColor(white: 0.65, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let focusBorder: UIView = {
        let v = UIView(); v.backgroundColor = .clear; v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 2.5; v.layer.borderColor = UIColor.white.cgColor; v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor(white: 1, alpha: 0.06)
        contentView.layer.cornerRadius = 14; contentView.layer.cornerCurve = .continuous; contentView.clipsToBounds = false
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.3; layer.shadowRadius = 10; layer.shadowOffset = CGSize(width: 0, height: 6)

        contentView.addSubview(thumbView); contentView.addSubview(watchedOverlay)
        contentView.addSubview(watchedBadge); watchedBadge.addSubview(watchedIcon); watchedBadge.addSubview(watchedLabel)
        contentView.addSubview(playCircle); playCircle.addSubview(playIcon)
        contentView.addSubview(numberLabel); contentView.addSubview(titleLabel); contentView.addSubview(durationLabel)
        contentView.addSubview(descLabel); contentView.addSubview(focusBorder)

        NSLayoutConstraint.activate([
            thumbView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            thumbView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbView.widthAnchor.constraint(equalToConstant: 213),
            thumbView.heightAnchor.constraint(equalToConstant: 120),

            watchedOverlay.topAnchor.constraint(equalTo: thumbView.topAnchor),
            watchedOverlay.leadingAnchor.constraint(equalTo: thumbView.leadingAnchor),
            watchedOverlay.trailingAnchor.constraint(equalTo: thumbView.trailingAnchor),
            watchedOverlay.bottomAnchor.constraint(equalTo: thumbView.bottomAnchor),

            watchedBadge.trailingAnchor.constraint(equalTo: thumbView.trailingAnchor, constant: -8),
            watchedBadge.bottomAnchor.constraint(equalTo: thumbView.bottomAnchor, constant: -8),
            watchedBadge.heightAnchor.constraint(equalToConstant: 28),

            watchedIcon.leadingAnchor.constraint(equalTo: watchedBadge.leadingAnchor, constant: 8),
            watchedIcon.centerYAnchor.constraint(equalTo: watchedBadge.centerYAnchor),

            watchedLabel.leadingAnchor.constraint(equalTo: watchedIcon.trailingAnchor, constant: 5),
            watchedLabel.trailingAnchor.constraint(equalTo: watchedBadge.trailingAnchor, constant: -8),
            watchedLabel.centerYAnchor.constraint(equalTo: watchedBadge.centerYAnchor),

            playCircle.centerXAnchor.constraint(equalTo: thumbView.centerXAnchor),
            playCircle.centerYAnchor.constraint(equalTo: thumbView.centerYAnchor),
            playCircle.widthAnchor.constraint(equalToConstant: 52), playCircle.heightAnchor.constraint(equalToConstant: 52),
            playIcon.centerXAnchor.constraint(equalTo: playCircle.centerXAnchor, constant: 3),
            playIcon.centerYAnchor.constraint(equalTo: playCircle.centerYAnchor),

            numberLabel.leadingAnchor.constraint(equalTo: thumbView.trailingAnchor, constant: 22),
            numberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),

            titleLabel.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: numberLabel.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -16),

            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            durationLabel.topAnchor.constraint(equalTo: numberLabel.topAnchor),

            descLabel.leadingAnchor.constraint(equalTo: numberLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),

            focusBorder.topAnchor.constraint(equalTo: contentView.topAnchor),
            focusBorder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            focusBorder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            focusBorder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with episode: Episode, movie: Movie, isWatched: Bool) {
        numberLabel.text = "E\(episode.number)"; titleLabel.text = episode.title
        durationLabel.text = episode.duration; descLabel.text = episode.description
        thumbView.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 426, height: 240))

        let watched = isWatched
        watchedOverlay.isHidden = !watched
        watchedBadge.isHidden = !watched
        // Dim text for watched episodes
        titleLabel.alpha = watched ? 0.45 : 1.0
        numberLabel.alpha = watched ? 0.35 : 1.0
        descLabel.alpha = watched ? 0.35 : 1.0
        durationLabel.alpha = watched ? 0.35 : 1.0
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
                self.contentView.backgroundColor = UIColor(white: 1, alpha: 0.11)
                self.focusBorder.alpha = 1; self.playCircle.alpha = 1
                // Always show full alpha on focus regardless of watched state
                self.titleLabel.alpha = 1; self.numberLabel.alpha = 1
                self.descLabel.alpha = 0.8; self.durationLabel.alpha = 0.8
                self.layer.shadowOpacity = 0.7; self.layer.shadowRadius = 20
            } else {
                self.transform = .identity; self.contentView.backgroundColor = UIColor(white: 1, alpha: 0.06)
                self.focusBorder.alpha = 0; self.playCircle.alpha = 0
                self.layer.shadowOpacity = 0.3; self.layer.shadowRadius = 10
                // Re-apply watched dimming
                let watched = !self.watchedOverlay.isHidden
                self.titleLabel.alpha = watched ? 0.45 : 1.0
                self.numberLabel.alpha = watched ? 0.35 : 1.0
                self.descLabel.alpha = watched ? 0.35 : 1.0
                self.durationLabel.alpha = watched ? 0.35 : 1.0
            }
        }, completion: nil)
    }
}

// MARK: - MovieDetailViewController

final class MovieDetailViewController: UIViewController {

    private let movie: Movie
    private var currentSeasonIndex = 0
    private var seasonTabButtons: [SeasonTabButton] = []
    private var selectedAudio: AudioTrack?

    // MARK: Background

    private lazy var backdropIV: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 1920, height: 1080))
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark)); v.alpha = 0.92
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    // MARK: Left Panel

    private lazy var posterIV: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true
        iv.layer.cornerRadius = 16; iv.layer.cornerCurve = .continuous
        iv.layer.shadowColor = UIColor.black.cgColor; iv.layer.shadowOpacity = 0.7
        iv.layer.shadowRadius = 28; iv.layer.shadowOffset = CGSize(width: 0, height: 14)
        iv.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 550, height: 782))
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private lazy var accentStripe: UIView = {
        let v = UIView(); v.backgroundColor = movie.accentColor.lighter(by: 0.5)
        v.layer.cornerRadius = 3; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private lazy var titleLabel: UILabel = {
        let l = UILabel(); l.text = movie.title; l.font = UIFont.systemFont(ofSize: 42, weight: .heavy)
        l.textColor = .white; l.numberOfLines = 2; l.adjustsFontSizeToFitWidth = true; l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private lazy var metaRow: UIStackView = {
        let sv = UIStackView(); sv.axis = .horizontal; sv.spacing = 8; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        let pills: [(String, UIColor)]
        if case .series(let seasons) = movie.type {
            pills = [("★ \(movie.rating)", UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)),
                     ("\(movie.year)–",    UIColor(white: 0.32, alpha: 1)),
                     (movie.genre,         movie.accentColor.withAlphaComponent(0.9)),
                     ("\(seasons.count) Seasons", UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.85))]
        } else {
            pills = [("★ \(movie.rating)", UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)),
                     (movie.year,          UIColor(white: 0.32, alpha: 1)),
                     (movie.genre,         movie.accentColor.withAlphaComponent(0.9)),
                     (movie.duration,      UIColor(white: 0.25, alpha: 1))]
        }
        pills.forEach { sv.addArrangedSubview(MetaPill(text: $0.0, color: $0.1)) }
        return sv
    }()
    private lazy var descLabel: UILabel = {
        let l = UILabel(); l.text = movie.description; l.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        l.textColor = UIColor(white: 0.78, alpha: 1); l.numberOfLines = 4
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let watchBtn    = DetailButton(title: "▶  Watch",    style: .primary)
    private let myListBtn   = DetailButton(title: "+  My List",  style: .secondary)
    private let trailerBtn  = DetailButton(title: "⊳  Trailer",  style: .secondary)
    private lazy var btnStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [watchBtn, myListBtn, trailerBtn])
        sv.axis = .horizontal; sv.spacing = 14; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()

    // MARK: Episodes Panel (bottom)

    private lazy var episodesPanelContainer: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; v.isHidden = true; return v
    }()
    private let episodesDivider: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.09)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private lazy var seasonTabsStack: UIStackView = {
        let sv = UIStackView(); sv.axis = .horizontal; sv.spacing = 6; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()
    private let audioTabSpacer: UIView = {
        // flexible spacer to push audio tab to the right
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.setContentHuggingPriority(.defaultLow, for: .horizontal)
        v.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return v
    }()
    private lazy var audioTabButton: AudioTabButton = {
        let b = AudioTabButton()
        b.accentColor = movie.accentColor.lighter(by: 0.5)
        b.addTarget(self, action: #selector(audioTapped), for: .primaryActionTriggered)
        return b
    }()
    private let tabsSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private lazy var episodesCV: UICollectionView = {
        let layout = UICollectionViewFlowLayout(); layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 14; layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 60, right: 0)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear; cv.remembersLastFocusedIndexPath = true
        cv.register(EpisodeCell.self, forCellWithReuseIdentifier: EpisodeCell.reuseID)
        cv.dataSource = self; cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false; return cv
    }()

    init(movie: Movie) { self.movie = movie; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        buildLayout()
        setupSeriesIfNeeded()
        setupAudio()
    }

    private func setupAudio() {
        let savedId = WatchStore.shared.selectedAudioId(movieId: movie.id)
        selectedAudio = movie.audioTracks.first { $0.id == savedId } ?? movie.audioTracks.first
        // Audio tab is only added for series (called after setupSeriesIfNeeded adds season tabs)
        // For movies the tab row is hidden entirely — so we add it here for series only
        updateAudioTab()
    }

    private func updateAudioTab() {
        guard movie.audioTracks.count > 1 else { return }
        audioTabButton.configure(with: selectedAudio)
    }

    @objc private func audioTapped() {
        let picker = AudioTrackPickerViewController(
            tracks: movie.audioTracks,
            movieId: movie.id,
            selectedId: selectedAudio?.id
        )
        picker.delegate = self
        present(picker, animated: true)
    }

    private func buildLayout() {
        view.addSubview(backdropIV); view.addSubview(backdropBlur)
        view.addSubview(posterIV); view.addSubview(accentStripe)
        view.addSubview(titleLabel); view.addSubview(metaRow); view.addSubview(descLabel); view.addSubview(btnStack)
        view.addSubview(episodesPanelContainer)
        episodesPanelContainer.addSubview(episodesDivider)
        episodesPanelContainer.addSubview(seasonTabsStack)
        episodesPanelContainer.addSubview(tabsSeparator)
        episodesPanelContainer.addSubview(episodesCV)

        let lInset: CGFloat = 64
        let hInset: CGFloat = 80

        NSLayoutConstraint.activate([
            backdropIV.topAnchor.constraint(equalTo: view.topAnchor), backdropIV.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropIV.trailingAnchor.constraint(equalTo: view.trailingAnchor), backdropIV.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor), backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor), backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Poster — top left
            posterIV.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: lInset),
            posterIV.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
            posterIV.widthAnchor.constraint(equalToConstant: 220),
            posterIV.heightAnchor.constraint(equalToConstant: 313),

            // Accent stripe next to poster
            accentStripe.leadingAnchor.constraint(equalTo: posterIV.trailingAnchor, constant: 28),
            accentStripe.topAnchor.constraint(equalTo: posterIV.topAnchor, constant: 8),
            accentStripe.widthAnchor.constraint(equalToConstant: 4),
            accentStripe.heightAnchor.constraint(equalToConstant: 250),

            // Title / meta / desc / buttons aligned next to accent stripe, spanning wider
            titleLabel.leadingAnchor.constraint(equalTo: accentStripe.trailingAnchor, constant: 22),
            titleLabel.topAnchor.constraint(equalTo: posterIV.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),

            metaRow.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),

            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: metaRow.bottomAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),

            btnStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            btnStack.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 26),

            // Episodes panel below poster + info block
            episodesPanelContainer.topAnchor.constraint(equalTo: posterIV.bottomAnchor, constant: 48),
            episodesPanelContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            episodesPanelContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            episodesPanelContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            episodesDivider.topAnchor.constraint(equalTo: episodesPanelContainer.topAnchor),
            episodesDivider.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            episodesDivider.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),
            episodesDivider.heightAnchor.constraint(equalToConstant: 1),

            seasonTabsStack.topAnchor.constraint(equalTo: episodesDivider.bottomAnchor, constant: 24),
            seasonTabsStack.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            seasonTabsStack.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),

            tabsSeparator.topAnchor.constraint(equalTo: seasonTabsStack.bottomAnchor, constant: 10),
            tabsSeparator.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            tabsSeparator.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),
            tabsSeparator.heightAnchor.constraint(equalToConstant: 1),

            episodesCV.topAnchor.constraint(equalTo: tabsSeparator.bottomAnchor),
            episodesCV.leadingAnchor.constraint(equalTo: episodesPanelContainer.leadingAnchor, constant: hInset),
            episodesCV.trailingAnchor.constraint(equalTo: episodesPanelContainer.trailingAnchor, constant: -hInset),
            episodesCV.bottomAnchor.constraint(equalTo: episodesPanelContainer.bottomAnchor),
        ])
    }

    private func setupSeriesIfNeeded() {
        guard case .series(let seasons) = movie.type else { return }
        episodesPanelContainer.isHidden = false

        for (i, season) in seasons.enumerated() {
            let btn = SeasonTabButton(season: season)
            btn.accentColor = movie.accentColor.lighter(by: 0.5)
            btn.isActiveSeason = (i == 0)
            btn.tag = i
            btn.addTarget(self, action: #selector(seasonTapped(_:)), for: .primaryActionTriggered)
            seasonTabsStack.addArrangedSubview(btn)
            seasonTabButtons.append(btn)
        }

        // Audio tab — push to trailing edge with spacer
        if movie.audioTracks.count > 1 {
            seasonTabsStack.addArrangedSubview(audioTabSpacer)
            seasonTabsStack.addArrangedSubview(audioTabButton)
        }

        scrollToFirstUnwatched(animated: false)
    }

    private func scrollToFirstUnwatched(animated: Bool) {
        guard let season = currentSeason() else { return }
        if let idx = WatchStore.shared.firstUnwatchedIndex(movieId: movie.id, season: season) {
            let ip = IndexPath(item: idx, section: 0)
            DispatchQueue.main.async {
                self.episodesCV.scrollToItem(at: ip, at: .top, animated: animated)
            }
        }
    }

    @objc private func seasonTapped(_ sender: SeasonTabButton) {
        guard sender.tag != currentSeasonIndex else { return }
        seasonTabButtons[currentSeasonIndex].isActiveSeason = false
        currentSeasonIndex = sender.tag
        seasonTabButtons[currentSeasonIndex].isActiveSeason = true

        UIView.animate(withDuration: 0.14, animations: { self.episodesCV.alpha = 0 }) { _ in
            self.episodesCV.reloadData()
            self.scrollToFirstUnwatched(animated: false)
            UIView.animate(withDuration: 0.18) { self.episodesCV.alpha = 1 }
        }
    }

    private func currentSeason() -> Season? {
        guard case .series(let seasons) = movie.type else { return nil }
        return seasons[safe: currentSeasonIndex]
    }
}

extension MovieDetailViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        currentSeason()?.episodes.count ?? 0
    }
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: EpisodeCell.reuseID, for: ip) as! EpisodeCell
        if let season = currentSeason(), let ep = season.episodes[safe: ip.item] {
            let watched = WatchStore.shared.isWatched(movieId: movie.id, season: season.number, episode: ep.number)
            cell.configure(with: ep, movie: movie, isWatched: watched)
        }
        return cell
    }
}

extension MovieDetailViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        guard let season = currentSeason(), let ep = season.episodes[safe: ip.item] else { return }
        let store = WatchStore.shared
        let wasWatched = store.isWatched(movieId: movie.id, season: season.number, episode: ep.number)
        store.setWatched(!wasWatched, movieId: movie.id, season: season.number, episode: ep.number)
        cv.reloadItems(at: [ip])
    }
}

extension MovieDetailViewController: AudioTrackPickerDelegate {
    func audioPicker(_ picker: AudioTrackPickerViewController, didSelect track: AudioTrack) {
        selectedAudio = track
        updateAudioTab()
    }
}

extension MovieDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt ip: IndexPath) -> CGSize {
        CGSize(width: cv.bounds.width, height: 166)
    }
}

// MARK: - MainController

final class MainController: UIViewController {

    private let movies = Movie.samples
    private var currentFocusedIndex: Int? = nil
    private var detailDebounceTimer: Timer?
    private var pendingMovie: Movie?

    private lazy var backdropImageView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFill; iv.clipsToBounds = true; iv.alpha = 0
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark)); v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let vignetteLayer: CAGradientLayer = {
        let l = CAGradientLayer(); l.type = .radial
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.70).cgColor]
        l.startPoint = CGPoint(x: 0.5, y: 0.5); l.endPoint = CGPoint(x: 1.0, y: 1.0); return l
    }()
    private let baseGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 1).cgColor,
                    UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1).cgColor]; return l
    }()
    private lazy var logoLabel: UILabel = {
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "FILMIX", attributes: [
            .kern: CGFloat(8), .font: UIFont.systemFont(ofSize: 38, weight: .heavy), .foregroundColor: UIColor.white])
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let logoAccentDot: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)
        v.layer.cornerRadius = 5; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private lazy var sectionLabel: UILabel = {
        let l = UILabel(); l.text = "Popular"
        l.font = UIFont.systemFont(ofSize: 30, weight: .medium); l.textColor = UIColor(white: 0.65, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let headerSeparator: UIView = {
        let v = UIView(); v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private lazy var heroPanel: HeroPanel = {
        let p = HeroPanel(); p.alpha = 0; p.translatesAutoresizingMaskIntoConstraints = false; return p
    }()
    private lazy var heroPanelHeightConstraint = heroPanel.heightAnchor.constraint(equalToConstant: 0)
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeFlowLayout())
        cv.backgroundColor = .clear; cv.remembersLastFocusedIndexPath = true
        cv.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseID)
        cv.dataSource = self; cv.delegate = self; cv.translatesAutoresizingMaskIntoConstraints = false; return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.insertSublayer(baseGradientLayer, at: 0)
        view.addSubview(backdropImageView); view.layer.addSublayer(vignetteLayer); view.addSubview(backdropBlur)
        view.addSubview(logoLabel); view.addSubview(logoAccentDot); view.addSubview(sectionLabel)
        view.addSubview(headerSeparator); view.addSubview(heroPanel); view.addSubview(collectionView)
        heroPanelHeightConstraint.isActive = true
        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor), backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor), backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor), backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor), backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            logoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 52), logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            logoAccentDot.widthAnchor.constraint(equalToConstant: 10), logoAccentDot.heightAnchor.constraint(equalToConstant: 10),
            logoAccentDot.leadingAnchor.constraint(equalTo: logoLabel.trailingAnchor, constant: 4),
            logoAccentDot.bottomAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: -6),
            sectionLabel.centerYAnchor.constraint(equalTo: logoLabel.centerYAnchor),
            sectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            headerSeparator.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 18),
            headerSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            headerSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1),
            heroPanel.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor, constant: 16),
            heroPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor), heroPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroPanelHeightConstraint,
            collectionView.topAnchor.constraint(equalTo: heroPanel.bottomAnchor, constant: 60),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor), collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baseGradientLayer.frame = view.bounds; vignetteLayer.frame = view.bounds
    }

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let l = UICollectionViewFlowLayout(); l.scrollDirection = .vertical
        l.minimumInteritemSpacing = 28; l.minimumLineSpacing = 44
        l.sectionInset = UIEdgeInsets(top: 0, left: 80, bottom: 80, right: 80); return l
    }

    private func cellSize() -> CGSize {
        let width = view.bounds.width
        let horizontalPadding: CGFloat = 80 * 2
        let spacing: CGFloat = 28 * 4
        
        let w = floor((width - horizontalPadding - spacing) / 5)
        let h = floor(w * 313 / 220)
        
        return CGSize(width: w, height: h)
    }

    private func showHeroPanel(for movie: Movie) {
        heroPanel.configure(with: movie)
        UIView.transition(with: backdropImageView, duration: 0.55, options: .transitionCrossDissolve) {
            self.backdropImageView.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 1920, height: 1080))
        }
        if heroPanel.alpha < 0.5 {
            heroPanelHeightConstraint.constant = 290
            heroPanel.transform = CGAffineTransform(translationX: 0, y: -20)
            UIView.animate(withDuration: 0.40, delay: 0, options: .curveEaseOut) {
                self.heroPanel.alpha = 1; self.heroPanel.transform = .identity
                self.backdropImageView.alpha = 0.22; self.backdropBlur.alpha = 0.60; self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.20) { self.heroPanel.alpha = 1 }
        }
    }

    private func hideHeroPanel() {
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseIn) {
            self.heroPanel.alpha = 0; self.heroPanel.transform = CGAffineTransform(translationX: 0, y: -10)
            self.backdropImageView.alpha = 0; self.backdropBlur.alpha = 0
            self.heroPanelHeightConstraint.constant = 0; self.view.layoutIfNeeded()
        } completion: { _ in self.heroPanel.transform = .identity }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if let cell = context.nextFocusedItem as? MovieCell, let ip = collectionView.indexPath(for: cell) {
            let movie = movies[ip.item]
            guard ip.item != currentFocusedIndex else { return }
            currentFocusedIndex = ip.item; detailDebounceTimer?.invalidate(); pendingMovie = movie
            detailDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: false) { [weak self] _ in
                guard let self, let m = self.pendingMovie else { return }
                self.showHeroPanel(for: m)
            }
        } else if !(context.nextFocusedItem is MovieCell) {
            detailDebounceTimer?.invalidate(); pendingMovie = nil; currentFocusedIndex = nil; hideHeroPanel()
        }
    }
}

extension MainController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int { movies.count }
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseID, for: ip) as! MovieCell
        cell.configure(with: movies[ip.item], rank: ip.item + 1); return cell
    }
}

extension MainController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        present(MovieDetailViewController(movie: movies[ip.item]), animated: true)
    }
}

extension MainController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt ip: IndexPath) -> CGSize { cellSize() }
}

// MARK: - Helpers

private extension UIColor {
    func lighter(by f: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r + (1-r)*f, 1), green: min(g + (1-g)*f, 1), blue: min(b + (1-b)*f, 1), alpha: a)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
