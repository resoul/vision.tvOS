import UIKit
import FontManager

class MovieDetailBanner: UICollectionViewCell {
    
    private let coverBackgroundView = CoverBackgroundView()
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play", for: .normal)
        button.titleLabel?.font = UIFont.montserrat(.bold, size: 25)
        button.layer.cornerRadius = 10
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handlePlayButtonTapped), for: .primaryActionTriggered)
        
        return button
    }()
    
    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("More Info", for: .normal)
        button.titleLabel?.font = UIFont.montserrat(.regular, size: 21)
        button.layer.cornerRadius = 10
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handlePlayButtonTapped), for: .primaryActionTriggered)
        
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        coverBackgroundView.contentMode = .scaleAspectFill
        coverBackgroundView.clipsToBounds = true
        coverBackgroundView.frame = contentView.bounds
        coverBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView.addSubview(coverBackgroundView)
        contentView.addSubview(playButton)
        contentView.addSubview(infoButton)
        
        playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        infoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        playButton.constraints(top: nil, leading: contentView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 50, bottom: 0, right: 0), size: .init(width: 250, height: 50))
        infoButton.constraints(top: nil, leading: playButton.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 50, bottom: 0, right: 0), size: .init(width: 250, height: 50))
    }
    
    @objc
    private func handlePlayButtonTapped() {
        print("tapped")
    }

    func configure(image: String) {
        coverBackgroundView.backgroundImageURL = image
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [playButton]
    }
    
    override var canBecomeFocused: Bool {
        return false
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
