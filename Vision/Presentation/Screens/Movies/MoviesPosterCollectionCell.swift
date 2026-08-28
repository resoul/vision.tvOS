import UIKit

final class MoviesPosterCollectionCell: UICollectionViewCell {
    static let reuseID = "MoviesPosterCollectionCell"

    private let posterImageView = UIImageView()
    private let topGradientView = GradientView(
        colors: [
            UIColor.black.withAlphaComponent(0.45).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor
        ],
        locations: [0, 0.35, 1.0]
    )
    private let bottomGradientView = GradientView(
        colors: [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor
        ],
        locations: [0.5, 1.0]
    )

    private let providerBadgeView = BadgeView(
        text: "",
        background: UIColor(white: 0.15, alpha: 0.85),
        font: .systemFont(ofSize: 13, weight: .bold)
    )
    private let adsBadgeView = BadgeView(
        text: "ADS",
        background: UIColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 0.92),
        font: .systemFont(ofSize: 14, weight: .heavy)
    )
    private let seriesBadgeView = BadgeView(
        text: "SERIES",
        background: UIColor(red: 0.20, green: 0.50, blue: 0.90, alpha: 0.88),
        font: .systemFont(ofSize: 15, weight: .bold)
    )

    private var movie: ContentItem?

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous

        contentView.addSubviews(posterImageView, topGradientView, bottomGradientView, providerBadgeView, adsBadgeView, seriesBadgeView)

        providerBadgeView.translatesAutoresizingMaskIntoConstraints = false
        adsBadgeView.translatesAutoresizingMaskIntoConstraints = false
        seriesBadgeView.translatesAutoresizingMaskIntoConstraints = false

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        
        posterImageView.constraints(top: contentView.topAnchor, leading: contentView.leadingAnchor, bottom: contentView.bottomAnchor, trailing: contentView.trailingAnchor)
        topGradientView.constraints(top: contentView.topAnchor, leading: contentView.leadingAnchor, bottom: contentView.bottomAnchor, trailing: contentView.trailingAnchor)
        bottomGradientView.constraints(top: contentView.topAnchor, leading: contentView.leadingAnchor, bottom: contentView.bottomAnchor, trailing: contentView.trailingAnchor)

        NSLayoutConstraint.activate([
            providerBadgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            providerBadgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),

            adsBadgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            adsBadgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            seriesBadgeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            seriesBadgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])

        backgroundColor = UIColor(white: 0.2, alpha: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.cancelPoster()
        movie = nil
    }

    func configure(movie: ContentItem) {
        self.movie = movie
        adsBadgeView.isHidden = !movie.isAdIn
        seriesBadgeView.isHidden = !movie.type.isSeries

        if let provider = providerInfo(for: movie) {
            providerBadgeView.update(text: provider.title, background: provider.color)
            providerBadgeView.isHidden = false
        } else {
            providerBadgeView.isHidden = true
        }

        let placeholder = PlaceholderArt.generate(for: movie, size: CGSize(width: 440, height: 626))
        posterImageView.setPoster(url: movie.posterURL, placeholder: placeholder)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let willBeFocused = (context.nextFocusedView === self)
        coordinator.addCoordinatedAnimations {
            self.transform = willBeFocused ? CGAffineTransform(scaleX: 1.08, y: 1.08) : .identity
            self.backgroundColor = willBeFocused ? .systemBlue : UIColor(white: 0.20, alpha: 1.0)
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOpacity = willBeFocused ? 0.45 : 0.0
            self.layer.shadowRadius = willBeFocused ? 18 : 0
            self.layer.shadowOffset = willBeFocused ? CGSize(width: 0, height: 14) : .zero
            self.layer.borderWidth = willBeFocused ? 2 : 0
            self.layer.borderColor = UIColor.white.cgColor
        }
    }

    // MARK: - Private Helpers

    private func providerInfo(for item: ContentItem) -> (title: String, color: UIColor)? {
        let url = item.movieURL.lowercased()
        if url.contains("kinobase.org") {
            return ("KINOBASE", UIColor(red: 0.06, green: 0.72, blue: 0.50, alpha: 0.92))
        } else if url.contains("seasonvar.ru") {
            return ("SEASONVAR", UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 0.92))
        } else if url.contains("filmix") {
            return ("FILMIX", UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 0.92))
        }
        return nil
    }
}
