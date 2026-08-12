import UIKit

/// ```swift
/// let slider = VideoSliderControl()
/// slider.totalDuration = 3600
/// slider.progressGradientColors = [UIColor.systemCyan.cgColor, UIColor.systemBlue.cgColor]
/// slider.trackColor = UIColor.white.withAlphaComponent(0.2)
/// slider.bufferColor = UIColor.white.withAlphaComponent(0.4)
/// slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
/// ```
class VideoSliderControl: UIControl {
    var totalDuration: Double = 0 {
        didSet { updateLayers(animated: false) }
    }
    
    private(set) var currentTime: Double = 0
    
    var bufferedTime: Double = 0 {
        didSet {
            bufferedTime = max(0, min(bufferedTime, totalDuration))
            updateBufferLayer()
        }
    }
    
    var trackColor: UIColor = UIColor.white.withAlphaComponent(0.25) {
        didSet { trackLayer.backgroundColor = trackColor.cgColor }
    }
    
    var bufferColor: UIColor = UIColor.white.withAlphaComponent(0.45) {
        didSet { bufferLayer.backgroundColor = bufferColor.cgColor }
    }
    
    var progressGradientColors: [CGColor] = [
        UIColor(red: 0.55, green: 0.85, blue: 1.0, alpha: 1.0).cgColor,
        UIColor(red: 0.10, green: 0.40, blue: 1.0, alpha: 1.0).cgColor
    ] {
        didSet { progressGradientLayer.colors = progressGradientColors }
    }
    
    var thumbColor: UIColor = .white {
        didSet { thumbLayer.backgroundColor = thumbColor.cgColor }
    }
    
    var thumbShadowColor: UIColor = UIColor(red: 0.10, green: 0.40, blue: 1.0, alpha: 0.6) {
        didSet { thumbLayer.shadowColor = thumbShadowColor.cgColor }
    }
    
    var trackHeight: CGFloat = 6 {
        didSet { layoutSublayers() }
    }
    
    var trackHeightFocused: CGFloat = 10 {
        didSet { layoutSublayers() }
    }
    
    var thumbDiameter: CGFloat = 18 {
        didSet { layoutSublayers() }
    }
    
    var thumbDiameterFocused: CGFloat = 26 {
        didSet { layoutSublayers() }
    }
    
    var seekStep: Double = 10
    private let trackLayer = CALayer()
    private let bufferLayer = CALayer()
    private let progressMaskLayer = CALayer()
    private let progressGradientLayer = CAGradientLayer()
    private let thumbLayer = CALayer()

    private var isFocusedOrHighlighted: Bool {
        isFocused
    }

