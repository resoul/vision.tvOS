import UIKit

final class PlayerOverlayView: UIView {
    enum DisplayMode {
        case full
        case scrubberOnly
        case episodeBrowse
    }

    enum Action {
        case previous, rewind, playPause, forward, next
        case description, bell, audioTrack
    }

    var onAction: ((Action) -> Void)?
    var onSliderChanged: ((Double) -> Void)?
    var onQueueSelection: ((Int) -> Void)?
    var onEpisodeSelected: ((Int, Int) -> Void)?
    var onBrowseIdleTimeout: (() -> Void)?

    var currentDisplayMode: DisplayMode { displayMode }
    var isVisible: Bool { !isHidden && alpha > 0.01 }

    private let dimView = UIView()

    private let titleLabel = UILabel()
    private let metadataLabel = UILabel()

    private let progressSlider = PlaybackScrubberControl()
    private let leftTimeLabel = UILabel()
    private let rightTimeLabel = UILabel()

    private let leftControlsStack = UIStackView()
    private let centerControlsStack = UIStackView()
    private let rightControlsStack = UIStackView()

    private let avatarIcon = UIImageView(image: UIImage(systemName: "person.circle.fill"))
    private let descriptionButton = CapsuleButton(title: L10n.Player.description)
    private let bellButton = RoundButton(symbolName: "bell")
    private let playPauseButton = PlayPauseButton()
    private let audioTrackButton = CapsuleButton(title: L10n.Player.audioTrack)

    private let queueCollectionView: UICollectionView
    private let episodeCollectionView: UICollectionView
    private let episodeHeaderLabel = UILabel()
    private let miniEpisodeStrip = MiniEpisodeStripControl()

    private var queue: [VideoQueueItem] = []
    private var currentQueueIndex = 0
    private var episodeBrowseItems: [EpisodeBrowseItem] = []
    private var isSeriesContent = false
    private var currentSeason = 0
    private var currentEpisode = 0
    private var style: ThemeStyle = Theme.dark.style
    private weak var preferredFocusTarget: UIView?
    private var displayMode: DisplayMode = .full
    private var browseIdleTask: Task<Void, Never>?

