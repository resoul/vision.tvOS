import UIKit

final class MovieCell: UICollectionViewCell {
    static let reuseID = "MovieCell"

    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 14
        iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let scrimLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        // Лёгкий скрим только сверху — для ранга и рейтинга
        l.colors = [
            UIColor.black.withAlphaComponent(0.45).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
        ]
        l.locations = [0, 0.35, 1.0]
        return l
    }()

    // Номер позиции — верхний левый угол
    private let rankLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        l.textColor = UIColor(white: 1, alpha: 0.50)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Рейтинг — верхний правый угол
    private let ratingPill: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 7
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let ratingLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Series badge — маленький, в правом нижнем углу
    private let seriesBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.88)
        v.layer.cornerRadius = 6
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let seriesBadgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        l.textColor = .white
        l.text = "SERIES"
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let focusBorderView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.cornerRadius = 14
        v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 3.5
        v.layer.borderColor = UIColor.white.cgColor
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let focusGlowLayer: CALayer = {
        let l = CALayer()
        l.cornerRadius = 14
        l.borderWidth = 1
        l.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        l.opacity = 0
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 14
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = false

        contentView.addSubview(posterImageView)
        contentView.layer.addSublayer(scrimLayer)
        contentView.layer.addSublayer(focusGlowLayer)
        contentView.addSubview(rankLabel)
        contentView.addSubview(ratingPill)
        ratingPill.addSubview(ratingLabel)
        contentView.addSubview(seriesBadge)
        seriesBadge.addSubview(seriesBadgeLabel)
        contentView.addSubview(focusBorderView)

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Ранг — верх лево
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            rankLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            // Рейтинг — верх право
            ratingPill.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            ratingPill.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            ratingPill.heightAnchor.constraint(equalToConstant: 28),
            ratingLabel.leadingAnchor.constraint(equalTo: ratingPill.leadingAnchor, constant: 7),
            ratingLabel.trailingAnchor.constraint(equalTo: ratingPill.trailingAnchor, constant: -7),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingPill.centerYAnchor),

            // Series badge — низ право
            seriesBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            seriesBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            seriesBadgeLabel.leadingAnchor.constraint(equalTo: seriesBadge.leadingAnchor, constant: 7),
            seriesBadgeLabel.trailingAnchor.constraint(equalTo: seriesBadge.trailingAnchor, constant: -7),
            seriesBadgeLabel.topAnchor.constraint(equalTo: seriesBadge.topAnchor, constant: 4),
            seriesBadgeLabel.bottomAnchor.constraint(equalTo: seriesBadge.bottomAnchor, constant: -4),

            focusBorderView.topAnchor.constraint(equalTo: contentView.topAnchor),
            focusBorderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            focusBorderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            focusBorderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius  = 14
        layer.shadowOffset  = CGSize(width: 0, height: 10)
    }
    required init?(coder: NSCoder) { fatalError() }


    override func layoutSubviews() {
        super.layoutSubviews()
        scrimLayer.frame = contentView.bounds
        focusGlowLayer.frame = contentView.bounds.insetBy(dx: 1, dy: 1)
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 14).cgPath
        scrimLayer.mask = mask
    }

    // MARK: - Configure

    func configure(with movie: Movie, rank: Int) {
        rankLabel.text  = "#\(rank)"
        ratingLabel.text = "★ \(movie.rating)"
        ratingPill.backgroundColor = movie.accentColor.lighter(by: 0.5)

        if case .series = movie.type {
            seriesBadge.isHidden = false
        } else {
            seriesBadge.isHidden = true
        }

        let placeholder = PlaceholderArt.generate(for: movie, size: CGSize(width: 440, height: 626))
        posterImageView.setPoster(url: movie.posterURL, placeholder: placeholder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.cancelPoster()
    }

    // MARK: - Focus

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.09, y: 1.09)
                self.layer.shadowOpacity = 0.9
                self.layer.shadowRadius  = 32
                self.layer.shadowOffset  = CGSize(width: 0, height: 22)
                self.focusBorderView.alpha  = 1
                self.focusGlowLayer.opacity = 1
            } else {
                self.transform = .identity
                self.layer.shadowOpacity = 0.45
                self.layer.shadowRadius  = 14
                self.layer.shadowOffset  = CGSize(width: 0, height: 10)
                self.focusBorderView.alpha  = 0
                self.focusGlowLayer.opacity = 0
            }
        }, completion: nil)
    }
}

// MARK: - ContentType helper

extension Movie.ContentType {
    var isSeries: Bool {
        if case .series = self { return true }
        return false
    }
}
