import UIKit

protocol VideoPlayerOverlayDelegate: AnyObject {
    func overlayDidSeek(to time: Double)
    func overlayDidTogglePlayPause()
    func overlayDidRequestDismiss()
    func overlayDidRequestSkipBackward()
    func overlayDidRequestSkipForward()
    func overlayDidRequestPreviousEpisode()
    func overlayDidRequestNextEpisode()
}

final class VideoPlayerOverlay: UIView {

    weak var delegate: VideoPlayerOverlayDelegate?

    // MARK: Public state

    var videoTitle: String = "" {
        didSet { titleLabel.text = videoTitle }
    }

    var totalDuration: Double = 0 {
        didSet {
            slider.totalDuration = totalDuration
            totalTimeLabel.text = formatTime(totalDuration)
        }
    }

    var currentTime: Double = 0 {
        didSet {
            slider.currentTime = currentTime
            currentTimeLabel.text = formatTime(currentTime)
        }
    }

    var bufferedTime: Double = 0 {
        didSet { slider.bufferedTime = bufferedTime }
    }

    var isPlaying: Bool = false {
        didSet { updatePlayPauseIcon() }
    }
    
    var isSeries: Bool = false {
        didSet { updateSeriesButtons() }
    }

    // MARK: - UI: gradient

    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.black.withAlphaComponent(0.85).cgColor
        ]
        g.locations = [0.0, 0.5, 1.0]
        return g
    }()

    // MARK: - UI: title

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 38, weight: .semibold)
        l.textColor = .white
        l.numberOfLines = 1
        return l
    }()

    // MARK: - UI: playback controls (center row)

    private let previousEpisodeButton: UIButton = {  // NEW
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        var btnConfig = UIButton.Configuration.plain()
        btnConfig.baseForegroundColor = .white
        btnConfig.image = UIImage(systemName: "backward.end.fill", withConfiguration: config)
        b.configuration = btnConfig
        b.isHidden = true
        return b
    }()

    private let skipBackwardButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        var btnConfig = UIButton.Configuration.plain()
        btnConfig.baseForegroundColor = .white
        btnConfig.image = UIImage(systemName: "gobackward.10", withConfiguration: config)
        b.configuration = btnConfig
        return b
    }()

    private let playPauseButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        var btnConfig = UIButton.Configuration.plain()
        btnConfig.baseForegroundColor = .white
        btnConfig.image = UIImage(systemName: "pause.fill", withConfiguration: config)
        b.configuration = btnConfig
        return b
    }()

    private let skipForwardButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        var btnConfig = UIButton.Configuration.plain()
        btnConfig.baseForegroundColor = .white
        btnConfig.image = UIImage(systemName: "goforward.10", withConfiguration: config)
        b.configuration = btnConfig
        return b
    }()

    private let nextEpisodeButton: UIButton = {  // NEW
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        var btnConfig = UIButton.Configuration.plain()
        btnConfig.baseForegroundColor = .white
        btnConfig.image = UIImage(systemName: "forward.end.fill", withConfiguration: config)
        b.configuration = btnConfig
        b.isHidden = true
        return b
    }()

    private lazy var playbackControlsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [
            previousEpisodeButton,  // NEW
            skipBackwardButton,
            playPauseButton,
            skipForwardButton,
            nextEpisodeButton       // NEW
        ])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 48
        return s
    }()
    
    let subtitlesButton: UIButton = makeMenuButton(
        icon: "captions.bubble.fill",
        title: "Subtitles"
    )
    
    let translationsButton: UIButton = makeMenuButton(
        icon: "character.bubble.fill",
        title: "Audio"
    )

    private lazy var rightMenuStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [subtitlesButton, translationsButton])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 24
        return s
    }()

    // MARK: - UI: slider row

    private let slider = VideoSliderControl.youtubeStyle()

    private let currentTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        l.textColor = .white
        l.text = "0:00"
        return l
    }()

    private let totalTimeLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.55)
        l.text = "0:00"
        return l
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        isHidden = true
        alpha = 0
        clipsToBounds = false

        layer.addSublayer(gradientLayer)

        addSubviews(
            titleLabel,
            playbackControlsStack,
            rightMenuStack,
            slider,
            currentTimeLabel,
            totalTimeLabel
        )

        setupConstraints()
        setupActions()
        updatePlayPauseIcon()
    }

    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        playbackControlsStack.translatesAutoresizingMaskIntoConstraints = false
        rightMenuStack.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -80),
            slider.heightAnchor.constraint(equalToConstant: 40),

            currentTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            currentTimeLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),

            totalTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            totalTimeLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: -24),
            titleLabel.trailingAnchor.constraint(equalTo: playbackControlsStack.leadingAnchor, constant: -20),

            playbackControlsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            playbackControlsStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            rightMenuStack.trailingAnchor.constraint(equalTo: slider.trailingAnchor),
            rightMenuStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            skipBackwardButton.widthAnchor.constraint(equalToConstant: 60),
            skipBackwardButton.heightAnchor.constraint(equalToConstant: 60),
            playPauseButton.widthAnchor.constraint(equalToConstant: 60),
            playPauseButton.heightAnchor.constraint(equalToConstant: 60),
            skipForwardButton.widthAnchor.constraint(equalToConstant: 60),
            skipForwardButton.heightAnchor.constraint(equalToConstant: 60),

            // NEW — episode buttons
            previousEpisodeButton.widthAnchor.constraint(equalToConstant: 60),
            previousEpisodeButton.heightAnchor.constraint(equalToConstant: 60),
            nextEpisodeButton.widthAnchor.constraint(equalToConstant: 60),
            nextEpisodeButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    private func setupActions() {
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .primaryActionTriggered)
        skipBackwardButton.addTarget(self, action: #selector(skipBackwardTapped), for: .primaryActionTriggered)
        skipForwardButton.addTarget(self, action: #selector(skipForwardTapped), for: .primaryActionTriggered)
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        // NEW
        previousEpisodeButton.addTarget(self, action: #selector(previousEpisodeTapped), for: .primaryActionTriggered)
        nextEpisodeButton.addTarget(self, action: #selector(nextEpisodeTapped), for: .primaryActionTriggered)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private weak var lastFocusedView: UIView?

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [lastFocusedView ?? slider]
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        guard let next = context.nextFocusedView else { return }
        let tracked: [UIView] = [
            slider, subtitlesButton, translationsButton,
            playPauseButton, skipBackwardButton, skipForwardButton,
            previousEpisodeButton, nextEpisodeButton  // NEW
        ]
        if tracked.contains(where: { $0 === next }) {
            lastFocusedView = next
        }
    }

    func handlePress(_ press: UIPress) -> Bool {
        switch press.type {
        case .playPause:
            delegate?.overlayDidTogglePlayPause()
            return true
        case .menu:
            delegate?.overlayDidRequestDismiss()
            return true
        case .leftArrow:
            guard slider.isFocused else { return false }
            slider.seek(by: -slider.seekStep)
            delegate?.overlayDidSeek(to: slider.currentTime)
            return true
        case .rightArrow:
            guard slider.isFocused else { return false }
            slider.seek(by: slider.seekStep)
            delegate?.overlayDidSeek(to: slider.currentTime)
            return true
        case .select:
            return false
        default:
            return false
        }
    }

    // MARK: - Actions

    @objc private func sliderChanged(_ sender: VideoSliderControl) {
        currentTimeLabel.text = formatTime(sender.currentTime)
        delegate?.overlayDidSeek(to: sender.currentTime)
    }

    @objc private func playPauseTapped() { delegate?.overlayDidTogglePlayPause() }
    @objc private func skipBackwardTapped() { delegate?.overlayDidRequestSkipBackward() }
    @objc private func skipForwardTapped() { delegate?.overlayDidRequestSkipForward() }
    @objc private func previousEpisodeTapped() { delegate?.overlayDidRequestPreviousEpisode() }
    @objc private func nextEpisodeTapped() { delegate?.overlayDidRequestNextEpisode() }

    // MARK: - Show / Hide

    func show(animated: Bool = true) {
        guard isHidden || alpha < 1 else { return }
        isHidden = false
        let finish = {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
        guard animated else { alpha = 1; finish(); return }
        UIView.animate(withDuration: 0.25) { self.alpha = 1 } completion: { _ in finish() }
    }

    func hide(animated: Bool = true) {
        lastFocusedView = nil
        guard animated else { isHidden = true; return }
        UIView.animate(withDuration: 0.25) { self.alpha = 0 } completion: { _ in self.isHidden = true }
    }
    
    private func updateSeriesButtons() {
        previousEpisodeButton.isHidden = !isSeries
        nextEpisodeButton.isHidden = !isSeries
    }

    private func updatePlayPauseIcon() {
        let name = isPlaying ? "pause.fill" : "play.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        playPauseButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }

    private static func makeMenuButton(icon: String, title: String) -> UIButton {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)

        var btnConfig = UIButton.Configuration.plain()
        btnConfig.image = UIImage(systemName: icon, withConfiguration: config)
        btnConfig.title = title
        btnConfig.imagePlacement = .top
        btnConfig.imagePadding = 6
        btnConfig.baseForegroundColor = .white
        btnConfig.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.white
            ])
        )
        b.configuration = btnConfig
        return b
    }
}