    private var episodeCollectionCenterYConstraint: NSLayoutConstraint?
    private var miniStripBottomConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        let queueLayout = UICollectionViewFlowLayout()
        queueLayout.scrollDirection = .horizontal
        queueLayout.minimumLineSpacing = 32
        queueLayout.itemSize = CGSize(width: 360, height: 200)
        queueLayout.sectionInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 90)

        let episodeLayout = UICollectionViewFlowLayout()
        episodeLayout.scrollDirection = .horizontal
        episodeLayout.minimumLineSpacing = 24
        episodeLayout.itemSize = CGSize(width: 320, height: 220)
        episodeLayout.sectionInset = UIEdgeInsets(top: 0, left: 90, bottom: 0, right: 90)

        queueCollectionView = UICollectionView(frame: .zero, collectionViewLayout: queueLayout)
        episodeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: episodeLayout)

        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyStyle(_ style: ThemeStyle) {
        self.style = style
        dimView.backgroundColor = UIColor.black.withAlphaComponent(displayMode == .episodeBrowse ? 0.65 : 0.45)

        titleLabel.textColor = .white
        metadataLabel.textColor = .white.withAlphaComponent(0.7)
        leftTimeLabel.textColor = .white.withAlphaComponent(0.8)
        rightTimeLabel.textColor = .white.withAlphaComponent(0.8)
        episodeHeaderLabel.textColor = .white

        progressSlider.minimumTrackTintColor = .white
        progressSlider.maximumTrackTintColor = .white.withAlphaComponent(0.24)
        progressSlider.thumbTintColor = .white

        miniEpisodeStrip.applyStyle(style)
        [descriptionButton, bellButton, audioTrackButton, playPauseButton].forEach { $0.applyStyle(style) }

        avatarIcon.tintColor = .white.withAlphaComponent(0.9)
        queueCollectionView.reloadData()
        episodeCollectionView.reloadData()
    }

    func updateInfo(item: VideoQueueItem) {
        titleLabel.text = item.title
        metadataLabel.text = "\(item.subtitle)  ·  \(item.viewsText)  ·  \(item.addedText)"
        miniEpisodeStrip.updateTitle(seasonEpisodeTitleText())
    }

    func updateQueue(_ queue: [VideoQueueItem], currentIndex: Int) {
        self.queue = queue
        self.currentQueueIndex = currentIndex
        queueCollectionView.reloadData()

        guard queue.indices.contains(currentIndex) else { return }
        queueCollectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
    }

    func updateCurrentQueueIndex(_ index: Int) {
        currentQueueIndex = index
        queueCollectionView.reloadData()

        guard queue.indices.contains(index) else { return }
        queueCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }

    func updatePlayPause(isPlaying: Bool) {
        playPauseButton.setIsPlaying(isPlaying)
    }

    func setDisplayMode(_ mode: DisplayMode) {
        guard displayMode != mode else { return }
        let previousMode = displayMode
        displayMode = mode
        applyDisplayMode(animated: true, previousMode: previousMode)
    }

    func configureEpisodeBrowse(
        items: [EpisodeBrowseItem],
        currentSeason: Int,
        currentEpisode: Int,
        isSeries: Bool
    ) {
        episodeBrowseItems = items
        self.currentSeason = currentSeason
        self.currentEpisode = currentEpisode
        isSeriesContent = isSeries
        if !isSeriesContent, displayMode == .episodeBrowse {
            displayMode = .full
        }

        miniEpisodeStrip.updateTitle(seasonEpisodeTitleText())
        updateEpisodeHeader()
        episodeCollectionView.reloadData()
        queueCollectionView.reloadData()
        updateMiniStripVisibility()
    }

    func updateTimes(current: Double, duration: Double) {
        let safeDuration = max(duration, 0)
        leftTimeLabel.text = formatTime(current)
        rightTimeLabel.text = formatTime(safeDuration)

        if safeDuration > 0 {
            progressSlider.value = CGFloat(current / safeDuration)
            progressSlider.isEnabled = true
        } else {
            progressSlider.value = 0
            progressSlider.isEnabled = false
        }
    }

    func focusScrubber() {
        preferredFocusTarget = progressSlider
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    func focusPrimaryControls() {
        preferredFocusTarget = playPauseButton
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if displayMode == .episodeBrowse {
            return [episodeCollectionView]
        }
        if let preferredFocusTarget, !preferredFocusTarget.isHidden, preferredFocusTarget.alpha > 0 {
            return [preferredFocusTarget]
        }
        return [playPauseButton]
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if displayMode == .episodeBrowse,
           let next = context.nextFocusedView,
           next.isDescendant(of: episodeCollectionView) {
            resetBrowseIdleTimer()
        }
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        isHidden = true
        alpha = 0

        dimView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 48, weight: .bold)
        titleLabel.numberOfLines = 2
        titleLabel.dropShadow()

        metadataLabel.translatesAutoresizingMaskIntoConstraints = false
        metadataLabel.font = .systemFont(ofSize: 28, weight: .medium)
        metadataLabel.dropShadow()

        addSubview(titleLabel)
        addSubview(metadataLabel)

        leftTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        rightTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.translatesAutoresizingMaskIntoConstraints = false

        leftTimeLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        rightTimeLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        rightTimeLabel.textAlignment = .right
        leftTimeLabel.text = "0:00"
        rightTimeLabel.text = "0:00"

        addSubview(leftTimeLabel)
        addSubview(rightTimeLabel)
        addSubview(progressSlider)

        [leftControlsStack, centerControlsStack, rightControlsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 24
            addSubview($0)
        }

        centerControlsStack.spacing = 0

        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarIcon.contentMode = .scaleAspectFit
        leftControlsStack.addArrangedSubview(avatarIcon)
        leftControlsStack.addArrangedSubview(descriptionButton)
        leftControlsStack.addArrangedSubview(bellButton)
        centerControlsStack.addArrangedSubview(playPauseButton)
        rightControlsStack.addArrangedSubview(audioTrackButton)

        queueCollectionView.translatesAutoresizingMaskIntoConstraints = false
        queueCollectionView.backgroundColor = .clear
        queueCollectionView.remembersLastFocusedIndexPath = true
        queueCollectionView.delegate = self
        queueCollectionView.dataSource = self
        queueCollectionView.register(QueueItemCell.self, forCellWithReuseIdentifier: QueueItemCell.reuseID)
        addSubview(queueCollectionView)

        miniEpisodeStrip.translatesAutoresizingMaskIntoConstraints = false
        miniEpisodeStrip.isHidden = true
        addSubview(miniEpisodeStrip)

        episodeHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        episodeHeaderLabel.font = .systemFont(ofSize: 32, weight: .bold)
        episodeHeaderLabel.textColor = .white
        episodeHeaderLabel.alpha = 0
        episodeHeaderLabel.textAlignment = .left
        episodeHeaderLabel.dropShadow()
        addSubview(episodeHeaderLabel)

        episodeCollectionView.translatesAutoresizingMaskIntoConstraints = false
        episodeCollectionView.backgroundColor = .clear
        episodeCollectionView.remembersLastFocusedIndexPath = true
        episodeCollectionView.delegate = self
        episodeCollectionView.dataSource = self
        episodeCollectionView.alpha = 0
        episodeCollectionView.register(EpisodeBrowseCell.self, forCellWithReuseIdentifier: EpisodeBrowseCell.reuseID)
        addSubview(episodeCollectionView)

        let episodeCenterConstraint = episodeCollectionView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 360)
        episodeCollectionCenterYConstraint = episodeCenterConstraint
        let miniBottomConstraint = miniEpisodeStrip.bottomAnchor.constraint(equalTo: queueCollectionView.topAnchor, constant: -8)
        miniStripBottomConstraint = miniBottomConstraint

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 90),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -90),

            metadataLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            metadataLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            progressSlider.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 100),
            progressSlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 90),
            progressSlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -90),

            leftTimeLabel.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            leftTimeLabel.bottomAnchor.constraint(equalTo: progressSlider.topAnchor, constant: -16),

            rightTimeLabel.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            rightTimeLabel.bottomAnchor.constraint(equalTo: progressSlider.topAnchor, constant: -16),

            centerControlsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerControlsStack.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 40),

            leftControlsStack.leadingAnchor.constraint(equalTo: progressSlider.leadingAnchor),
            leftControlsStack.centerYAnchor.constraint(equalTo: centerControlsStack.centerYAnchor),

            rightControlsStack.trailingAnchor.constraint(equalTo: progressSlider.trailingAnchor),
            rightControlsStack.centerYAnchor.constraint(equalTo: centerControlsStack.centerYAnchor),

            avatarIcon.widthAnchor.constraint(equalToConstant: 64),
            avatarIcon.heightAnchor.constraint(equalToConstant: 64),

            queueCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            queueCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            queueCollectionView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
            queueCollectionView.heightAnchor.constraint(equalToConstant: 220),

            miniEpisodeStrip.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 90),
            miniEpisodeStrip.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -90),
            miniBottomConstraint,
            miniEpisodeStrip.heightAnchor.constraint(equalToConstant: 48),

            episodeHeaderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 90),
            episodeHeaderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -90),
            episodeHeaderLabel.bottomAnchor.constraint(equalTo: episodeCollectionView.topAnchor, constant: -28),

            episodeCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            episodeCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            episodeCollectionView.heightAnchor.constraint(equalToConstant: 220),
            episodeCenterConstraint,
        ])

        applyDisplayMode(animated: false, previousMode: .full)
    }

    private func setupActions() {
        descriptionButton.onSelect = { [weak self] in self?.onAction?(.description) }
        bellButton.onSelect = { [weak self] in self?.onAction?(.bell) }
        playPauseButton.onSelect = { [weak self] in self?.onAction?(.playPause) }
        audioTrackButton.onSelect = { [weak self] in self?.onAction?(.audioTrack) }
        miniEpisodeStrip.onSelect = { [weak self] in
            guard let self, self.isSeriesContent else { return }
            self.setDisplayMode(.episodeBrowse)
        }
        progressSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    }

    private func formatTime(_ value: Double) -> String {
        let seconds = Int(max(value, 0))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    @objc private func sliderChanged() {
        onSliderChanged?(Double(progressSlider.value))
    }

    private func applyDisplayMode(animated: Bool, previousMode: DisplayMode) {
        let showsScrubberOnly = displayMode == .scrubberOnly
        let showsEpisodeBrowse = displayMode == .episodeBrowse

        let infoViews = [titleLabel, metadataLabel, progressSlider, leftTimeLabel, rightTimeLabel, leftControlsStack, centerControlsStack, rightControlsStack, queueCollectionView, miniEpisodeStrip]

        let applyState = {
            self.dimView.isHidden = showsScrubberOnly
            self.dimView.backgroundColor = UIColor.black.withAlphaComponent(showsEpisodeBrowse ? 0.65 : 0.45)

            if showsEpisodeBrowse {
                self.episodeCollectionCenterYConstraint?.constant = 0
                self.episodeCollectionView.alpha = 1
                self.episodeHeaderLabel.alpha = 1
                self.infoViewsForAnimation(infoViews).forEach {
                    $0.alpha = 0
                    $0.transform = CGAffineTransform(translationX: 0, y: -40)
                }
            } else if showsScrubberOnly {
                self.episodeCollectionCenterYConstraint?.constant = 360
                self.episodeCollectionView.alpha = 0
                self.episodeHeaderLabel.alpha = 0
                self.infoViewsForAnimation(infoViews).forEach {
                    if $0 === self.progressSlider || $0 === self.leftTimeLabel || $0 === self.rightTimeLabel {
                        $0.alpha = 1
                        $0.transform = .identity
                    } else {
                        $0.alpha = 0
                        $0.transform = .identity
                    }
                }
            } else {
                self.episodeCollectionCenterYConstraint?.constant = 360
                self.episodeCollectionView.alpha = 0
                self.episodeHeaderLabel.alpha = 0
                self.infoViewsForAnimation(infoViews).forEach {
                    $0.alpha = 1
                    $0.transform = .identity
                }
                self.updateMiniStripVisibility()
            }
            self.layoutIfNeeded()
        }

        if !animated {
            applyState()
            updateModeVisibility()
            return
        }

        if showsEpisodeBrowse {
            cancelBrowseIdleTimer()
            episodeCollectionView.reloadData()
            if let currentIndex = episodeBrowseItems.firstIndex(where: \.isCurrent) {
                episodeCollectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)
            }
        }

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseInOut],
            animations: { applyState() },
            completion: { _ in
                self.updateModeVisibility()
                if showsEpisodeBrowse {
                    self.preferredFocusTarget = self.episodeCollectionView
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                    self.resetBrowseIdleTimer()
                } else if previousMode == .episodeBrowse {
                    self.cancelBrowseIdleTimer()
                    self.focusPrimaryControls()
                }
            }
        )
    }

    private func infoViewsForAnimation(_ views: [UIView]) -> [UIView] {
        views.filter { $0 !== miniEpisodeStrip || isSeriesContent }
    }

    private func updateModeVisibility() {
        let isScrubberOnly = displayMode == .scrubberOnly
        let isEpisodeBrowse = displayMode == .episodeBrowse

        titleLabel.isHidden = isScrubberOnly || isEpisodeBrowse
        metadataLabel.isHidden = isScrubberOnly || isEpisodeBrowse
        leftControlsStack.isHidden = isScrubberOnly || isEpisodeBrowse
        centerControlsStack.isHidden = isScrubberOnly || isEpisodeBrowse
        rightControlsStack.isHidden = isScrubberOnly || isEpisodeBrowse
        queueCollectionView.isHidden = isScrubberOnly || isEpisodeBrowse

        miniEpisodeStrip.isHidden = isScrubberOnly || isEpisodeBrowse || !isSeriesContent

        episodeCollectionView.isHidden = !isEpisodeBrowse
        episodeHeaderLabel.isHidden = !isEpisodeBrowse
    }

    private func updateMiniStripVisibility() {
        miniEpisodeStrip.isHidden = !(displayMode == .full && isSeriesContent)
    }

    private func updateEpisodeHeader() {
        let seasonPrefix = String(format: L10n.Player.seasonEpisodeFormat, currentSeason, currentEpisode)
        episodeHeaderLabel.text = "\(seasonPrefix) · \(L10n.Player.upcomingEpisodes)"
    }

    private func seasonEpisodeTitleText() -> String {
        guard isSeriesContent else { return "" }
        let prefix = String(format: L10n.Player.seasonEpisodeFormat, currentSeason, currentEpisode)
        let title = episodeBrowseItems.first(where: \.isCurrent)?.title ?? ""
        if title.isEmpty {
            return prefix
        }
        return "\(prefix)  ·  \(title)"
    }

    private func cancelBrowseIdleTimer() {
        browseIdleTask?.cancel()
        browseIdleTask = nil
    }

    private func resetBrowseIdleTimer() {
        guard displayMode == .episodeBrowse else { return }
        cancelBrowseIdleTimer()
        browseIdleTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.displayMode == .episodeBrowse else { return }
                self.setDisplayMode(.full)
                self.onBrowseIdleTimeout?()
            }
        }
    }
}

