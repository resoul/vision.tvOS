import Foundation

enum L10n {
    static var bundle: Bundle = .main
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: bundle)
    }
    
    enum Tab {
        static var home:        String { L10n.string("tab.home") }
        static var movies:      String { L10n.string("tab.movies") }
        static var series:      String { L10n.string("tab.series") }
        static var cartoons:    String { L10n.string("tab.cartoons") }
        static var favorites:   String { L10n.string("tab.favorites") }
        static var watchHistory: String { L10n.string("tab.watch_history") }
        static var search:      String { L10n.string("tab.search") }
    }

    enum Genre {
        enum Movies {
            static var action:       String { L10n.string("genre.movies.action") }
            static var comedy:       String { L10n.string("genre.movies.comedy") }
            static var drama:        String { L10n.string("genre.movies.drama") }
            static var thriller:     String { L10n.string("genre.movies.thriller") }
            static var horror:       String { L10n.string("genre.movies.horror") }
            static var scifi:        String { L10n.string("genre.movies.scifi") }
            static var fantasy:      String { L10n.string("genre.movies.fantasy") }
            static var adventure:    String { L10n.string("genre.movies.adventure") }
            static var animation:    String { L10n.string("genre.movies.animation") }
            static var documentary:  String { L10n.string("genre.movies.documentary") }
            static var crime:        String { L10n.string("genre.movies.crime") }
            static var romance:      String { L10n.string("genre.movies.romance") }
            static var biography:    String { L10n.string("genre.movies.biography") }
            static var history:      String { L10n.string("genre.movies.history") }
            static var sport:        String { L10n.string("genre.movies.sport") }
        }
        enum Series {
            static var action:       String { L10n.string("genre.series.action") }
            static var comedy:       String { L10n.string("genre.series.comedy") }
            static var drama:        String { L10n.string("genre.series.drama") }
            static var thriller:     String { L10n.string("genre.series.thriller") }
            static var horror:       String { L10n.string("genre.series.horror") }
            static var scifi:        String { L10n.string("genre.series.scifi") }
            static var fantasy:      String { L10n.string("genre.series.fantasy") }
            static var crime:        String { L10n.string("genre.series.crime") }
            static var romance:      String { L10n.string("genre.series.romance") }
            static var anime:        String { L10n.string("genre.series.anime") }
            static var documentary:  String { L10n.string("genre.series.documentary") }
            static var reality:      String { L10n.string("genre.series.reality") }
        }
        enum Cartoons {
            static var kids:         String { L10n.string("genre.cartoons.kids") }
            static var anime:        String { L10n.string("genre.cartoons.anime") }
            static var adventure:    String { L10n.string("genre.cartoons.adventure") }
            static var comedy:       String { L10n.string("genre.cartoons.comedy") }
            static var scifi:        String { L10n.string("genre.cartoons.scifi") }
            static var fantasy:      String { L10n.string("genre.cartoons.fantasy") }
            static var family:       String { L10n.string("genre.cartoons.family") }
            static var series:       String { L10n.string("genre.cartoons.series") }
        }
    }

    enum Settings {
        static var title:         String { L10n.string("settings.title") }
        enum Autoplay {
            static var title:     String { L10n.string("settings.autoplay.title") }
            static var on:        String { L10n.string("settings.autoplay.on") }
            static var off:       String { L10n.string("settings.autoplay.off") }
        }
        enum Quality {
            static var title:     String { L10n.string("settings.quality.title") }
        }
        enum Theme {
            static var title:     String { L10n.string("settings.theme.title") }
            static var dark:      String { L10n.string("settings.theme.dark") }
            static var light:     String { L10n.string("settings.theme.light") }
            static var midnight:  String { L10n.string("settings.theme.midnight") }
        }
        enum Language {
            static var title:     String { L10n.string("settings.language.title") }
        }
        enum Font {
            static var title:     String { L10n.string("settings.font.title") }
        }
        enum Section {
            static var playback:  String { L10n.string("settings.section.playback") }
            static var interface: String { L10n.string("settings.section.interface") }
            static var memory:    String { L10n.string("settings.section.memory") }
            static var storage:   String { L10n.string("settings.section.storage") }
            static var about:     String { L10n.string("settings.section.about") }
        }
        enum Cache {
            static var title:     String { L10n.string("settings.cache.title") }
            static var hint:      String { L10n.string("settings.cache.hint") }
            static var noLimit:   String { L10n.string("settings.cache.no_limit") }
        }
        enum Storage {
            static var posters:      String { L10n.string("settings.storage.posters") }
            static var history:      String { L10n.string("settings.storage.history") }
            static var favorites:    String { L10n.string("settings.storage.favorites") }
            static var database:     String { L10n.string("settings.storage.database") }
            static var preferences:  String { L10n.string("settings.storage.preferences") }
            static var clearPosters: String { L10n.string("settings.storage.clear_posters") }
            static var clearHistory: String { L10n.string("settings.storage.clear_history") }
            
            enum Confirm {
                static var clearPosters: String { L10n.string("settings.storage.confirm.clear_posters") }
                static var clearHistory: String { L10n.string("settings.storage.confirm.clear_history") }
            }
        }
        enum About {
            static var version:   String { L10n.string("settings.about.version") }
        }
    }


    enum Player {
        enum Resume {
            static var title:     String { L10n.string("player.resume.title") }
            static func message(_ time: String) -> String {
                String(format: L10n.string("player.resume.message"), time)
            }
            static var `continue`: String { L10n.string("player.resume.continue") }
            static var restart:   String { L10n.string("player.resume.restart") }
        }
    }
    
    enum Common {
        static var cancel:        String { L10n.string("common.cancel") }
        static var back:          String { L10n.string("common.back") }
        static var confirm:       String { L10n.string("common.confirm") }
    }

    enum Detail {
        static var inFavorites:   String { L10n.string("detail.favorites.in") }
        static var addToFavorites: String { L10n.string("detail.favorites.add") }
        static var watch:         String { L10n.string("detail.watch") }
        static var playbackUnavailable: String { L10n.string("detail.playback_unavailable") }
        static var audioTrack:    String { L10n.string("detail.audio_track") }
        static var country:       String { L10n.string("detail.country") }
        static var director:      String { L10n.string("detail.director") }
        static var writer:        String { L10n.string("detail.writer") }
        static var actors:        String { L10n.string("detail.actors") }
        static var slogan:        String { L10n.string("detail.slogan") }
        static var season:        String { L10n.string("detail.season") }
        static var watched:       String { L10n.string("detail.watched") }
    }

    enum Search {
        static var placeholder:  String { L10n.string("search.placeholder") }
        static var emptyResults: String { L10n.string("search.empty_results") }
    }
}
