import UIKit
import AVKit

final class PlaybackViewController: UIViewController {

    // MARK: - Callbacks

    /// Вызывается когда нужно перейти к следующему эпизоду (0-based индексы).
    /// Используется только для обновления UI в SerieDetailViewController,
    /// сам переход уже совершён AVQueuePlayer'ом.
    var onRequestNextEpisode: ((Int, Int) -> Void)?

    /// Вызывается когда озвучка закончилась (следующего эпизода нет ни в одной озвучке)
    var onTranslationEnded: (() -> Void)?

    /// Провайдер актуального translation — нужен для подгрузки следующего-следующего item
    var translationProvider: (() -> FilmixTranslation?)?

    // MARK: - Private

    private let context: PlaybackContext
    private var currentContext: PlaybackContext

    private let playerVC = AVPlayerViewController()
    private var queuePlayer: AVQueuePlayer?
    private var currentItem: AVPlayerItem?

    private var periodicObserver: Any?
    private var itemEndedObserver: NSObjectProtocol?
    private var currentItemToken: NSKeyValueObservation?
    private var audioTrackObserver: NSKeyValueObservation?

    private var overlay: NextEpisodeOverlay?
    private var overlayShown = false
    private var didHandleAudioTracks = false
    private var resumePosition: Double

    // MARK: - Init

    init(context: PlaybackContext, resumePosition: Double = 0) {
        self.context        = context
        self.currentContext = context
        self.resumePosition = resumePosition
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupQueuePlayer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveProgress()
        tearDownObservers()
    }

    // MARK: - Setup

    private func setupQueuePlayer() {
        guard let currentURL = URL(string: context.streamURL) else { return }

        var items: [AVPlayerItem] = []
        let firstItem = AVPlayerItem(url: currentURL)
        items.append(firstItem)
        currentItem = firstItem

        // Сразу кладём следующий item в очередь — AVQueuePlayer начнёт буферизацию заранее
        if let next = context.nextItem,
           let stream = next.streamURL(preferredQuality: SeriesPickerStore.shared.globalPreferredQuality),
           let nextURL = URL(string: stream.url) {
            items.append(AVPlayerItem(url: nextURL))
        }

        let player = AVQueuePlayer(items: items)
        queuePlayer = player

        playerVC.player = player
        playerVC.title  = context.displayTitle

        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.view.frame = view.bounds
        playerVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playerVC.didMove(toParent: self)

        if resumePosition > 5 {
            player.seek(
                to: CMTime(seconds: resumePosition, preferredTimescale: 600),
                toleranceBefore: .zero, toleranceAfter: .zero
            )
        }

        player.play()
        setupPeriodicObserver(player: player)
        subscribeToItemEnd(item: firstItem)
        subscribeToCurrentItemChange(player: player)
        observeAudioTracks(item: firstItem)
    }

    // MARK: - Observers