private extension UIView {
    func dropShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
    }
}

class OverlayControl: TVFocusControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        bgView.layer.cornerRadius = 32
        focusedBgAlpha = 0.25
        normalBgAlpha = 0.1
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyStyle(_ style: ThemeStyle) {
        bgView.backgroundColor = UIColor.white.withAlphaComponent(isFocused ? focusedBgAlpha : normalBgAlpha)
    }

    override func applyFocusAppearance(focused: Bool) {
        bgView.backgroundColor = UIColor.white.withAlphaComponent(focused ? focusedBgAlpha : normalBgAlpha)
    }
}

final class RoundButton: OverlayControl {
    private let iconView = UIImageView()

    init(symbolName: String) {
        super.init(frame: .zero)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(systemName: symbolName, withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
        iconView.tintColor = .white

        addSubview(iconView)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 72),
            heightAnchor.constraint(equalToConstant: 72),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
        ])
        bgView.layer.cornerRadius = 36
    }

    required init?(coder: NSCoder) { fatalError() }
}

private final class CapsuleButton: OverlayControl {
    private let label = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .systemFont(ofSize: 26, weight: .semibold)
        label.textColor = .white

        addSubview(label)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 72),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        bgView.layer.cornerRadius = 36
    }

    required init?(coder: NSCoder) { fatalError() }
}

