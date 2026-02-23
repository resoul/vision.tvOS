import UIKit
import AVKit

// MARK: - PlaybackContext

enum PlaybackContext {
    case movie(movieId: Int, studio: String, quality: String, streamURL: String)
    case episode(movieId: Int, season: Int, episode: Int,
                 studio: String, quality: String, streamURL: String,
                 title: String)
}

// MARK: - PlaybackViewController

final class PlaybackViewController: UIViewController {

    /// Called when an episode ends / 95 %+ reached — series only
    var onRequestNextEpisode: (() -> Void)?

    private let context: PlaybackContext
    private let playerVC = AVPlayerViewController()
    private var player: AVPlayer?
    private var periodicObserver: Any?
    private var overlay: NextEpisodeOverlay?
    private var overlayShown = false
    private var saveTimer: Timer?

    // Resume position injected before playback starts
    private var resumePosition: Double = 0

    init(context: PlaybackContext, resumePosition: Double = 0) {
        self.context        = context
        self.resumePosition = resumePosition
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveProgress(final: true)
        tearDownObservers()
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        guard let url = URL(string: streamURL) else { return }

        let item   = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player

        playerVC.player = player
        playerVC.title  = displayTitle

        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.view.frame = view.bounds
        playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerVC.didMove(toParent: self)

        // Resume position
        if resumePosition > 5 {
            let time = CMTime(seconds: resumePosition, preferredTimescale: 600)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        player.play()
        setupObservers(player: player)
    }

    // MARK: - Observers

    private func setupObservers(player: AVPlayer) {
        // Периодически сохраняем каждые 5 сек
        let interval = CMTime(seconds: 5, preferredTimescale: 600)
        periodicObserver = player.addPeriodicTimeObserver(forInterval: interval,
                                                          queue: .main) { [weak self] _ in
            self?.onTick()
        }

        // End of item
        NotificationCenter.default.addObserver(self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem)
    }

    private func tearDownObservers() {
        if let obs = periodicObserver {
            player?.removeTimeObserver(obs)
            periodicObserver = nil
        }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Tick (every 5 sec)

    private func onTick() {
        let position = currentPosition
        let duration = currentDuration
        guard duration > 0 else { return }

        saveProgressValues(position: position, duration: duration)

        let fraction = position / duration

        // Показать overlay при 95–99 % (только для серий, один раз)
        if case .episode = context, fraction >= 0.95, fraction < 1.0, !overlayShown {
            overlayShown = true
            showNextEpisodeOverlay()
        }
    }

    // MARK: - Finish

    @objc private func playerDidFinish() {
        saveProgress(final: true)
        overlay?.hide(animated: false)
    }

    // MARK: - Progress Save

    private func saveProgress(final: Bool) {
        let position = final ? currentPosition : currentPosition
        let duration = currentDuration
        guard duration > 0 else { return }
        saveProgressValues(position: position, duration: duration)
    }

    private func saveProgressValues(position: Double, duration: Double) {
        switch context {
        case let .movie(movieId, studio, quality, streamURL):
            PlaybackStore.shared.saveMovieProgress(
                movieId: movieId,
                position: position, duration: duration,
                studio: studio, quality: quality, streamURL: streamURL
            )
        case let .episode(movieId, season, episode, _, _, _, _):
            PlaybackStore.shared.saveEpisodeProgress(
                movieId: movieId, season: season, episode: episode,
                position: position, duration: duration
            )
        }
    }

    // MARK: - Next Episode Overlay

    private func showNextEpisodeOverlay() {
        guard case let .episode(_, _, _, _, _, _, title) = context else { return }

        // Try to derive "Episode N+1" for the title hint
        let nextTitle = nextEpisodeTitle(currentTitle: title)

        let ol = NextEpisodeOverlay(nextTitle: nextTitle, countdown: 10)
        ol.onNext = { [weak self] in
            self?.saveProgress(final: true)
            self?.dismiss(animated: false) {
                self?.onRequestNextEpisode?()
            }
        }
        ol.onDismiss = { /* user skipped — do nothing */ }
        overlay = ol
        ol.show(in: playerVC.view)
    }

    private func nextEpisodeTitle(currentTitle: String) -> String {
        // Попытка вычленить номер из "E3 · Название" → "E4"
        if let match = currentTitle.firstMatch(of: #/E(\d+)/#),
           let n = Int(match.output.1) {
            return "Эпизод \(n + 1)"
        }
        return "Следующий эпизод"
    }

    // MARK: - Helpers

    private var currentPosition: Double {
        guard let time = player?.currentTime(), time.isValid, time.isNumeric else { return 0 }
        return max(0, CMTimeGetSeconds(time))
    }

    private var currentDuration: Double {
        guard let duration = player?.currentItem?.duration,
              duration.isValid, duration.isNumeric else { return 0 }
        return max(0, CMTimeGetSeconds(duration))
    }

    private var streamURL: String {
        switch context {
        case let .movie(_, _, _, url):    return url
        case let .episode(_, _, _, _, _, url, _): return url
        }
    }

    private var displayTitle: String {
        switch context {
        case let .movie(_, studio, quality, _):
            return "\(studio) · \(quality)"
        case let .episode(_, _, _, studio, quality, _, title):
            return "\(title) · \(studio) · \(quality)"
        }
    }
}
