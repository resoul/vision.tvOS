import UIKit
import Combine
import AVFoundation

class VideoController: BaseController {
    let viewModel: VideoViewModel
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let playerView = QueueVideoPlayerLayerView()
    private let playerEngine = QueueVideoPlayerEngine()
    private let overlayView = VideoPlayerOverlay()
    private var isPlaying = true

    private var audioGroup: AVMediaSelectionGroup?
    private var subtitleGroup: AVMediaSelectionGroup?
    
    init(viewModel: VideoViewModel, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.viewModel = viewModel
        super.init(themeManager: themeManager, languageManager: languageManager)
        modalPresentationStyle = .fullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
        bindPlayerEngine()
        setupUI()
        bindViewModel()

        Task {
            await viewModel.loadCurrent()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerEngine.player.pause()
        Task { await viewModel.saveState() }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        playerView.player = playerEngine.player
        loadingView.hidesWhenStopped = true
        overlayView.isSeries = false

        overlayView.delegate = self
        overlayView.videoTitle = ""
        overlayView.totalDuration = 0
        overlayView.currentTime = 0
        overlayView.bufferedTime = 0
        overlayView.isPlaying = isPlaying

        view.addSubviews(playerView, overlayView, loadingView)
        playerView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        overlayView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        loadingView.constraintToCenter(in: view)
    }
    
    private func bindViewModel() {
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

        viewModel.$currentContext
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                self?.handleNewContext(context)
            }
            .store(in: &cancellables)

        viewModel.$shouldDismiss
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)

        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
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

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.playerEngine.player.pause()
                Task { await self.viewModel.saveState() }
            }
            .store(in: &cancellables)
    }

    private func bindPlayerEngine() {
        playerEngine.onPlaybackStateChanged = { [weak self] playing in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPlaying = playing
                self.overlayView.isPlaying = playing
            }
        }

        playerEngine.onTimeUpdate = { [weak self] current, duration in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.viewModel.updateProgress(currentTime: current, duration: duration)
                self.overlayView.setPlaybackTime(current)
                if self.overlayView.totalDuration != duration && duration > 0 {
                    self.overlayView.totalDuration = duration
                }
            }
        }

        playerEngine.onPlaybackFinished = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.viewModel.playNext()
            }
        }

        playerEngine.onTracksAvailable = { [weak self] audioGroup, audioOptions, subtitleGroup, subtitleOptions in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.audioGroup = audioGroup
                self.subtitleGroup = subtitleGroup
                self.updateAudioMenu(from: audioOptions)
                
                if subtitleGroup != nil {
                    self.updateSubtitlesMenu(from: subtitleOptions)
                    self.overlayView.subtitlesButton.isHidden = false
                } else {
                    self.overlayView.subtitlesButton.isHidden = true
                }
            }
        }
    }

    private func handleNewContext(_ context: PlaybackContext) {
        guard let url = URL(string: context.streamURL) else { return }

        audioGroup = nil
        subtitleGroup = nil

        if viewModel.isAwaitingResumeDecision {
            playerEngine.prepare(url: url)
        } else {
            playerEngine.play(url: url)
            if let resumeTime = viewModel.consumeAutoResumeTime() {
                playerEngine.seek(seconds: resumeTime)
            }
        }

        overlayView.videoTitle = titleFor(context: context)
        overlayView.isSeries = switch context {
        case .episode: true
        default: false
        }
        overlayView.isPreviousEpisodeEnabled = viewModel.canPlayPrevious
        overlayView.isNextEpisodeEnabled = viewModel.canPlayNext

        overlayView.show()
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

    private func titleFor(context: PlaybackContext) -> String {
        switch context {
        case .movie(_, _, _, _, let title):
            return title
        case .episode(_, let s, let e, _, _, _, let title):
            return "S\(s)E\(e) · \(title)"
        }
    }

    // MARK: - Press handling

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !overlayView.isHidden {
            for press in presses where overlayView.handlePress(press) {
                return
            }
        }

        if presses.contains(where: { $0.type == .upArrow }) { return }
        if presses.contains(where: { $0.type == .downArrow }) { return }

        if presses.contains(where: { $0.type == .menu }) {
            if !overlayView.isHidden {
                overlayView.hide()
            } else {
                dismiss(animated: true)
            }
            return
        }

        if presses.contains(where: { $0.type == .playPause }) {
            playerEngine.togglePlayPause()
            overlayView.show()
            return
        }

        if presses.contains(where: { $0.type == .select }) {
            if overlayView.isHidden { overlayView.show() }
            return
        }

        if presses.contains(where: { $0.type == .leftArrow }) { return }
        if presses.contains(where: { $0.type == .rightArrow }) { return }

        super.pressesBegan(presses, with: event)
    }

    // MARK: - Audio / Subtitles menus

    private func updateAudioMenu(from options: [AVMediaSelectionOption]) {
        let actions = options.map { option in
            UIAction(
                title: option.displayName,
                state: isCurrentAudio(option) ? .on : .off
            ) { [weak self] _ in
                guard let self, let group = self.audioGroup else { return }
                self.playerEngine.selectAudioOption(option, in: group)
                self.updateAudioMenu(from: options)
            }
        }

        overlayView.translationsButton.menu = UIMenu(title: "AUDIO", children: actions)
        overlayView.translationsButton.showsMenuAsPrimaryAction = true
    }

    private func updateSubtitlesMenu(from options: [AVMediaSelectionOption]) {
        var actions: [UIAction] = [
            UIAction(
                title: "Off",
                state: isSubtitlesOff() ? .on : .off
            ) { [weak self] _ in
                guard let self, let group = self.subtitleGroup else { return }
                self.playerEngine.selectSubtitleOption(nil, in: group)
                self.updateSubtitlesMenu(from: options)
            }
        ]

        actions += options.map { option in
            UIAction(
                title: option.displayName,
                state: isCurrentSubtitle(option) ? .on : .off
            ) { [weak self] _ in
                guard let self, let group = self.subtitleGroup else { return }
                self.playerEngine.selectSubtitleOption(option, in: group)
                self.updateSubtitlesMenu(from: options)
            }
        }

        overlayView.subtitlesButton.menu = UIMenu(title: "SUBTITLES", children: actions)
        overlayView.subtitlesButton.showsMenuAsPrimaryAction = true
    }

    // MARK: - Track helpers (используют кэшированные группы, без deprecated вызовов)

    private func isCurrentAudio(_ option: AVMediaSelectionOption) -> Bool {
        guard let item = playerEngine.player.currentItem,
              let group = audioGroup
        else { return false }
        return item.currentMediaSelection.selectedMediaOption(in: group) == option
    }

    private func isCurrentSubtitle(_ option: AVMediaSelectionOption) -> Bool {
        guard let item = playerEngine.player.currentItem,
              let group = subtitleGroup
        else { return false }
        return item.currentMediaSelection.selectedMediaOption(in: group) == option
    }

    private func isSubtitlesOff() -> Bool {
        guard let item = playerEngine.player.currentItem,
              let group = subtitleGroup
        else { return true }
        return item.currentMediaSelection.selectedMediaOption(in: group) == nil
    }

    // MARK: - Error

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Playback Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.viewModel.clearError()
            Task { await self?.viewModel.retry() }
        })

        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
            self?.viewModel.clearError()
        })

        present(alert, animated: true)
    }
}

// MARK: - VideoPlayerOverlayDelegate

extension VideoController: VideoPlayerOverlayDelegate {
    func overlayDidSeek(to time: Double) {
        playerEngine.seek(seconds: time)
        overlayView.currentTime = time
    }

    func overlayDidTogglePlayPause() {
        playerEngine.togglePlayPause()
    }

    func overlayDidRequestDismiss() {
        overlayView.hide()
    }

    func overlayDidRequestSkipBackward() {
        playerEngine.seekBy(delta: -10)
    }

    func overlayDidRequestSkipForward() {
        playerEngine.seekBy(delta: 10)
    }

    func overlayDidRequestPreviousEpisode() {
        Task { await viewModel.playPrevious() }
    }

    func overlayDidRequestNextEpisode() {
        Task { await viewModel.playNext() }
    }
}