private final class PlayPauseButton: OverlayControl {
    private let iconView = UIImageView()
    private var iconCenterXConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .black
        iconView.image = UIImage(systemName: "play.fill")

        addSubview(iconView)
        iconCenterXConstraint = iconView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 2)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 100),
            heightAnchor.constraint(equalToConstant: 100),
            iconCenterXConstraint!,
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
        ])

        bgView.layer.cornerRadius = 50
        normalBgAlpha = 0.95
        focusedBgAlpha = 1.0
        bgView.backgroundColor = .white
    }

    required init?(coder: NSCoder) { fatalError() }

    func setIsPlaying(_ isPlaying: Bool) {
        iconView.image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
        iconCenterXConstraint?.constant = isPlaying ? 0 : 4
        layoutIfNeeded()
    }

    override func applyFocusAppearance(focused: Bool) {
        bgView.backgroundColor = focused ? .white : .white.withAlphaComponent(0.95)
    }
}

private final class MiniEpisodeStripControl: TVFocusControl {
    private let titleLabel = UILabel()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.up"))

    override init(frame: CGRect) {
        super.init(frame: frame)

        normalBgAlpha = 0
        focusedBgAlpha = 0.18
        focusScale = 1.03
        bgView.layer.cornerRadius = 12

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .medium)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.tintColor = UIColor.white.withAlphaComponent(0.6)
        chevronView.contentMode = .scaleAspectFit

