import UIKit

final class HeroPanel: UIView {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))

    private let accentGlow: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let accentGlowLayer = CAGradientLayer()

    private let accentLine: UIView = {
        let v = UIView(); v.layer.cornerRadius = 2; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let posterView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 46, weight: .heavy)
        l.textColor = .white
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let metaStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal; sv.spacing = 8; sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let translateLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .medium)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let directorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        l.textColor = UIColor(white: 0.60, alpha: 1)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let actorsLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        l.textColor = UIColor(white: 0.55, alpha: 1)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        l.textColor = UIColor(white: 0.78, alpha: 1)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.10)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let bottomFade: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor]
        l.locations = [0.7, 1.0]
        return l
    }()

    override init(frame: CGRect) { super.init(frame: frame); build() }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        accentGlowLayer.type = .radial
        accentGlowLayer.startPoint = CGPoint(x: 0, y: 0.5)
        accentGlowLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        accentGlow.layer.addSublayer(accentGlowLayer)

        let cv = blurView.contentView
        cv.addSubview(accentGlow)
        cv.addSubview(accentLine)
        cv.addSubview(posterView)
        cv.addSubview(titleLabel)
        cv.addSubview(metaStack)
        cv.addSubview(translateLabel)
        cv.addSubview(directorLabel)
        cv.addSubview(actorsLabel)
        cv.addSubview(descLabel)
        cv.addSubview(separator)
        layer.addSublayer(bottomFade)

        let inset: CGFloat = 72
        let pW: CGFloat    = 186
        let pH             = pW * 313 / 220

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentGlow.topAnchor.constraint(equalTo: cv.topAnchor),
            accentGlow.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            accentGlow.widthAnchor.constraint(equalToConstant: 500),
            accentGlow.bottomAnchor.constraint(equalTo: cv.bottomAnchor),

            accentLine.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: inset),
            accentLine.centerYAnchor.constraint(equalTo: cv.centerYAnchor),
            accentLine.widthAnchor.constraint(equalToConstant: 4),
            accentLine.heightAnchor.constraint(equalToConstant: pH * 0.75),

            posterView.leadingAnchor.constraint(equalTo: accentLine.trailingAnchor, constant: 20),
            posterView.centerYAnchor.constraint(equalTo: cv.centerYAnchor),
            posterView.widthAnchor.constraint(equalToConstant: pW),
            posterView.heightAnchor.constraint(equalToConstant: pH),

            titleLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 44),
            titleLabel.topAnchor.constraint(equalTo: posterView.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -inset),

            metaStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),

            translateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            translateLabel.topAnchor.constraint(equalTo: metaStack.bottomAnchor, constant: 10),

            directorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            directorLabel.topAnchor.constraint(equalTo: translateLabel.bottomAnchor, constant: 6),
            directorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            actorsLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            actorsLabel.topAnchor.constraint(equalTo: directorLabel.bottomAnchor, constant: 6),
            actorsLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: actorsLabel.bottomAnchor, constant: 10),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        accentGlowLayer.frame = accentGlow.bounds
        bottomFade.frame = CGRect(x: 0, y: bounds.height - 60, width: bounds.width, height: 60)
    }

    // MARK: - Configure

    func configure(with movie: Movie) {
        titleLabel.text  = movie.title
        descLabel.text   = movie.description

        let placeholder = PlaceholderArt.generate(for: movie, size: CGSize(width: 372, height: 530))
        posterView.setPoster(url: movie.posterURL, placeholder: placeholder)
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        metaStack.addArrangedSubview(MetaPill(
            text: "★ \(movie.rating)",
            color: UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)
        ))

        let yearText = movie.type.isSeries ? "\(movie.year)–" : movie.year
        if !movie.year.isEmpty && movie.year != "—" {
            metaStack.addArrangedSubview(MetaPill(
                text: yearText,
                color: UIColor(white: 0.35, alpha: 1)
            ))
        }

        let genres = movie.genreList.isEmpty ? [movie.genre] : movie.genreList
        let genreColors: [UIColor] = [
            movie.accentColor.withAlphaComponent(0.90),
            movie.accentColor.withAlphaComponent(0.70),
            movie.accentColor.withAlphaComponent(0.55),
        ]
        for (i, g) in genres.prefix(3).enumerated() where !g.isEmpty && g != "—" {
            metaStack.addArrangedSubview(MetaPill(text: g, color: genreColors[i]))
        }

        if case .series(let seasons) = movie.type {
            metaStack.addArrangedSubview(MetaPill(
                text: "\(seasons.count) Seasons",
                color: UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.85)
            ))
        } else if !movie.duration.isEmpty && movie.duration != "—" {
            metaStack.addArrangedSubview(MetaPill(
                text: movie.duration,
                color: UIColor(white: 0.25, alpha: 1)
            ))
        }
        
        translateLabel.text = movie.translate
        if movie.directors.isEmpty {
            directorLabel.isHidden = true
        } else {
            directorLabel.isHidden = false
            let names = movie.directors.prefix(2).joined(separator: ", ")
            directorLabel.attributedText = labeled("Режиссёр:", value: names)
        }

        if movie.actors.isEmpty {
            actorsLabel.isHidden = true
        } else {
            actorsLabel.isHidden = false
            let names = movie.actors.prefix(4).joined(separator: ", ")
            actorsLabel.attributedText = labeled("В ролях:", value: names)
        }

        accentLine.backgroundColor = movie.accentColor.lighter(by: 0.6)
        accentGlowLayer.colors = [
            movie.accentColor.withAlphaComponent(0.28).cgColor,
            movie.accentColor.withAlphaComponent(0.0).cgColor,
        ]
    }

    // MARK: - Helpers

    private func labeled(_ key: String, value: String) -> NSAttributedString {
        let s = NSMutableAttributedString(
            string: key + "  ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 21, weight: .semibold),
                .foregroundColor: UIColor(white: 0.45, alpha: 1),
            ]
        )
        s.append(NSAttributedString(
            string: value,
            attributes: [
                .font: UIFont.systemFont(ofSize: 21, weight: .regular),
                .foregroundColor: UIColor(white: 0.70, alpha: 1),
            ]
        ))
        return s
    }
}
