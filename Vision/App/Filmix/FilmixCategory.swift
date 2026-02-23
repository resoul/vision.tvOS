import Foundation

struct FilmixCategory {
    let title: String
    let url: String
    let icon: String
    var isFavorites: Bool = false
    var genres: [FilmixGenre] = []

    static let all: [FilmixCategory] = [
        FilmixCategory(title: "Главная",     url: "https://filmix.my",          icon: "house.fill"),
        FilmixCategory(title: "Фильмы",      url: "https://filmix.my/film/",    icon: "film.fill",          genres: FilmixGenre.movies),
        FilmixCategory(title: "Сериалы",     url: "https://filmix.my/seria/",   icon: "tv.fill",            genres: FilmixGenre.series),
        FilmixCategory(title: "Мультфильмы", url: "https://filmix.my/mults/",   icon: "sparkles.tv.fill",   genres: FilmixGenre.cartoons),
        FilmixCategory(title: "Избранное",   url: "",                           icon: "star.fill", isFavorites: true),
    ]
}

struct FilmixGenre {
    let title: String
    let url: String

    static let movies: [FilmixGenre] = [
        FilmixGenre(title: "Аниме",          url: "https://filmix.my/film/animes/"),
        FilmixGenre(title: "Биография",      url: "https://filmix.my/film/biografia/"),
        FilmixGenre(title: "Боевики",        url: "https://filmix.my/film/boevik/"),
        FilmixGenre(title: "Вестерн",        url: "https://filmix.my/film/vesterny/"),
        FilmixGenre(title: "Военный",        url: "https://filmix.my/film/voennyj/"),
        FilmixGenre(title: "Детектив",       url: "https://filmix.my/film/detektivy/"),
        FilmixGenre(title: "Детский",        url: "https://filmix.my/film/detskij/"),
        FilmixGenre(title: "Для взрослых",   url: "https://filmix.my/film/for_adults/"),
        FilmixGenre(title: "Документальные", url: "https://filmix.my/film/dokumentalenyj/"),
        FilmixGenre(title: "Драмы",          url: "https://filmix.my/film/drama/"),
        FilmixGenre(title: "Исторический",   url: "https://filmix.my/film/istoricheskie/"),
        FilmixGenre(title: "Комедии",        url: "https://filmix.my/film/komedia/"),
        FilmixGenre(title: "Короткометражка",url: "https://filmix.my/film/korotkometragka/"),
        FilmixGenre(title: "Криминал",       url: "https://filmix.my/film/kriminaly/"),
        FilmixGenre(title: "Мелодрамы",      url: "https://filmix.my/film/melodrama/"),
        FilmixGenre(title: "Мистика",        url: "https://filmix.my/film/mistika/"),
        FilmixGenre(title: "Музыка",         url: "https://filmix.my/film/music/"),
        FilmixGenre(title: "Мюзикл",         url: "https://filmix.my/film/muzkl/"),
        FilmixGenre(title: "Приключения",    url: "https://filmix.my/film/prikluchenija/"),
        FilmixGenre(title: "Семейный",       url: "https://filmix.my/film/semejnye/"),
        FilmixGenre(title: "Спорт",          url: "https://filmix.my/film/sports/"),
        FilmixGenre(title: "Триллеры",       url: "https://filmix.my/film/triller/"),
        FilmixGenre(title: "Ужасы",          url: "https://filmix.my/film/uzhasu/"),
        FilmixGenre(title: "Фантастика",     url: "https://filmix.my/film/fantastiks/"),
        FilmixGenre(title: "Фэнтези",        url: "https://filmix.my/film/fjuntezia/"),
    ]

