import AsyncDisplayKit

final class VideoOverlayNode: ASDisplayNode {
    
    private let durationNode = DurationNode()
    private let sliderNode = SliderNode()
    
    var onSeek: ((Float) -> Void)? {
        didSet {
            sliderNode.onSeek = onSeek
        }
    }
    
    override init() {
        super.init()
        automaticallyManagesSubnodes = true
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        cornerRadius = 8
        clipsToBounds = true
        
        durationNode.updateTimeLabel(current: "00:00", total: "00:00")
    }
    
    func updateDuration(current: Double, total: Double) {
        durationNode.updateTimeLabel(current: format(seconds: current), total: format(seconds: total))
        
        guard total > 0 else { return }
        sliderNode.progress = Float(current) / Float(total)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let layout = ASStackLayoutSpec.vertical()
        layout.spacing = 8
        layout.children = [sliderNode, durationNode]
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20),
            child: layout
        )
    }
    
    private func format(seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}


import UIKit
import AVFoundation

final class VideoView: UIView {
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    private func commonInit() {
        playerLayer.videoGravity = .resizeAspect
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
}


final class VideoNode: ASDisplayNode {
    
    private let player: AVPlayer

    init(_ url: URL) {
        self.player = AVPlayer(url: url)
        super.init()
        automaticallyManagesSubnodes = true
        setViewBlock { () -> UIView in
            let view = VideoView()
            view.player = self.player
            
            return view
        }
    }
    
    override func didLoad() {
        super.didLoad()
        player.play()
    }
    
    func getCurrentItem() -> AVPlayerItem? {
        return player.currentItem
    }
    
    func seek(to time: CMTime) {
        player.seek(to: time)
    }
}


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let url = URL(string: "https://nl201.cdnsqu.com/s/FHypKguneCkMCqe2P8PiGCpEFBQUFBQUFBQUFBUnMxQjF3L29BUlk1c1V6RT0.nCIJzcMiWjgEdlTMe_FyA3z74E5Tm2BWGPNbdQ/the.client.list.newstudio.2012-nf19/s01e01_480.mp4") else {
            return
        }
        
        let controller = VideoController(url)
        controller.modalPresentationStyle = .overFullScreen
        
        navigationController?.present(controller, animated: true)
    }
}

final class VideoController: ASDKViewController<ASDisplayNode> {
    
    private let videoNode: VideoNode
    private let overlayNode = VideoOverlayNode()
    
    private var timer: Timer?
    
    init(_ url: URL) {
        self.videoNode = VideoNode(url)
        super.init(node: ASDisplayNode())
        self.node.automaticallyManagesSubnodes = true
        self.node.layoutSpecBlock = { [weak self] _, _ in
            guard let strongSelf = self else { return ASLayoutSpec() }

            return ASOverlayLayoutSpec(
                child: strongSelf.videoNode,
                overlay: ASInsetLayoutSpec(
                    insets: UIEdgeInsets(top: .infinity, left: 40, bottom: 60, right: 40),
                    child: strongSelf.overlayNode
                )
            )
        }
        
        overlayNode.onSeek = { [weak self] time in
            guard let self = self, let duration = self.videoNode.getCurrentItem()?.duration.seconds, duration.isFinite else {
                return
            }
            self.videoNode.seek(to: CMTime(seconds: Double(time) * duration, preferredTimescale: 600))
        }
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateOverlay()
        }
    }
    
    private func updateOverlay() {
        guard let item = videoNode.getCurrentItem() else { return }

        let current = item.currentTime().seconds
        let total = item.duration.seconds

        guard current.isFinite, total.isFinite else { return }
        
        overlayNode.updateDuration(current: current, total: total)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
import AsyncDisplayKit
import UIKit

class DurationNode: ASDisplayNode {
    
    private let currentTimeLabel = ASTextNode()
    private let totalTimeLabel = ASTextNode()
    
    override init() {
        super.init()
        automaticallyManagesSubnodes = true
    }
    
    func updateTimeLabel(current: String, total: String) {
        currentTimeLabel.attributedText = NSAttributedString(
            string: current,
            attributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.white
            ]
        )

        totalTimeLabel.attributedText = NSAttributedString(
            string: total,
            attributes: [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.white
            ]
        )
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let layout = ASStackLayoutSpec.horizontal()
        layout.justifyContent = .spaceBetween
        layout.children = [currentTimeLabel, totalTimeLabel]
        
        return layout
    }
}
import UIKit

final class FocusableSliderView: UIView {

    var progress: Float = 0.0 {
        didSet {
            progress = max(0.0, min(1.0, progress))
            setNeedsDisplay()
        }
    }

    var onSeek: ((Float) -> Void)?

    private var isFocusedNow = false

    override var canBecomeFocused: Bool {
        return true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        isFocusedNow = (context.nextFocusedView == self)
        setNeedsDisplay()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        print(press)

        switch press.type {
        case .leftArrow:
            progress -= 0.02
        case .rightArrow:
            progress += 0.02
        default:
            super.pressesBegan(presses, with: event)
            return
        }

        onSeek?(progress)
        setNeedsDisplay()
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        print(progress)
        super.pressesEnded(presses, with: event)
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let barHeight: CGFloat = 6.0
        let y = (rect.height - barHeight) / 2
        let backgroundRect = CGRect(x: 0, y: y, width: rect.width, height: barHeight)
        let progressWidth = CGFloat(progress) * rect.width
        let progressRect = CGRect(x: 0, y: y, width: progressWidth, height: barHeight)

        ctx.setFillColor(UIColor.darkGray.cgColor)
        ctx.fill(backgroundRect)

        ctx.setFillColor((isFocusedNow ? UIColor.systemYellow : UIColor.white).cgColor)
        ctx.fill(progressRect)
    }
}
import AsyncDisplayKit

final class SliderNode: ASDisplayNode {
    
    private let sliderView = FocusableSliderView()

    var onSeek: ((Float) -> Void)? {
        get { sliderView.onSeek }
        set { sliderView.onSeek = newValue }
    }

    var progress: Float {
        get { sliderView.progress }
        set { sliderView.progress = newValue }
    }
    
    override init() {
        super.init()
        backgroundColor = .clear
        setViewBlock { () -> UIView in
            return self.sliderView
        }
    }
    
    override func calculateLayoutThatFits(_ constrainedSize: ASSizeRange) -> ASLayout {
        let height: CGFloat = 30
        return ASLayout(layoutElement: self, size: CGSize(width: constrainedSize.max.width, height: height))
    }
}
