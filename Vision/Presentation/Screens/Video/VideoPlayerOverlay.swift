import UIKit

protocol VideoPlayerOverlayDelegate: AnyObject {
    func overlayDidSeek(to time: Double)
    func overlayDidTogglePlayPause()
    func overlayDidRequestDismiss()
}

final class VideoPlayerOverlay: UIView {
    weak var delegate: VideoPlayerOverlayDelegate?

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
        didSet {
            let icon = isPlaying ? "pause.fill" : "play.fill"
            playPauseButton.setImage(UIImage(systemName: icon), for: .normal)
        }
    }

    // MARK: - UI

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
        l.textColor = UIColor.white.withAlphaComponent(0.6)
        l.text = "0:00"
        return l
    }()

    private let playPauseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        b.tintColor = .white
        return b
    }()

    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        g.locations = [0.0, 1.0]
        return g
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

    private func setup() {
        isHidden = true
        alpha = 0
        layer.addSublayer(gradientLayer)

        addSubviews(slider, currentTimeLabel, totalTimeLabel, playPauseButton)
        playPauseButton.constraints(top: nil, leading: nil, bottom: slider.topAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 20, right: 0), size: .init(width: 60, height: 60))
        playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        slider.constraints(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 60, bottom: 80, right: 60), size: .init(width: 0, height: 40))
        currentTimeLabel.constraints(top: slider.bottomAnchor, leading: slider.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 8, left: 0, bottom: 0, right: 0))
        totalTimeLabel.constraints(top: slider.bottomAnchor, leading: nil, bottom: nil, trailing: slider.trailingAnchor, padding: .init(top: 8, left: 0, bottom: 0, right: 0))

        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .primaryActionTriggered)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [slider]
    }

    // MARK: - pressesBegan — ВСЯ логика пульта здесь

    // Оверлей должен быть первым responder или
    // VideoController пробрасывает сюда нажатия
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

    // MARK: - Show / Hide

    func show(animated: Bool = true) {
        guard isHidden || alpha < 1 else { return }
        isHidden = false
        let finish = {
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
        guard animated else {
            alpha = 1
            finish()
            return
        }
        UIView.animate(withDuration: 0.25) {
            self.alpha = 1
        } completion: { _ in
            finish()
        }
    }

    func hide(animated: Bool = true) {
        guard animated else { isHidden = true; return }
        UIView.animate(withDuration: 0.25) { self.alpha = 0 } completion: { _ in
            self.isHidden = true
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }
}
