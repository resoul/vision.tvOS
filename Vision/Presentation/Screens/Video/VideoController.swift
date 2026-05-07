import UIKit

// MARK: - Mock data models

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
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.viewDidLoad()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black
        playerView.player = playerEngine.player

        overlayView.delegate = self
        overlayView.videoTitle = "The Elephant Queen"
        overlayView.totalDuration = 60 * 45
        overlayView.currentTime = 0
        overlayView.bufferedTime = 60 * 12
        overlayView.isPlaying = isPlaying

        view.addSubviews(playerView, overlayView)
        playerView.constraints(
            top: view.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.bottomAnchor,
            trailing: view.trailingAnchor
        )
        overlayView.constraints(
            top: view.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.bottomAnchor,
            trailing: view.trailingAnchor
        )
    }

    // MARK: - Remote control

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
            return
        }

        if presses.contains(where: { $0.type == .playPause }) {
            showOverlay()
            return
        }

        if presses.contains(where: { $0.type == .select }) {
            showOverlay()
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

    // MARK: - Overlay

    private func showOverlay() {
        overlayView.show()
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    // MARK: - Subtitles / Audio menus

    private func showSubtitlesMenu() {
        let alert = UIAlertController(title: "SUBTITLES", message: nil, preferredStyle: .actionSheet)
        for (index, option) in subtitles.enumerated() {
            let title = option.isSelected ? "✓  \(option.language)" : "    \(option.language)"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                for i in self.subtitles.indices { self.subtitles[i].isSelected = false }
                self.subtitles[index].isSelected = true
                print("Subtitle selected:", option.language)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showTranslationsMenu() {
        let alert = UIAlertController(title: "AUDIO", message: nil, preferredStyle: .actionSheet)
        for (index, option) in audioTracks.enumerated() {
            let title = option.isSelected ? "✓  \(option.language)" : "    \(option.language)"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self else { return }
                for i in self.audioTracks.indices { self.audioTracks[i].isSelected = false }
                self.audioTracks[index].isSelected = true
                print("Audio track selected:", option.language)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - VideoPlayerOverlayDelegate

extension VideoController: VideoPlayerOverlayDelegate {
    func overlayDidSeek(to time: Double) {
        overlayView.currentTime = time
        // playerEngine.seek(to: time)
    }

    func overlayDidTogglePlayPause() {
        isPlaying.toggle()
        overlayView.isPlaying = isPlaying
        // isPlaying ? playerEngine.play() : playerEngine.pause()
    }

    func overlayDidRequestDismiss() {
        overlayView.hide()
    }

    func overlayDidRequestSkipBackward() {
        let newTime = max(0, overlayView.currentTime - 10)
        overlayView.currentTime = newTime
        // playerEngine.seek(to: newTime)
    }

    func overlayDidRequestSkipForward() {
        let newTime = min(overlayView.totalDuration, overlayView.currentTime + 10)
        overlayView.currentTime = newTime
        // playerEngine.seek(to: newTime)
    }

    func overlayDidRequestSubtitles() {
        showSubtitlesMenu()
    }

    func overlayDidRequestTranslations() {
        showTranslationsMenu()
    }
}
