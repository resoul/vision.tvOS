struct SettingsData {
    var isAutoplayEnabled: Bool
    var preferredQuality: VideoQuality
    var cacheSizeStep: Int
}

enum VideoQuality: String, CaseIterable {
    case auto      = "Авто"
    case uhd       = "4K UHD"
    case fullHDPlus = "1080p Ultra+"
    case fullHD    = "1080p"
    case hd        = "720p"
    case qhd       = "480p"
}

