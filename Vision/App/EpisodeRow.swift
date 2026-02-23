import UIKit

final class EpisodeRow: UIView {

    var onPlay: (() -> Void)?
    var onWatchToggle: (() -> Void)?

    private let accentColor: UIColor
    private var watched: Bool
    private var progressFraction: Double?

    private lazy var mainControl: EpisodeMainControl = {
        let c = EpisodeMainControl(
            index: index, folder: folder,
            accentColor: accentColor, isWatched: watched
        )
        c.onPlay = { [weak self] in self?.onPlay?() }
        return c
    }()

    private lazy var watchedControl: EpisodeWatchedControl = {
        let c = EpisodeWatchedControl(isWatched: watched)
        c.onToggle = { [weak self] in self?.onWatchToggle?() }
        return c
    }()

    // Тонкий progress bar внизу строки (голубой)
    private let progressBar = PlaybackProgressBar()

    private let index: Int
    private let folder: _FilmixPlayerFolder

    init(index: Int, folder: _FilmixPlayerFolder, accentColor: UIColor,
         isWatched: Bool, progressFraction: Double? = nil) {
        self.index            = index
        self.folder           = folder
        self.accentColor      = accentColor
        self.watched          = isWatched
        self.progressFraction = progressFraction
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 76).isActive = true   // +4 для progress bar

        addSubview(mainControl)
        addSubview(watchedControl)
        addSubview(progressBar)

        NSLayoutConstraint.activate([
            mainControl.topAnchor.constraint(equalTo: topAnchor),
            mainControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainControl.bottomAnchor.constraint(equalTo: progressBar.topAnchor),
            mainControl.trailingAnchor.constraint(equalTo: watchedControl.leadingAnchor, constant: -8),

            watchedControl.topAnchor.constraint(equalTo: topAnchor),
            watchedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            watchedControl.bottomAnchor.constraint(equalTo: progressBar.topAnchor),
            watchedControl.widthAnchor.constraint(equalToConstant: 56),

            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            progressBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])

        progressBar.setFraction(progressFraction)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setWatched(_ w: Bool) {
        watched = w
        mainControl.setWatched(w)
        watchedControl.setWatched(w)
        // Если стало просмотренным — скрываем progress bar
        if w { progressBar.setFraction(nil) }
    }

    func setProgressFraction(_ fraction: Double?) {
        progressFraction = fraction
        progressBar.setFraction(watched ? nil : fraction)
    }
}
