
struct PlaybackProgress {
    let positionSeconds: Double
    let durationSeconds: Double
    let studio:    String?
    let quality:   String?
    let streamURL: String?

    var fraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(positionSeconds / durationSeconds, 1.0)
    }

    var isCompleted: Bool { fraction >= 0.88 }
    var shouldSuggestNext: Bool { fraction >= 0.95 && fraction < 1.0 }
    var hasProgress: Bool { positionSeconds > 5 && !isCompleted }
}