    private var currentProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(currentTime / totalDuration, 1))
    }

    private var bufferedProgress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(bufferedTime / totalDuration, 1))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = false

        trackLayer.cornerRadius = trackHeight / 2
        trackLayer.backgroundColor = trackColor.cgColor
        layer.addSublayer(trackLayer)

        bufferLayer.cornerRadius = trackHeight / 2
        bufferLayer.backgroundColor = bufferColor.cgColor
        layer.addSublayer(bufferLayer)

        progressGradientLayer.colors = progressGradientColors
        progressGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        progressGradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        progressMaskLayer.backgroundColor = UIColor.white.cgColor
        progressGradientLayer.mask = progressMaskLayer
        layer.addSublayer(progressGradientLayer)

        thumbLayer.backgroundColor = thumbColor.cgColor
        thumbLayer.shadowColor = thumbShadowColor.cgColor
        thumbLayer.shadowOpacity = 0.7
        thumbLayer.shadowOffset  = .zero
        thumbLayer.shadowRadius  = 8
        layer.addSublayer(thumbLayer)
        setupTVOSGestures()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutSublayers()
    }

    private func layoutSublayers() {
        updateLayers(animated: false)
    }

    private func updateLayers(animated: Bool, duration: CFTimeInterval = 0.15, timingFunction: CAMediaTimingFunctionName = .linear) {
        let h = isFocusedOrHighlighted ? trackHeightFocused : trackHeight
        let midY = bounds.midY

        let trackFrame = CGRect(x: 0, y: midY - h / 2, width: bounds.width, height: h)

        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        if animated {
            CATransaction.setAnimationDuration(duration)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: timingFunction))
        }

        trackLayer.frame = trackFrame
        trackLayer.cornerRadius = h / 2

        progressGradientLayer.frame = trackFrame
        progressGradientLayer.cornerRadius = h / 2

        updateBufferLayerFrame(trackFrame: trackFrame, h: h)
        updateProgressLayerFrame(trackFrame: trackFrame, h: h)
        updateThumbLayerFrame(midY: midY)
        CATransaction.commit()
    }

    private func updateBufferLayerFrame(trackFrame: CGRect, h: CGFloat) {
        let w = trackFrame.width * CGFloat(bufferedProgress)
        bufferLayer.frame = CGRect(x: 0, y: trackFrame.minY, width: w, height: h)
        bufferLayer.cornerRadius = h / 2
    }

    private func updateProgressLayerFrame(trackFrame: CGRect, h: CGFloat) {
        let w = trackFrame.width * CGFloat(currentProgress)
        progressMaskLayer.frame = CGRect(x: 0, y: 0, width: w, height: h)
        progressMaskLayer.cornerRadius = h / 2
    }

    private func updateThumbLayerFrame(midY: CGFloat) {
        let d = isFocusedOrHighlighted ? thumbDiameterFocused : thumbDiameter
        let x = bounds.width * CGFloat(currentProgress) - d / 2
        thumbLayer.frame = CGRect(x: x, y: midY - d / 2, width: d, height: d)
        thumbLayer.cornerRadius = d / 2
    }
    
    func seek(by seconds: Double) {
        let newTime = max(0, min(currentTime + seconds, totalDuration))
        guard newTime != currentTime else { return }
        setCurrentTime(newTime, animated: false)
        sendActions(for: .valueChanged)
        animateSeekFeedback(forward: seconds > 0)
    }
    
    /// Use animation for periodic playback updates; user-initiated seeks should be immediate.
    func setCurrentTime(_ time: Double, animated: Bool = false) {
        let newTime = max(0, min(time, totalDuration))
        guard newTime != currentTime else { return }
        currentTime = newTime
        updateLayers(animated: animated)
    }

    private func updateBufferLayer() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let h = isFocusedOrHighlighted ? trackHeightFocused : trackHeight
        let midY = bounds.midY
        let trackFrame = CGRect(x: 0, y: midY - h / 2, width: bounds.width, height: h)
        updateBufferLayerFrame(trackFrame: trackFrame, h: h)
        CATransaction.commit()
    }

    private func animateFocusChange() {
        updateLayers(animated: true, duration: 0.2, timingFunction: .easeOut)
    }

    private func animateSeekFeedback(forward: Bool) {
        let scale: CGFloat = 1.15
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue   = scale
        scaleAnim.duration  = 0.1
        scaleAnim.autoreverses = true
        thumbLayer.add(scaleAnim, forKey: "seekBounce")
    }
    
    open override var canBecomeFocused: Bool { true }

    open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations({
            self.animateFocusChange()
            self.thumbLayer.shadowRadius  = self.isFocused ? 14 : 8
            self.thumbLayer.shadowOpacity = self.isFocused ? 0.9 : 0.7
        }, completion: nil)
    }
    
    override var isHighlighted: Bool {
        didSet { animateFocusChange() }
    }

    private func setupTVOSGestures() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTVPan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }

    @objc private func handleSwipeRight() {
        seek(by: seekStep)
    }

    @objc private func handleSwipeLeft() {
        seek(by: -seekStep)
    }

    private var tvPanAccumulator: CGFloat = 0

    @objc private func handleTVPan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            tvPanAccumulator = 0
        case .changed:
            let velocity = gesture.velocity(in: self)
            guard abs(velocity.x) > abs(velocity.y) * 1.5 else { return }
            let delta = velocity.x * 0.005
            seek(by: Double(delta))
        default:
            break
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard isFocused else { super.pressesBegan(presses, with: event); return }
        for press in presses {
            switch press.type {
            case .rightArrow: seek(by:  seekStep)
            case .leftArrow:  seek(by: -seekStep)
            default:          super.pressesBegan(presses, with: event)
            }
        }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        get { .adjustable }
        set { }
    }
    
    override var accessibilityValue: String? {
        get { String(format: "%.0f / %.0f", currentTime, totalDuration) }
        set { }
    }
    
    override func accessibilityIncrement() {
        seek(by: seekStep)
    }
    
    override func accessibilityDecrement() {
        seek(by: -seekStep)
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: max(thumbDiameterFocused, trackHeightFocused) + 8)
    }
}

extension VideoSliderControl: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: self)
        
        return abs(velocity.x) > abs(velocity.y)
    }
}

extension VideoSliderControl {
    static func youtubeStyle() -> VideoSliderControl {
        let s = VideoSliderControl()
        s.progressGradientColors = [
            UIColor(red: 0.55, green: 0.85, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.10, green: 0.40, blue: 1.0, alpha: 1.0).cgColor
        ]
        s.trackColor  = UIColor.white.withAlphaComponent(0.2)
        s.bufferColor = UIColor.white.withAlphaComponent(0.4)
        s.thumbColor  = .white
        return s
    }
    
    static func netflixStyle() -> VideoSliderControl {
        let s = VideoSliderControl()
        s.progressGradientColors = [
            UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0).cgColor,
            UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
        ]
        s.trackColor       = UIColor.white.withAlphaComponent(0.2)
        s.bufferColor      = UIColor.white.withAlphaComponent(0.4)
        s.thumbColor       = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        s.thumbShadowColor = UIColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 0.7)
        return s
    }
}
