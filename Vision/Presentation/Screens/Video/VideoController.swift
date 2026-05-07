import UIKit

class VideoController: BaseViewController {
    let viewModel: VideoViewModel
    private let playerView = QueueVideoPlayerLayerView()
    private let playerEngine = QueueVideoPlayerEngine()
    private let overlayView = VideoPlayerOverlay()
    private var isPlaying = true

    init(viewModel: VideoViewModel, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.viewModel = viewModel
        super.init(themeManager: themeManager, languageManager: languageManager)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.viewDidLoad()
    }

    private func setupUI() {
        view.backgroundColor = .black
        playerView.player = playerEngine.player

        overlayView.delegate = self
        overlayView.totalDuration = 60 * 45
        overlayView.currentTime = 0
        overlayView.bufferedTime = 60 * 12
        overlayView.isPlaying = isPlaying

        view.addSubviews(playerView, overlayView)
        playerView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        overlayView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !overlayView.isHidden {
            for press in presses where overlayView.handlePress(press) {
                return
            }
        }

        if presses.contains(where: { $0.type == .upArrow }) {
            print("pressesBegan", "upArrow")
            return
        }

        if presses.contains(where: { $0.type == .downArrow }) {
            print("pressesBegan", "downArrow")
            return
        }

        if presses.contains(where: { $0.type == .menu }) {
            print("pressesBegan", "menu")
            return
        }

        if presses.contains(where: { $0.type == .playPause }) {
            print("pressesBegan", "playPause")
            showOverlay()
            return
        }

        if presses.contains(where: { $0.type == .select }) {
            print("pressesBegan", "select")
            showOverlay()
            return
        }

        if presses.contains(where: { $0.type == .leftArrow }) {
            print("pressesBegan", "leftArrow")
            return
        }

        if presses.contains(where: { $0.type == .rightArrow }) {
            print("pressesBegan", "rightArrow")
            return
        }

        super.pressesBegan(presses, with: event)
    }

    private func showOverlay() {
        overlayView.show()
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VideoController: VideoPlayerOverlayDelegate {
    func overlayDidSeek(to time: Double) {
        overlayView.currentTime = time
    }

    func overlayDidTogglePlayPause() {
        isPlaying.toggle()
        overlayView.isPlaying = isPlaying
    }

    func overlayDidRequestDismiss() {
        overlayView.hide()
    }
}
