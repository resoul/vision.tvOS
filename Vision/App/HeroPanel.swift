import UIKit

final class HeroPanel: UIView {

    // MARK: - Background layers

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))

    private let accentGlow: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let accentGlowLayer = CAGradientLayer()

    private let accentLine: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
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

    // MARK: - Poster

    private let posterView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 14
        iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Right column

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 44, weight: .heavy)
        l.textColor = .white
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.72
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let metaStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Vertical stack of info rows — hidden rows collapse automatically
    private let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let translateRow  = HeroInfoRow()
    private let directorRow   = HeroInfoRow()
    private let actorsRow     = HeroInfoRow()
    private let lastAddedRow  = HeroInfoRow()
    private let descRow       = HeroInfoRow()

    // MARK: - Init

    override init(frame: CGRect) { super.init(frame: frame); build() }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func build() {
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        accentGlowLayer.type       = .radial
        accentGlowLayer.startPoint = CGPoint(x: 0, y: 0.5)
        accentGlowLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        accentGlow.layer.addSublayer(accentGlowLayer)

        let cv = blurView.contentView
        cv.addSubview(accentGlow)
        cv.addSubview(accentLine)
        cv.addSubview(posterView)
        cv.addSubview(titleLabel)
        cv.addSubview(metaStack)
        cv.addSubview(infoStack)
        cv.addSubview(separator)
        layer.addSublayer(bottomFade)

        let descDivider = ThinDividerView()
        infoStack.addArrangedSubview(translateRow)
        infoStack.addArrangedSubview(directorRow)
        infoStack.addArrangedSubview(actorsRow)
        infoStack.addArrangedSubview(lastAddedRow)
        infoStack.addArrangedSubview(descDivider)
        infoStack.addArrangedSubview(descRow)

        let inset: CGFloat = 72
        let pW: CGFloat    = 206
        let pH: CGFloat    = pW * 313 / 220

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentGlow.topAnchor.constraint(equalTo: cv.topAnchor),
            accentGlow.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            accentGlow.widthAnchor.constraint(equalToConstant: 540),
            accentGlow.bottomAnchor.constraint(equalTo: cv.bottomAnchor),

            // Accent stripe
            accentLine.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: inset),
            accentLine.centerYAnchor.constraint(equalTo: cv.centerYAnchor),
            accentLine.widthAnchor.constraint(equalToConstant: 4),
            accentLine.heightAnchor.constraint(equalToConstant: pH * 0.82),

            // Poster centered vertically
            posterView.leadingAnchor.constraint(equalTo: accentLine.trailingAnchor, constant: 22),
            posterView.centerYAnchor.constraint(equalTo: cv.centerYAnchor),
            posterView.widthAnchor.constraint(equalToConstant: pW),
            posterView.heightAnchor.constraint(equalToConstant: pH),

            // Title anchored near top with padding
            titleLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 48),
            titleLabel.topAnchor.constraint(equalTo: cv.topAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -inset),

            // Pills row
            metaStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),

            // Info stack fills remaining space
            infoStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoStack.topAnchor.constraint(equalTo: metaStack.bottomAnchor, constant: 18),
            infoStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            infoStack.bottomAnchor.constraint(lessThanOrEqualTo: cv.bottomAnchor, constant: -28),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        accentGlowLayer.frame = accentGlow.bounds
        bottomFade.frame = CGRect(x: 0, y: bounds.height - 80, width: bounds.width, height: 80)
    }

    // MARK: - Configure

    func configure(with movie: Movie) {
        titleLabel.text = movie.title

        let placeholder = PlaceholderArt.generate(for: movie, size: CGSize(width: 412, height: 586))
        posterView.setPoster(url: movie.posterURL, placeholder: placeholder)
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        metaStack.addArrangedSubview(MetaPill(
            text: "★ \(movie.rating)",
            color: UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)
        ))
        let yearText = movie.type.isSeries ? "\(movie.year)–" : movie.year
        if !movie.year.isEmpty && movie.year != "—" {
            metaStack.addArrangedSubview(MetaPill(text: yearText, color: UIColor(white: 0.35, alpha: 1)))
        }
        let genres = movie.genreList.isEmpty ? [movie.genre] : movie.genreList
        let genreAlphas: [CGFloat] = [0.90, 0.70, 0.55]
        for (i, g) in genres.prefix(3).enumerated() where !g.isEmpty && g != "—" {
            metaStack.addArrangedSubview(MetaPill(text: g, color: movie.accentColor.withAlphaComponent(genreAlphas[i])))
        }
        if case .series(let seasons) = movie.type {
            metaStack.addArrangedSubview(MetaPill(
                text: "\(seasons.count) сезонов",
                color: UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 0.85)
            ))
        } else if !movie.duration.isEmpty && movie.duration != "—" {
            metaStack.addArrangedSubview(MetaPill(text: movie.duration, color: UIColor(white: 0.25, alpha: 1)))
        }

        translateRow.set(key: "Перевод",    value: movie.translate)
        directorRow.set(key: "Режиссёр",    value: movie.directors.prefix(2).joined(separator: ", "))
        actorsRow.set(key: "В ролях",       value: movie.actors.prefix(4).joined(separator: ", "), lines: 2)
        lastAddedRow.set(key: "Добавлена",  value: movie.lastAdded ?? "")
        descRow.set(key: "Описание",        value: movie.description, lines: 3)

        accentLine.backgroundColor = movie.accentColor.lighter(by: 0.6)
        accentGlowLayer.colors = [
            movie.accentColor.withAlphaComponent(0.30).cgColor,
            movie.accentColor.withAlphaComponent(0.0).cgColor,
        ]
    }
}

private final class HeroInfoRow: UIView {

    private let keyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.42, alpha: 1)
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.74, alpha: 1)
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(keyLabel)
        addSubview(valueLabel)
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            keyLabel.firstBaselineAnchor.constraint(equalTo: valueLabel.firstBaselineAnchor),

            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 10),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func set(key: String, value: String, lines: Int = 1) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let empty   = trimmed.isEmpty || trimmed == "—"
        isHidden    = empty
        guard !empty else { return }
        keyLabel.text            = key + ":"
        valueLabel.text          = trimmed
        valueLabel.numberOfLines = lines
    }
}

private final class ThinDividerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.08)
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    required init?(coder: NSCoder) { fatalError() }
}