    static let series: [FilmixGenre] = [
        FilmixGenre(title: "Аниме",          url: "https://filmix.my/seria/animes/s7/"),
        FilmixGenre(title: "Биография",      url: "https://filmix.my/seria/biografia/s7/"),
        FilmixGenre(title: "Боевики",        url: "https://filmix.my/seria/boevik/s7/"),
        FilmixGenre(title: "Вестерн",        url: "https://filmix.my/seria/vesterny/s7/"),
        FilmixGenre(title: "Военный",        url: "https://filmix.my/seria/voennyj/s7/"),
        FilmixGenre(title: "Детектив",       url: "https://filmix.my/seria/detektivy/s7/"),
        FilmixGenre(title: "Детский",        url: "https://filmix.my/seria/detskij/s7/"),
        FilmixGenre(title: "Для взрослых",   url: "https://filmix.my/seria/for_adults/s7/"),
        FilmixGenre(title: "Документальные", url: "https://filmix.my/seria/dokumentalenyj/s7/"),
        FilmixGenre(title: "Дорамы",         url: "https://filmix.my/seria/dorama/s7/"),
        FilmixGenre(title: "Драмы",          url: "https://filmix.my/seria/drama/s7/"),
        FilmixGenre(title: "Игра",           url: "https://filmix.my/seria/game/s7/"),
        FilmixGenre(title: "Исторический",   url: "https://filmix.my/seria/istoricheskie/s7/"),
        FilmixGenre(title: "Комедии",        url: "https://filmix.my/seria/komedia/s7/"),
        FilmixGenre(title: "Криминал",       url: "https://filmix.my/seria/kriminaly/s7/"),
        FilmixGenre(title: "Мелодрамы",      url: "https://filmix.my/seria/melodrama/s7/"),
        FilmixGenre(title: "Мистика",        url: "https://filmix.my/seria/mistika/s7/"),
        FilmixGenre(title: "Мюзикл",         url: "https://filmix.my/seria/muzkl/s7/"),
        FilmixGenre(title: "Приключения",    url: "https://filmix.my/seria/prikluchenija/s7/"),
        FilmixGenre(title: "Семейный",       url: "https://filmix.my/seria/semejnye/s7/"),
        FilmixGenre(title: "Ситком",         url: "https://filmix.my/seria/sitcom/s7/"),
        FilmixGenre(title: "Триллеры",       url: "https://filmix.my/seria/triller/s7/"),
        FilmixGenre(title: "Ужасы",          url: "https://filmix.my/seria/uzhasu/s7/"),
        FilmixGenre(title: "Фантастика",     url: "https://filmix.my/seria/fantastiks/s7/"),
        FilmixGenre(title: "Фэнтези",        url: "https://filmix.my/seria/fjuntezia/s7/"),
    ]

    static let cartoons: [FilmixGenre] = [
        FilmixGenre(title: "Аниме",          url: "https://filmix.my/mults/animes/s14/"),
        FilmixGenre(title: "Биография",      url: "https://filmix.my/mults/biografia/s14/"),
        FilmixGenre(title: "Боевики",        url: "https://filmix.my/mults/boevik/s14/"),
        FilmixGenre(title: "Вестерн",        url: "https://filmix.my/mults/vesterny/s14/"),
        FilmixGenre(title: "Военный",        url: "https://filmix.my/mults/voennyj/s14/"),
        FilmixGenre(title: "Детектив",       url: "https://filmix.my/mults/detektivy/s14/"),
        FilmixGenre(title: "Детский",        url: "https://filmix.my/mults/detskij/s14/"),
        FilmixGenre(title: "Для взрослых",   url: "https://filmix.my/mults/for_adults/s14/"),
        FilmixGenre(title: "Документальные", url: "https://filmix.my/mults/dokumentalenyj/s14/"),
        FilmixGenre(title: "Драмы",          url: "https://filmix.my/mults/drama/s14/"),
        FilmixGenre(title: "Исторический",   url: "https://filmix.my/mults/istoricheskie/s14/"),
        FilmixGenre(title: "Комедии",        url: "https://filmix.my/mults/komedia/s14/"),
        FilmixGenre(title: "Криминал",       url: "https://filmix.my/mults/kriminaly/s14/"),
        FilmixGenre(title: "Мелодрамы",      url: "https://filmix.my/mults/melodrama/s14/"),
        FilmixGenre(title: "Мистика",        url: "https://filmix.my/mults/mistika/s14/"),
        FilmixGenre(title: "Музыка",         url: "https://filmix.my/mults/music/s14/"),
        FilmixGenre(title: "Мюзикл",         url: "https://filmix.my/mults/muzkl/s14/"),
        FilmixGenre(title: "Приключения",    url: "https://filmix.my/mults/prikluchenija/s14/"),
        FilmixGenre(title: "Семейный",       url: "https://filmix.my/mults/semejnye/s14/"),
        FilmixGenre(title: "Спорт",          url: "https://filmix.my/mults/sports/s14/"),
        FilmixGenre(title: "Триллеры",       url: "https://filmix.my/mults/triller/s14/"),
        FilmixGenre(title: "Ужасы",          url: "https://filmix.my/mults/uzhasu/s14/"),
        FilmixGenre(title: "Фантастика",     url: "https://filmix.my/mults/fantastiks/s14/"),
        FilmixGenre(title: "Фэнтези",        url: "https://filmix.my/mults/fjuntezia/s14/"),
    ]
}
