import UIKit

// MARK: - Delegate

protocol VideoPlayerOverlayDelegate: AnyObject {
    func overlayDidSeek(to time: Double)
    func overlayDidTogglePlayPause()
    func overlayDidRequestDismiss()
    func overlayDidRequestSkipBackward()
    func overlayDidRequestSkipForward()
    func overlayDidRequestSubtitles()
    func overlayDidRequestTranslations()
}

// MARK: - VideoPlayerOverlay

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

    private let skipBackwardButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        b.setImage(UIImage(systemName: "gobackward.10", withConfiguration: config), for: .normal)
        b.tintColor = .white
        return b
    }()

    private let playPauseButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 34, weight: .medium)
        b.setImage(UIImage(systemName: "pause.fill", withConfiguration: config), for: .normal)
        b.tintColor = .white
        return b
    }()

    private let skipForwardButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        b.setImage(UIImage(systemName: "goforward.10", withConfiguration: config), for: .normal)
        b.tintColor = .white
        return b
    }()

    // Stack that holds the three playback buttons
    private lazy var playbackControlsStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [skipBackwardButton, playPauseButton, skipForwardButton])
        s.axis = .horizontal
        s.alignment = .center
        s.spacing = 48
        return s
    }()

    // MARK: - UI: right menu buttons

    private let subtitlesButton: UIButton = makeMenuButton(
        icon: "captions.bubble.fill",
        title: "Subtitles"
    )

    private let translationsButton: UIButton = makeMenuButton(
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
        // Title — bottom-left, above slider area
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        playbackControlsStack.translatesAutoresizingMaskIntoConstraints = false
        rightMenuStack.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Slider — anchored to bottom
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -80),
            slider.heightAnchor.constraint(equalToConstant: 40),

            // Time labels below slider
            currentTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            currentTimeLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),

            totalTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 8),
            totalTimeLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor),

            // Title — left-aligned, above slider
            titleLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: -24),
            titleLabel.trailingAnchor.constraint(equalTo: playbackControlsStack.leadingAnchor, constant: -20),

            // Playback controls — centered horizontally, same vertical as title
            playbackControlsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            playbackControlsStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            // Right menu — right-aligned, same vertical as title
            rightMenuStack.trailingAnchor.constraint(equalTo: slider.trailingAnchor),
            rightMenuStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            // Button sizes
            skipBackwardButton.widthAnchor.constraint(equalToConstant: 60),
            skipBackwardButton.heightAnchor.constraint(equalToConstant: 60),
            playPauseButton.widthAnchor.constraint(equalToConstant: 60),
            playPauseButton.heightAnchor.constraint(equalToConstant: 60),
            skipForwardButton.widthAnchor.constraint(equalToConstant: 60),
            skipForwardButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    private func setupActions() {
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .primaryActionTriggered)
        skipBackwardButton.addTarget(self, action: #selector(skipBackwardTapped), for: .primaryActionTriggered)
        skipForwardButton.addTarget(self, action: #selector(skipForwardTapped), for: .primaryActionTriggered)
        subtitlesButton.addTarget(self, action: #selector(subtitlesTapped), for: .primaryActionTriggered)
        translationsButton.addTarget(self, action: #selector(translationsTapped), for: .primaryActionTriggered)
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Focus

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [slider]
    }

    // MARK: - Remote press routing (called from VideoController)

    /// Returns true if the press was handled
    func handlePress(_ press: UIPress) -> Bool {
        switch press.type {
        case .playPause:
            delegate?.overlayDidTogglePlayPause()
            return true
        case .menu:
            delegate?.overlayDidRequestDismiss()
            return true
        case .leftArrow:
            slider.seek(by: -slider.seekStep)
            delegate?.overlayDidSeek(to: slider.currentTime)
            return true
        case .rightArrow:
            slider.seek(by: slider.seekStep)
            delegate?.overlayDidSeek(to: slider.currentTime)
            return true
        default:
            return false
        }
    }

    // MARK: - Actions

    @objc private func sliderChanged(_ sender: VideoSliderControl) {
        currentTimeLabel.text = formatTime(sender.currentTime)
        delegate?.overlayDidSeek(to: sender.currentTime)
    }

    @objc private func playPauseTapped() {
        delegate?.overlayDidTogglePlayPause()
    }

    @objc private func skipBackwardTapped() {
        delegate?.overlayDidRequestSkipBackward()
    }

    @objc private func skipForwardTapped() {
        delegate?.overlayDidRequestSkipForward()
    }

    @objc private func subtitlesTapped() {
        delegate?.overlayDidRequestSubtitles()
    }

    @objc private func translationsTapped() {
        delegate?.overlayDidRequestTranslations()
    }

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
        guard animated else { isHidden = true; return }
        UIView.animate(withDuration: 0.25) { self.alpha = 0 } completion: { _ in self.isHidden = true }
    }

    // MARK: - Helpers

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
        b.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        b.tintColor = .white

        // Stack icon + label vertically inside button using a manual layout approach
        // For tvOS the standard UIButton with .vertical layout works on iOS 15+
        if #available(tvOS 15.0, *) {
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
        }

        return b
    }
}
