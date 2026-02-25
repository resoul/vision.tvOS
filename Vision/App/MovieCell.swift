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
        l.colors = [
            UIColor.black.withAlphaComponent(0.45).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
        ]
        l.locations = [0, 0.35, 1.0]
        return l
    }()

    private let bottomScrimLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
        ]
        l.locations = [0.5, 1.0]
        return l
    }()

    private let adsBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 0.92)
        v.layer.cornerRadius = 6
        v.layer.cornerCurve = .continuous
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let adsLabel: UILabel = {
        let l = UILabel()
        l.text = "ADS"
        l.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

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

    private let inProgressBadge: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.10, green: 0.72, blue: 0.45, alpha: 0.92)
        v.layer.cornerRadius = 6
        v.layer.cornerCurve = .continuous
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let inProgressLabel: UILabel = {
        let l = UILabel()
        l.text = "В ПРОЦЕССЕ"
        l.font = UIFont.systemFont(ofSize: 13, weight: .heavy)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let progressTrack: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.20)
        v.layer.cornerRadius = 2
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private let progressFill: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.23, green: 0.62, blue: 0.96, alpha: 1)
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private var progressFillWidthConstraint: NSLayoutConstraint!

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
        contentView.layer.addSublayer(bottomScrimLayer)
        contentView.layer.addSublayer(focusGlowLayer)

        contentView.addSubview(adsBadge)
        adsBadge.addSubview(adsLabel)
        contentView.addSubview(seriesBadge)
        seriesBadge.addSubview(seriesBadgeLabel)
        contentView.addSubview(inProgressBadge)
        inProgressBadge.addSubview(inProgressLabel)
        contentView.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)
        contentView.addSubview(focusBorderView)

        progressFillWidthConstraint = progressFill.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            adsBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            adsBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            adsLabel.leadingAnchor.constraint(equalTo: adsBadge.leadingAnchor, constant: 6),
            adsLabel.trailingAnchor.constraint(equalTo: adsBadge.trailingAnchor, constant: -6),
            adsLabel.topAnchor.constraint(equalTo: adsBadge.topAnchor, constant: 4),
            adsLabel.bottomAnchor.constraint(equalTo: adsBadge.bottomAnchor, constant: -4),
            seriesBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            seriesBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            seriesBadgeLabel.leadingAnchor.constraint(equalTo: seriesBadge.leadingAnchor, constant: 7),
            seriesBadgeLabel.trailingAnchor.constraint(equalTo: seriesBadge.trailingAnchor, constant: -7),
            seriesBadgeLabel.topAnchor.constraint(equalTo: seriesBadge.topAnchor, constant: 4),
            seriesBadgeLabel.bottomAnchor.constraint(equalTo: seriesBadge.bottomAnchor, constant: -4),
            inProgressBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            inProgressBadge.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            inProgressLabel.leadingAnchor.constraint(equalTo: inProgressBadge.leadingAnchor, constant: 7),
            inProgressLabel.trailingAnchor.constraint(equalTo: inProgressBadge.trailingAnchor, constant: -7),
            inProgressLabel.topAnchor.constraint(equalTo: inProgressBadge.topAnchor, constant: 4),
            inProgressLabel.bottomAnchor.constraint(equalTo: inProgressBadge.bottomAnchor, constant: -4),
            progressTrack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            progressTrack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            progressTrack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            progressTrack.heightAnchor.constraint(equalToConstant: 4),
            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFillWidthConstraint,
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
        bottomScrimLayer.frame = contentView.bounds
        focusGlowLayer.frame = contentView.bounds.insetBy(dx: 1, dy: 1)
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 14).cgPath
        scrimLayer.mask = mask
        let mask2 = CAShapeLayer()
        mask2.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 14).cgPath
        bottomScrimLayer.mask = mask2
    }

    // MARK: - Configure

    func configure(with movie: Movie) {
        adsBadge.isHidden = !movie.isAdIn

        let isSeries = movie.type.isSeries
        seriesBadge.isHidden = !isSeries

        if !isSeries {
            if let progress = PlaybackStore.shared.movieProgress(movieId: movie.id),
               progress.hasProgress {
                showProgress(fraction: progress.fraction)
            } else {
                hideProgress()
            }
            inProgressBadge.isHidden = true
        } else {
            hideProgress()
            let inProgress = WatchHistoryStore.shared.isSeriesInProgress(movieId: movie.id)
            inProgressBadge.isHidden = !inProgress
        }

        let placeholder = PlaceholderArt.generate(for: movie, size: CGSize(width: 440, height: 626))
        posterImageView.setPoster(url: movie.posterURL, placeholder: placeholder)
    }

    private func showProgress(fraction: Double) {
        progressTrack.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
        let maxW = progressTrack.bounds.width
        guard maxW > 0 else {
            progressFillWidthConstraint.constant = 0
            return
        }
        progressFillWidthConstraint.constant = maxW * CGFloat(min(max(fraction, 0), 1))
    }

    private func hideProgress() {
        progressTrack.isHidden = true
        progressFillWidthConstraint.constant = 0
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.cancelPoster()
        hideProgress()
        inProgressBadge.isHidden = true
        seriesBadge.isHidden = true
        adsBadge.isHidden = true
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
