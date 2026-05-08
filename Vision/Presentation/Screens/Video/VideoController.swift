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
        overlayView.videoTitle = "The Elephant Queen"
        overlayView.totalDuration = 60 * 45
        overlayView.currentTime = 0
        overlayView.bufferedTime = 60 * 12
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
    
    private func bindPlayerEngine() {}
    
    private func handleNewContext(_ context: PlaybackContext) {
        print(context)
        guard let url = URL(string: context.streamURL) else { return }
        
        print(url)

//        if viewModel.isAwaitingResumeDecision {
//            playerEngine.prepare(url: url)
//        } else {
//            playerEngine.play(url: url)
//            if let resumeTime = viewModel.consumeAutoResumeTime() {
//                playerEngine.seek(seconds: resumeTime)
//            }
//        }
//
//        let info = VideoQueueItem(
//            id: context.movieId,
//            title: title(for: context),
//            subtitle: subtitle(for: context),
//            viewsText: "",
//            addedText: "",
//            posterURL: ""
//        )
//        overlayView.updateInfo(item: info)
//        Task { [weak self] in
//            guard let self else { return }
//            let items = await self.viewModel.buildEpisodeBrowseItems()
//            await MainActor.run {
//                self.overlayView.configureEpisodeBrowse(
//                    items: items,
//                    currentSeason: self.viewModel.currentSeasonIndex,
//                    currentEpisode: self.viewModel.currentEpisodeIndex,
//                    isSeries: self.viewModel.isSeries
//                )
//                self.showOverlayTemporarily()
//            }
//        }
    }

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

    private func updateSubtitlesMenu() {
        let actions = subtitles.enumerated().map { (index, option) in
            UIAction(
                title: option.language,
                state: option.isSelected ? .on : .off
            ) { [weak self] _ in
                guard let self else { return }
                for i in self.subtitles.indices { self.subtitles[i].isSelected = false }
                self.subtitles[index].isSelected = true
                self.updateSubtitlesMenu()   // обновляем checkmark
                print("Subtitle selected:", option.language)
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
                self.updateAudioMenu()       // обновляем checkmark
                print("Audio track selected:", option.language)
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
    
    func overlayDidRequestPreviousEpisode() {
        print("Previous episode tapped")
        // Ваша логика перехода к предыдущему эпизоду
    }

    func overlayDidRequestNextEpisode() {
        print("Next episode tapped")
        // Ваша логика перехода к следующему эпизоду
    }
}
