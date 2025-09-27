struct YoutubeVideo {
    let title: String
    let channel: String
    let views: String
    let dateAdded: String
    let thumbnailName: String
}

struct YoutubeStory {
    let title: String
    let thumbnailName: String
    let isNew: Bool
}

enum YoutubeSectionType {
    case video(title: String, videos: [YoutubeVideo])
    case stories(stories: [YoutubeStory])
}

let youtubeData: [YoutubeSectionType] = [
    .stories(stories: [
        YoutubeStory(title: "Новая история", thumbnailName: "2325447", isNew: true),
        YoutubeStory(title: "Обновление", thumbnailName: "2325447", isNew: false),
        YoutubeStory(title: "Прямой эфир", thumbnailName: "2325447", isNew: true),
        YoutubeStory(title: "Мой канал", thumbnailName: "2325447", isNew: false)
    ]),
    .video(title: "Рекомендованные", videos: [
        YoutubeVideo(title: "Новый iPhone 16", channel: "Apple Tech", views: "1.2M", dateAdded: "2 дня назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Обзор Galaxy Z Fold", channel: "Samsung Fan", views: "800K", dateAdded: "неделю назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Лучшие игры 2024", channel: "GameHub", views: "500K", dateAdded: "2 недели назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Прогулка по Токио", channel: "TravelVlog", views: "150K", dateAdded: "3 дня назад", thumbnailName: "2325447")
    ]),
    .video(title: "Недавно просмотренные", videos: [
        YoutubeVideo(title: "Лучшие игры 2024", channel: "GameHub", views: "500K", dateAdded: "2 недели назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Рецепт пиццы", channel: "Foodie Channel", views: "300K", dateAdded: "5 дней назад", thumbnailName: "2325447"),
    ]),
    .video(title: "Недавно просмотренные", videos: [
        YoutubeVideo(title: "Лучшие игры 2024", channel: "GameHub", views: "500K", dateAdded: "2 недели назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Рецепт пиццы", channel: "Foodie Channel", views: "300K", dateAdded: "5 дней назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Новый iPhone 16", channel: "Apple Tech", views: "1.2M", dateAdded: "2 дня назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Обзор Galaxy Z Fold", channel: "Samsung Fan", views: "800K", dateAdded: "неделю назад", thumbnailName: "2325447"),
        YoutubeVideo(title: "Что нового в iOS 18", channel: "WWDC", views: "2.5M", dateAdded: "1 месяц назад", thumbnailName: "2325447")
    ])
]
