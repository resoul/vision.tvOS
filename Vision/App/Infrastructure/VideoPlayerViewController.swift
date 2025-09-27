import UIKit
import AVKit
import AVFoundation

class VideoPlayerViewController: UIViewController, FocusableScrubberDelegate {

    private let playerViewController = AVPlayerViewController()
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    private let scrubberView = FocusableScrubberView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupPlayer()
        setupScrubberView()
        addTimeObserver()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerViewController.player?.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else { return }
        player = AVPlayer(url: url)
        playerViewController.player = player
        
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playerViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            playerViewController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            playerViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8)
        ])
        
        playerViewController.didMove(toParent: self)
        
        // Add an observer for the video's duration
        player?.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
    }

    private func setupScrubberView() {
        view.addSubview(scrubberView)
        scrubberView.translatesAutoresizingMaskIntoConstraints = false
        scrubberView.delegate = self
        
        NSLayoutConstraint.activate([
            scrubberView.topAnchor.constraint(equalTo: playerViewController.view.bottomAnchor, constant: 20),
            scrubberView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            scrubberView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50)
        ])
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            guard let self = self, let duration = self.player?.currentItem?.duration else { return }
            guard duration.isValid && !duration.isIndefinite else { return }
            
            let currentTime = CMTimeGetSeconds(time)
            let totalDuration = CMTimeGetSeconds(duration)
            
            if totalDuration > 0 {
                self.scrubberView.progressView.progress = Float(currentTime / totalDuration)
            }
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration", let duration = player?.currentItem?.duration {
            // Pass the video duration to the scrubber view
            scrubberView.setDuration(duration)
        }
    }

    // MARK: - FocusableScrubberDelegate
    
    func scrubber(_ scrubber: FocusableScrubberView, didRequestSeekTo time: CMTime) {
        player?.seek(to: time)
    }
}