    private func setupPeriodicObserver(player: AVQueuePlayer) {
        let interval = CMTime(seconds: 5, preferredTimescale: 600)
        periodicObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.onTick()
        }
    }

    private func subscribeToItemEnd(item: AVPlayerItem) {
        if let old = itemEndedObserver { NotificationCenter.default.removeObserver(old) }
        itemEndedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.saveProgress()
        }
    }

    private func subscribeToCurrentItemChange(player: AVQueuePlayer) {
        currentItemToken = player.observe(\.currentItem, options: [.old, .new]) { [weak self] _, change in
            guard change.oldValue != change.newValue else { return }
            DispatchQueue.main.async { self?.handleCurrentItemChanged() }
        }
    }

    private func tearDownObservers() {
        if let obs = periodicObserver { queuePlayer?.removeTimeObserver(obs); periodicObserver = nil }
        if let obs = itemEndedObserver { NotificationCenter.default.removeObserver(obs); itemEndedObserver = nil }
        currentItemToken?.invalidate(); currentItemToken = nil
        audioTrackObserver?.invalidate(); audioTrackObserver = nil
    }

    // MARK: - Item Changed

    private func handleCurrentItemChanged() {
        guard let player = queuePlayer,
              let newItem = player.currentItem,
              newItem !== currentItem
        else { return }

        saveProgress() // сохраняем прогресс предыдущего

        // Сдвигаем контекст
        guard let nextCtx = currentContext.advancedContext() else { return }
        currentContext = nextCtx
        currentItem    = newItem

        // Обновляем плеер
        playerVC.title = nextCtx.displayTitle
        overlayShown   = false

        // Подписываемся на конец нового item
        subscribeToItemEnd(item: newItem)

        // Уведомляем SerieDetailViewController чтобы он обновил UI (подсветку эпизода и т.п.)
        if case let .episode(_, _, _, _, _, _, _, nextItem) = nextCtx, let next = nextItem {
            onRequestNextEpisode?(next.seasonIndex, next.episodeIndex)
            // Сразу подгружаем следующий-следующий эпизод в очередь
            enqueueItemAfter(next)
        }

        // Resume position из CoreData если есть
        if case let .episode(movieId, season, episode, _, _, _, _, _) = nextCtx {
            let saved = PlaybackStore.shared
                .episodeProgress(movieId: movieId, season: season, episode: episode)?
                .positionSeconds ?? 0
            if saved > 5 {
                player.seek(
                    to: CMTime(seconds: saved, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero
                )
            }
        }

        // Аудиодорожки для нового item
        didHandleAudioTracks = false
        observeAudioTracks(item: newItem)
    }

    /// Подгружает item через один от текущего — чтобы буферизация шла на два эпизода вперёд
    private func enqueueItemAfter(_ nextItem: NextEpisodeItem) {
        guard let translation = translationProvider?() else { return }

        let availability = TranslationReachabilityChecker.nextEpisode(
            in: translation,
            seasonIndex: nextItem.seasonIndex,
            episodeIndex: nextItem.episodeIndex,
            allTranslations: []
        )

        guard case let .available(_, _, folder) = availability else { return }

        let probe = NextEpisodeItem(
            seasonIndex:  nextItem.seasonIndex,
            episodeIndex: nextItem.episodeIndex,
            folder:       folder,
            studio:       nextItem.studio,
            quality:      nextItem.quality
        )

        guard let stream = probe.streamURL(preferredQuality: SeriesPickerStore.shared.globalPreferredQuality),
              let url = URL(string: stream.url) else { return }

        queuePlayer?.insert(AVPlayerItem(url: url), after: nil)
    }

    // MARK: - Tick

    private func onTick() {
        let position = currentPosition
        let duration = currentDuration
        guard duration > 0 else { return }

        saveProgressValues(position: position, duration: duration)

        guard case .episode = currentContext else { return }
        guard position / duration >= 0.95, !overlayShown else { return }
        overlayShown = true
        showNextEpisodeOverlay()
    }

    // MARK: - Overlay

    private func showNextEpisodeOverlay() {
        guard case let .episode(_, _, _, _, _, _, _, nextItem) = currentContext else { return }

        guard let next = nextItem else {
            // Озвучка закончилась — уходим и показываем попап в SerieDetailViewController
            dismiss(animated: true) { [weak self] in self?.onTranslationEnded?() }
            return
        }

        let ol = NextEpisodeOverlay(nextTitle: next.title, countdown: 10)
        overlay = ol

        ol.onNext = { [weak self] in
            self?.overlay = nil
            self?.queuePlayer?.advanceToNextItem()
        }

        ol.onDismiss = { [weak self] in
            self?.overlay = nil
        }

        ol.show(in: playerVC.view, focusedIn: self)
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    // MARK: - Progress

    private func saveProgress() {
        let d = currentDuration
        guard d > 0 else { return }
        saveProgressValues(position: currentPosition, duration: d)
    }

    private func saveProgressValues(position: Double, duration: Double) {
        switch currentContext {
        case let .movie(movieId, studio, quality, streamURL):
            PlaybackStore.shared.saveMovieProgress(
                movieId: movieId, position: position, duration: duration,
                studio: studio, quality: quality, streamURL: streamURL
            )
        case let .episode(movieId, season, episode, _, _, _, _, _):
            PlaybackStore.shared.saveEpisodeProgress(
                movieId: movieId, season: season, episode: episode,
                position: position, duration: duration
            )
        }
    }

    // MARK: - Audio Tracks

    private func observeAudioTracks(item: AVPlayerItem) {
        audioTrackObserver?.invalidate()
        didHandleAudioTracks = false

        audioTrackObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self, !self.didHandleAudioTracks, item.status == .readyToPlay else { return }
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
            if languageCode(of: options[0]) != "ru" { item.select(options[1], in: group) }
        } else {
            showAudioTrackPicker(options: options, group: group, item: item)
        }
    }

    private func languageCode(of option: AVMediaSelectionOption) -> String? {
        if #available(tvOS 16, *) { return option.locale?.language.languageCode?.identifier }
        else { return option.locale?.languageCode }
    }

    private func showAudioTrackPicker(options: [AVMediaSelectionOption],
                                       group: AVMediaSelectionGroup, item: AVPlayerItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "Аудиодорожка", message: nil, preferredStyle: .actionSheet)
            options.forEach { opt in
                alert.addAction(UIAlertAction(title: opt.displayName, style: .default) { _ in
                    item.select(opt, in: group)
                })
            }
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    // MARK: - Focus

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        // Когда оверлей видим — направляем фокус в него
        if let ol = overlay, ol.superview != nil {
            return [ol.nextButton]
        }
        return super.preferredFocusEnvironments
    }

    // MARK: - Helpers

    private var currentPosition: Double {
        guard let t = queuePlayer?.currentTime(), t.isValid, t.isNumeric else { return 0 }
        return max(0, CMTimeGetSeconds(t))
    }

    private var currentDuration: Double {
        guard let d = queuePlayer?.currentItem?.duration, d.isValid, d.isNumeric else { return 0 }
        return max(0, CMTimeGetSeconds(d))
    }
}
