import UIKit

let videoUrl = URL(string: "https://nl201.cdnsqu.com/s/FHV8uOMYDn3Cz1b7V70tmOwEFBQUFBQUFBQUFBUm82U3hndm9BUlk1c1V6RT0.qnh9j3RyMu8Pkqm3djlYsmLTE-i8sPQgnxMqsw/fatal.seduction.2023.rezka.ru/s01e01_480.mp4")!

class PlayerController: UIViewController {
    
    var player = Player()
    
    // MARK: object lifecycle
    deinit {
        self.player.willMove(toParent: nil)
        self.player.view.removeFromSuperview()
        self.player.removeFromParent()
    }
    
    // MARK: view lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.autoresizingMask = ([.flexibleWidth, .flexibleHeight])
        
        self.player.playerDelegate = self
        self.player.playbackDelegate = self

        self.player.playerView.playerBackgroundColor = .black

        self.addChild(self.player)
        self.view.addSubview(self.player.view)
        self.player.didMove(toParent: self)
        
        self.player.url = videoUrl
        
        self.player.playbackLoops = true
        
        let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
        tapGestureRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)];
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.player.playFromBeginning()
    }
}

// MARK: - UIGestureRecognizer

extension PlayerController {
    
    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        switch (self.player.playbackState.rawValue) {
        case Player.PlaybackState.stopped.rawValue:
            self.player.playFromBeginning()
        case Player.PlaybackState.paused.rawValue:
            self.player.playFromCurrentTime()
        case Player.PlaybackState.playing.rawValue:
            self.player.pause()
        case Player.PlaybackState.failed.rawValue:
            self.player.pause()
        default:
            self.player.pause()
        }
    }
    
}

// MARK: - PlayerDelegate
    
extension PlayerController: PlayerDelegate {
    
    func playerReady(_ player: Player) {
    }
    
    func playerPlaybackStateDidChange(_ player: Player) {
    }
    
    func playerBufferingStateDidChange(_ player: Player) {
    }
    
    func playerBufferTimeDidChange(_ bufferTime: Double) {
    }
    
    func player(_ player: Player, didFailWithError error: Error?) {
    }

}

// MARK: - PlayerPlaybackDelegate

extension PlayerController: PlayerPlaybackDelegate {
    
    func playerCurrentTimeDidChange(_ player: Player) {
    }
    
    func playerPlaybackWillStartFromBeginning(_ player: Player) {
    }
    
    func playerPlaybackDidEnd(_ player: Player) {
    }
    
    func playerPlaybackWillLoop(_ player: Player) {
    }

    func playerPlaybackDidLoop(_ player: Player) {
    }
}
