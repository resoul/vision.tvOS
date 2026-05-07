import UIKit
import AVFoundation
import Combine

@MainActor
final class VideoPlayerViewController: BaseViewController {
    private enum SeekState {
        case idle
        case previewing(startTime: Double, targetTime: Double)
    }
    
    private let viewModel: PlayerViewModel
    private let playerView = QueueVideoPlayerLayerView()
    private let overlayView = PlayerOverlayView()
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let playerEngine = QueueVideoPlayerEngine()
    private var hideOverlayTask: Task<Void, Never>?
    private var seekState: SeekState = .idle
    private var seekHoldCount = 0

    init(viewModel: PlayerViewModel, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.viewModel = viewModel
        super.init(themeManager: themeManager, languageManager: languageManager)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindViewModel()
        bindOverlay()
        bindPlayerEngine()

        Task {
            await viewModel.loadCurrent()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideOverlayTask?.cancel()
        hideOverlayTask = nil
        playerEngine.player.pause()
        Task { await viewModel.saveState() }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        bumpOverlayAutoHideTimerOnInteraction()

        if presses.contains(where: { $0.type == .upArrow }) {
            handleUpArrow()
            return
        }

        if presses.contains(where: { $0.type == .downArrow }) {
            handleDownArrow()
            return
        }

        if presses.contains(where: { $0.type == .menu }) {
            handleMenuPress()
            return
        }

        if presses.contains(where: { $0.type == .playPause }) {
            handlePlayPausePress()
            return
        }

        if presses.contains(where: { $0.type == .select }) {
            handleSelectPress()
            return
        }

        if presses.contains(where: { $0.type == .leftArrow }) {
            handleLeftArrow()
            return
        }

        if presses.contains(where: { $0.type == .rightArrow }) {
            handleRightArrow()
            return
        }

        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .leftArrow || $0.type == .rightArrow }) {
            seekHoldCount = 0
        }
        super.pressesEnded(presses, with: event)
    }

    // MARK: - Individual press handlers

    private func handleUpArrow() {
        if overlayView.isVisible && viewModel.isSeries {
            overlayView.setDisplayMode(.episodeBrowse)
        } else {
            showOverlayTemporarily()
        }
    }

    private func handleDownArrow() {
        if overlayView.currentDisplayMode == .episodeBrowse {
            overlayView.setDisplayMode(.full)
            showOverlayTemporarily()
        }
    }

    private func handleMenuPress() {
        if overlayView.currentDisplayMode == .episodeBrowse {
            overlayView.setDisplayMode(.full)
            showOverlayTemporarily()
            return
        }
        if isSeekPreviewActive {
            cancelSeekPreview()
            return
        }
        dismiss(animated: true)
    }

    private func handlePlayPausePress() {
        if isSeekPreviewActive {
            confirmSeekPreview()
            return
        }
        playerEngine.togglePlayPause()
    }

    private func handleSelectPress() {
        if isSeekPreviewActive {
            confirmSeekPreview()
            return
        }
        overlayView.setDisplayMode(.full)
        showOverlayTemporarily()
    }

    private func handleLeftArrow() {
        if overlayView.currentDisplayMode == .episodeBrowse { return }
        beginSeekPreviewIfNeeded()
        seekHoldCount += 1
        stepSeekPreview(delta: -seekStepSeconds())
    }

    private func handleRightArrow() {
        if overlayView.currentDisplayMode == .episodeBrowse { return }
        beginSeekPreviewIfNeeded()
        seekHoldCount += 1
        stepSeekPreview(delta: seekStepSeconds())
    }
    
    private func seekStepSeconds() -> Double {
        switch seekHoldCount {
        case 1...3:  return 10
        case 4...8:  return 30
        default:     return 60
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        playerView.player = playerEngine.player
        loadingView.hidesWhenStopped = true
        
        view.addSubviews(playerView, overlayView, loadingView)
        playerView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        overlayView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        loadingView.constraintToCenter(in: view)
    }
    
    private func bindViewModel() {
        viewModel.$currentContext
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.handleNewContext(context)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingView.startAnimating()
                } else {
                    self?.loadingView.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$resumePromptTime
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.playerEngine.player.pause()
                self?.showResumePrompt(at: time)
            }
            .store(in: &cancellables)

        viewModel.$seekCommand
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] command in
                guard let self else { return }
                switch command {
                case .absolute(let time):
                    self.playerEngine.seek(seconds: time)
                case .restart:
                    self.playerEngine.seek(seconds: 0)
                }
                self.viewModel.clearSeekCommand()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.playerEngine.player.pause()
                Task { await self.viewModel.saveState() }
            }
            .store(in: &cancellables)

        viewModel.$shouldDismiss
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }
    
    private func showResumePrompt(at time: Double) {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        let timeString = formatter.string(from: time) ?? "0:00"

        let alert = UIAlertController(
            title: L10n.Player.Resume.title,
            message: L10n.Player.Resume.message(timeString),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: L10n.Player.Resume.continue, style: .default) { [weak self] _ in
            self?.viewModel.resume()
            self?.playerEngine.player.play()
        })

        alert.addAction(UIAlertAction(title: L10n.Player.Resume.restart, style: .destructive) { [weak self] _ in
            self?.viewModel.restart()
            self?.playerEngine.player.play()
        })

        present(alert, animated: true)
    }
    
    private func handleNewContext(_ context: PlaybackContext) {
        guard let url = URL(string: context.streamURL) else { return }

        if viewModel.isAwaitingResumeDecision {
            playerEngine.prepare(url: url)
        } else {
            playerEngine.play(url: url)
            if let resumeTime = viewModel.consumeAutoResumeTime() {
                playerEngine.seek(seconds: resumeTime)
            }
        }

        let info = VideoQueueItem(
            id: context.movieId,
            title: title(for: context),
            subtitle: subtitle(for: context),
            viewsText: "",
            addedText: "",
            posterURL: ""
        )
        overlayView.updateInfo(item: info)
        Task { [weak self] in
            guard let self else { return }
            let items = await self.viewModel.buildEpisodeBrowseItems()
            await MainActor.run {
                self.overlayView.configureEpisodeBrowse(
                    items: items,
                    currentSeason: self.viewModel.currentSeasonIndex,
                    currentEpisode: self.viewModel.currentEpisodeIndex,
                    isSeries: self.viewModel.isSeries
                )
                self.showOverlayTemporarily()
            }
        }
    }

    private func title(for context: PlaybackContext) -> String {
        switch context {
        case .movie(_, _, _, _, let title): return title
        case .episode(_, let s, let e, _, _, _, let title):
            return "\(String(format: L10n.Player.seasonEpisodeFormat, s, e)) · \(title)"
        }
    }

    private func subtitle(for context: PlaybackContext) -> String {
        switch context {
        case .movie(_, let s, let q, _, _): return "\(s) · \(q)"
        case .episode(_, _, _, let s, let q, _, _): return "\(s) · \(q)"
        }
    }
    
    private func bindOverlay() {
        overlayView.onAction = { [weak self] action in
            guard let self else { return }
            self.showOverlayTemporarily()
            switch action {
            case .previous:
                Task { await self.viewModel.playPrevious() }
            case .rewind:
                self.playerEngine.seekBy(delta: -15)
            case .playPause:
                self.playerEngine.togglePlayPause()
            case .forward:
                self.playerEngine.seekBy(delta: 15)
            case .next:
                Task { await self.viewModel.playNext() }
            case .audioTrack:
                self.showSettingsMenu()
            default:
                break
            }
        }

        overlayView.onSliderChanged = { [weak self] ratio in
            guard let self else { return }
            let duration = self.playerEngine.player.currentItem?.duration.seconds ?? 0
            guard duration.isFinite, duration > 0 else { return }
            let targetTime = duration * ratio
            if case .previewing(let startTime, _) = self.seekState {
                self.seekState = .previewing(startTime: startTime, targetTime: targetTime)
                self.playerEngine.seek(seconds: targetTime)
                self.showSeekPreviewOverlay()
                return
            }
            self.overlayView.setDisplayMode(.full)
            self.showOverlayTemporarily()
            self.playerEngine.seek(seconds: targetTime)
        }

        overlayView.onEpisodeSelected = { [weak self] season, episode in
            Task { await self?.viewModel.changeEpisode(season: season, episode: episode) }
        }

        overlayView.onBrowseIdleTimeout = { [weak self] in
            self?.showOverlayTemporarily()
        }
    }
    
    private func bindPlayerEngine() {
        playerEngine.onPlaybackStateChanged = { [weak self] isPlaying in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.overlayView.updatePlayPause(isPlaying: isPlaying)
                self.viewModel.isPlaying = isPlaying
                if isPlaying {
                    self.showOverlayTemporarily()
                } else {
                    self.showOverlayPersistent()
                }
            }
        }

        playerEngine.onTimeUpdate = { [weak self] current, duration in
            self?.overlayView.updateTimes(current: current, duration: duration)
            self?.viewModel.updateProgress(currentTime: current, duration: duration)
        }

        playerEngine.onPlaybackFinished = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.viewModel.playNext()
            }
        }
    }
    
    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        overlayView.applyStyle(style)
    }
    
    private func showOverlayTemporarily(focusScrubber: Bool = false) {
        overlayView.setDisplayMode(.full)
        scheduleOverlayAutoHide()

        if overlayView.isHidden {
            overlayView.isHidden = false
            UIView.animate(withDuration: 0.22) {
                self.overlayView.alpha = 1
            }
        }

        if focusScrubber {
            overlayView.focusScrubber()
        } else {
            overlayView.focusPrimaryControls()
        }
    }
    
    private func showOverlayPersistent() {
        hideOverlayTask?.cancel()
        hideOverlayTask = nil

        overlayView.setDisplayMode(.full)
        overlayView.isHidden = false
        UIView.animate(withDuration: 0.22) {
            self.overlayView.alpha = 1
        }
        overlayView.focusPrimaryControls()
    }

    private func scheduleOverlayAutoHide() {
        hideOverlayTask?.cancel()

        hideOverlayTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.overlayView.currentDisplayMode == .full else { return }
                guard self.viewModel.isPlaying else { return }
                UIView.animate(withDuration: 0.25, animations: {
                    self.overlayView.alpha = 0
                }, completion: { _ in
                    self.overlayView.isHidden = true
                })
            }
        }
    }

    private func bumpOverlayAutoHideTimerOnInteraction() {
        guard overlayView.isVisible else { return }
        guard overlayView.currentDisplayMode == .full else { return }
        guard !isSeekPreviewActive else { return }
        guard viewModel.isPlaying else { return }
        scheduleOverlayAutoHide()
    }
    
    private func beginSeekPreviewIfNeeded() {
        guard case .idle = seekState else { return }
        let start = currentPlaybackTime()
        seekState = .previewing(startTime: start, targetTime: start)
        viewModel.setSeekPreviewPersistenceEnabled(false)
        playerEngine.player.pause()
        showSeekPreviewOverlay()
    }

    private func stepSeekPreview(delta: Double) {
        guard case .previewing(let startTime, let targetTime) = seekState else { return }
        let maxTime = playbackDuration()
        guard maxTime > 0 else { return }
        let next = min(max(targetTime + delta, 0), maxTime)
        seekState = .previewing(startTime: startTime, targetTime: next)
        playerEngine.seek(seconds: next)
        showSeekPreviewOverlay()
    }

    private func confirmSeekPreview() {
        guard case .previewing(_, let targetTime) = seekState else { return }
        playerEngine.seek(seconds: targetTime)
        playerEngine.player.play()
        endSeekPreview()
    }

    private func cancelSeekPreview() {
        guard case .previewing(let startTime, _) = seekState else { return }
        playerEngine.seek(seconds: startTime)
        playerEngine.player.play()
        endSeekPreview()
    }

    private func endSeekPreview() {
        seekState = .idle
        seekHoldCount = 0
        viewModel.setSeekPreviewPersistenceEnabled(true)
        overlayView.setDisplayMode(.full)
        showOverlayTemporarily()
    }

    private func showSeekPreviewOverlay() {
        hideOverlayTask?.cancel()
        overlayView.setDisplayMode(.scrubberOnly)
        if overlayView.isHidden {
            overlayView.isHidden = false
            UIView.animate(withDuration: 0.22) {
                self.overlayView.alpha = 1
            }
        }
        overlayView.focusScrubber()
    }

    private func showSettingsMenu() {
        let alert = UIAlertController(title: L10n.Player.audioTrack, message: nil, preferredStyle: .actionSheet)
        for translation in viewModel.translations {
            alert.addAction(UIAlertAction(title: translation.studio, style: .default) { [weak self] _ in
                Task { await self?.viewModel.changeTranslation(translation) }
            })
        }
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        present(alert, animated: true)
    }

    private func showEpisodesMenu() {
        guard let context = viewModel.currentContext,
              case .episode(_, let currentSeason, _, let studio, _, _, _) = context else { return }
        guard let translation = viewModel.translations.first(where: { $0.studio == studio }) else { return }

        let alert = UIAlertController(title: L10n.Player.episodes, message: nil, preferredStyle: .actionSheet)
        for (sIdx, season) in translation.seasons.enumerated() {
            let seasonNum = sIdx + 1
            let isCurrent = seasonNum == currentSeason
            let seasonTitle = "\(L10n.Detail.season) \(seasonNum) (\(season.episodes.count))"
            alert.addAction(UIAlertAction(title: isCurrent ? "● \(seasonTitle)" : seasonTitle, style: .default) { [weak self] _ in
                self?.showEpisodesForSeason(season, seasonNum: seasonNum)
            })
        }
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        present(alert, animated: true)
    }

    private func showEpisodesForSeason(_ season: Season, seasonNum: Int) {
        let alert = UIAlertController(title: "\(L10n.Detail.season) \(seasonNum)", message: nil, preferredStyle: .actionSheet)
        for (eIdx, episode) in season.episodes.enumerated() {
            let epNum = eIdx + 1
            alert.addAction(UIAlertAction(title: "\(epNum). \(episode.title)", style: .default) { [weak self] _ in
                Task { await self?.viewModel.changeEpisode(season: seasonNum, episode: epNum) }
            })
        }
        alert.addAction(UIAlertAction(title: L10n.Common.back, style: .cancel) { [weak self] _ in
            self?.showEpisodesMenu()
        })
        present(alert, animated: true)
    }
    
    private func currentPlaybackTime() -> Double {
        let s = playerEngine.player.currentTime().seconds
        return s.isFinite ? max(s, 0) : 0
    }

    private func playbackDuration() -> Double {
        let d = playerEngine.player.currentItem?.duration.seconds ?? 0
        return d.isFinite ? max(d, 0) : 0
    }

    private var isSeekPreviewActive: Bool {
        if case .previewing = seekState { return true }
        return false
    }
}
