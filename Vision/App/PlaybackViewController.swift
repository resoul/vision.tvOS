import UIKit
import AVKit

enum PlaybackContext {
    case movie(movieId: Int, studio: String, quality: String, streamURL: String)
    case episode(movieId: Int, season: Int, episode: Int,
                 studio: String, quality: String, streamURL: String,
                 title: String)
}

final class PlaybackViewController: UIViewController {

    var onRequestNextEpisode: (() -> Void)?

    private let context: PlaybackContext
    private let playerVC = AVPlayerViewController()
    private var player: AVPlayer?
    private var periodicObserver: Any?
    private var overlay: NextEpisodeOverlay?
    private var overlayShown = false
    private var saveTimer: Timer?
    private var resumePosition: Double = 0
    private var audioTrackObserver: NSKeyValueObservation?
    private var didHandleAudioTracks = false

    init(context: PlaybackContext, resumePosition: Double = 0) {
        self.context        = context
        self.resumePosition = resumePosition
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveProgress(final: true)
        tearDownObservers()
    }

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

        if resumePosition > 5 {
            let time = CMTime(seconds: resumePosition, preferredTimescale: 600)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }

        player.play()
        setupObservers(player: player)
        observeAudioTracks(item: item)
    }

    private func observeAudioTracks(item: AVPlayerItem) {
        audioTrackObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self, !self.didHandleAudioTracks else { return }
            guard item.status == .readyToPlay else { return }
            self.didHandleAudioTracks = true
            DispatchQueue.main.async { self.handleAudioTracks(item: item) }
        }
    }

    private func handleAudioTracks(item: AVPlayerItem) {
        Task {
            guard let group = try? await item.asset.loadMediaSelectionGroup(for: .audible) else { return }
            await MainActor.run { self.applyAudioTrackSelection(item: item, group: group) }
        }
    }

    private func applyAudioTrackSelection(item: AVPlayerItem, group: AVMediaSelectionGroup) {
        let options = group.options
        guard options.count >= 2 else { return }

        if options.count == 2 {
            let isFirstRussian = languageCode(of: options[0]) == "ru"
            if !isFirstRussian {
                item.select(options[1], in: group)
            }
        } else {
            showAudioTrackPicker(options: options, group: group, item: item)
        }
    }

    private func languageCode(of option: AVMediaSelectionOption) -> String? {
        if #available(tvOS 16, *) {
            return option.locale?.language.languageCode?.identifier
        } else {
            return option.locale?.languageCode
        }
    }

    private func showAudioTrackPicker(options: [AVMediaSelectionOption],
                                      group: AVMediaSelectionGroup,
                                      item: AVPlayerItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            let alert = UIAlertController(
                title: "Аудиодорожка",
                message: "Выберите язык или дорожку",
                preferredStyle: .actionSheet
            )

            for option in options {
                alert.addAction(UIAlertAction(title: option.displayName, style: .default) { _ in
                    item.select(option, in: group)
                })
            }

            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    private func setupObservers(player: AVPlayer) {
        let interval = CMTime(seconds: 5, preferredTimescale: 600)
        periodicObserver = player.addPeriodicTimeObserver(forInterval: interval,
                                                          queue: .main) { [weak self] _ in
            self?.onTick()
        }

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
        audioTrackObserver?.invalidate()
        audioTrackObserver = nil
        NotificationCenter.default.removeObserver(self)
    }

    private func onTick() {
        let position = currentPosition
        let duration = currentDuration
        guard duration > 0 else { return }

        saveProgressValues(position: position, duration: duration)

        let fraction = position / duration

        if case .episode = context, fraction >= 0.95, fraction < 1.0, !overlayShown {
            overlayShown = true
            showNextEpisodeOverlay()
        }
    }
    
    @objc private func playerDidFinish() {
        saveProgress(final: true)
        overlay?.hide(animated: false)
    }

    private func saveProgress(final: Bool) {
        let duration = currentDuration
        guard duration > 0 else { return }
        saveProgressValues(position: currentPosition, duration: duration)
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

    private func showNextEpisodeOverlay() {
        guard case let .episode(_, _, _, _, _, _, title) = context else { return }

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
        if let match = currentTitle.firstMatch(of: #/E(\d+)/#),
           let n = Int(match.output.1) {
            return "Эпизод \(n + 1)"
        }
        return "Следующий эпизод"
    }

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
        case let .movie(_, _, _, url):             return url
        case let .episode(_, _, _, _, _, url, _):  return url
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
