import UIKit

class YoutubeVideoCell: UICollectionViewCell {
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let channelLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(channelLabel)
        contentView.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor, multiplier: 9.0/16.0),
            
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            channelLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            channelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            channelLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            infoLabel.topAnchor.constraint(equalTo: channelLabel.bottomAnchor, constant: 5),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with video: YoutubeVideo) {
        titleLabel.text = video.title
        channelLabel.text = video.channel
        infoLabel.text = "\(video.views) просмотров · \(video.dateAdded)"
        thumbnailImageView.image = UIImage(named: video.thumbnailName)
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.thumbnailImageView.layer.borderWidth = 5.0
                self.thumbnailImageView.layer.borderColor = UIColor.white.cgColor
            } else {
                self.thumbnailImageView.layer.borderWidth = 0.0
            }
        }, completion: nil)
    }
}
