import UIKit
import Combine
import AVFoundation

struct SubtitleOption {
    let language: String
    let isAuto: Bool
    var isSelected: Bool
}

struct AudioOption {
    let language: String
    var isSelected: Bool
}

// MARK: - VideoController

class VideoController: BaseViewController {
    let viewModel: VideoViewModel
    private let loadingView = UIActivityIndicatorView(style: .large)
    private let playerView = QueueVideoPlayerLayerView()
    private let playerEngine = QueueVideoPlayerEngine()
    private let overlayView = VideoPlayerOverlay()
    private var isPlaying = true

    // MARK: Mock data

    private var subtitles: [SubtitleOption] = [
        SubtitleOption(language: "Auto", isAuto: true, isSelected: true),
        SubtitleOption(language: "English (US) CC", isAuto: false, isSelected: false),
        SubtitleOption(language: "Arabic", isAuto: false, isSelected: false),
        SubtitleOption(language: "Bulgarian", isAuto: false, isSelected: false),
        SubtitleOption(language: "Cantonese, Traditional", isAuto: false, isSelected: false),
        SubtitleOption(language: "Chinese, Simplified", isAuto: false, isSelected: false),
        SubtitleOption(language: "Chinese, Traditional", isAuto: false, isSelected: false),
    ]

    private var audioTracks: [AudioOption] = [
        AudioOption(language: "English", isSelected: true),
        AudioOption(language: "Español", isSelected: false),
        AudioOption(language: "Français", isSelected: false),
        AudioOption(language: "Deutsch", isSelected: false),
        AudioOption(language: "日本語", isSelected: false),
    ]

    // MARK: - Init

    init(viewModel: VideoViewModel, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.viewModel = viewModel
        super.init(themeManager: themeManager, languageManager: languageManager)
        modalPresentationStyle = .fullScreen
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.viewDidLoad()
        bindViewModel()
        bindPlayerEngine()

        Task {
            await viewModel.loadCurrent()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerEngine.player.pause()
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

        updateSubtitlesMenu()
        updateAudioMenu()
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
                self.overlayView.currentTime = current
                if self.overlayView.totalDuration != duration && duration > 0 {
                    self.overlayView.totalDuration = duration
                }
            }
        }

        playerEngine.onPlaybackFinished = { [weak self] in
            Task { @MainActor [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }

    private func handleNewContext(_ context: PlaybackContext) {
        guard let url = URL(string: context.streamURL) else { return }
        playerEngine.play(url: url)
        overlayView.videoTitle = titleFor(context: context)
        overlayView.show()
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

        if presses.contains(where: { $0.type == .upArrow }) {
            return
        }

        if presses.contains(where: { $0.type == .downArrow }) {
            return
        }

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
            if overlayView.isHidden {
                overlayView.show()
            }
            return
        }

        if presses.contains(where: { $0.type == .leftArrow }) {
            return
        }

        if presses.contains(where: { $0.type == .rightArrow }) {
            return
        }

        super.pressesBegan(presses, with: event)
    }

    // MARK: - Subtitles / Audio menus

    private func updateSubtitlesMenu() {
        let actions = subtitles.enumerated().map { (index, option) in
            UIAction(
                title: option.language,
                state: option.isSelected ? .on : .off
            ) { [weak self] _ in
                guard let self else { return }
                for i in self.subtitles.indices { self.subtitles[i].isSelected = false }
                self.subtitles[index].isSelected = true
                self.updateSubtitlesMenu()
            }
        }

        overlayView.subtitlesButton.menu = UIMenu(title: "SUBTITLES", children: actions)
        overlayView.subtitlesButton.showsMenuAsPrimaryAction = true
    }

    private func updateAudioMenu() {
        let actions = audioTracks.enumerated().map { (index, option) in
            UIAction(
                title: option.language,
                state: option.isSelected ? .on : .off
            ) { [weak self] _ in
                guard let self else { return }
                for i in self.audioTracks.indices { self.audioTracks[i].isSelected = false }
                self.audioTracks[index].isSelected = true
                self.updateAudioMenu()
            }
        }

        overlayView.translationsButton.menu = UIMenu(title: "AUDIO", children: actions)
        overlayView.translationsButton.showsMenuAsPrimaryAction = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        Task { await viewModel.loadCurrent() }
    }

    func overlayDidRequestNextEpisode() {
        Task { await viewModel.loadCurrent() }
    }
}
