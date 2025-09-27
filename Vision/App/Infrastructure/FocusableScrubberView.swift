import UIKit
import AVFoundation

protocol FocusableScrubberDelegate: AnyObject {
    func scrubber(_ scrubber: FocusableScrubberView, didRequestSeekTo time: CMTime)
}

class FocusableScrubberView: UIView {
    
    weak var delegate: FocusableScrubberDelegate?
    
    let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.progressTintColor = .red
        pv.trackTintColor = .darkGray
        return pv
    }()
    
    private var videoDuration: CMTime = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add gesture recognizer for scrubbing
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    // Override this property to make the view focusable
    override var canBecomeFocused: Bool {
        return true
    }
    
    // Update the visual appearance when focus changes
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
                self.transform = .identity
            }
        }, completion: nil)
    }
    
    // Handle the pan gesture
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard videoDuration.isValid && videoDuration.isIndefinite == false else { return }
        
        let totalSeconds = CMTimeGetSeconds(videoDuration)
        let translation = gesture.translation(in: self)
        
        // Calculate the percentage of movement
        let translationPercentage = translation.x / self.bounds.width
        
        // Calculate the new time in seconds
        let newTimeInSeconds = totalSeconds * Double(progressView.progress) + (totalSeconds * translationPercentage)
        let newCMTime = CMTime(seconds: newTimeInSeconds, preferredTimescale: 600)
        
        // Update the player through the delegate
        delegate?.scrubber(self, didRequestSeekTo: newCMTime)
        
        // Reset the translation to zero so the next update is relative
        gesture.setTranslation(.zero, in: self)
    }
    
    func setDuration(_ duration: CMTime) {
        self.videoDuration = duration
    }
}