        addSubview(titleLabel)
        addSubview(chevronView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -16),
            chevronView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            chevronView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 22),
            chevronView.heightAnchor.constraint(equalToConstant: 22),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateTitle(_ title: String) {
        titleLabel.text = title
    }

    func applyStyle(_ style: ThemeStyle) {
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
    }

    override func applyFocusAppearance(focused: Bool) {
        bgView.backgroundColor = UIColor.white.withAlphaComponent(focused ? focusedBgAlpha : normalBgAlpha)
    }
}

extension PlayerOverlayView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        collectionView == queueCollectionView ? queue.count : episodeBrowseItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == queueCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QueueItemCell.reuseID, for: indexPath) as! QueueItemCell
            cell.configure(item: queue[indexPath.item], style: style, isActive: indexPath.item == currentQueueIndex)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EpisodeBrowseCell.reuseID, for: indexPath) as! EpisodeBrowseCell
        cell.configure(item: episodeBrowseItems[indexPath.item], style: style)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == queueCollectionView {
            onQueueSelection?(indexPath.item)
            return
        }
        let item = episodeBrowseItems[indexPath.item]
        onEpisodeSelected?(item.season, item.episode)
        setDisplayMode(.full)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === episodeCollectionView {
            resetBrowseIdleTimer()
        }
    }
}
