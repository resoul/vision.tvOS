import UIKit

class YoutubeStoryCell: UICollectionViewCell {
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true // Важно для скругления
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        
        titleLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor),
            thumbnailImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            
            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Настройка скругления и бордера
    override func layoutSubviews() {
        super.layoutSubviews()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.bounds.width / 2
    }
    
    func configure(with story: YoutubeStory) {
        titleLabel.text = story.title
        thumbnailImageView.image = UIImage(named: story.thumbnailName)
        
        if story.isNew {
            thumbnailImageView.layer.borderColor = UIColor.red.cgColor
            thumbnailImageView.layer.borderWidth = 3
        } else {
            thumbnailImageView.layer.borderColor = nil
            thumbnailImageView.layer.borderWidth = 0
        }
    }
    
    // MARK: - Эффект наведения
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.thumbnailImageView.layer.borderColor = UIColor.white.cgColor
                self.thumbnailImageView.layer.borderWidth = 3
                self.titleLabel.textColor = .white
            } else {
//                let story =  Как получить данные?
                // Это проблема, так как ячейка не знает своих данных
                // Мы будем использовать isNew
//                self.configure(with: story) // Эта строка вызовет ошибку, так как story не определена
                // Лучше хранить isNew в ячейке или просто сбросить бордер
                self.thumbnailImageView.layer.borderWidth = 0
                self.titleLabel.textColor = .lightGray
            }
        }, completion: nil)
    }
    
    // Обновленная didUpdateFocus для корректного сброса
    func updateFocusBorder(isFocused: Bool, isNew: Bool) {
        if isFocused {
            thumbnailImageView.layer.borderColor = UIColor.white.cgColor
            thumbnailImageView.layer.borderWidth = 3
        } else {
            if isNew {
                thumbnailImageView.layer.borderColor = UIColor.red.cgColor
                thumbnailImageView.layer.borderWidth = 3
            } else {
                thumbnailImageView.layer.borderWidth = 0
            }
        }
    }
}
