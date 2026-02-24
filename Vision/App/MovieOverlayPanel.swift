import UIKit

final class MovieOverlayPanel: UIView {

    static let shared = MovieOverlayPanel()

    // MARK: - Constants
    private let panelOffset: CGFloat = 16

    private var cellSize: CGSize = .zero
    private var panelWidth:  CGFloat { cellSize.width * 2.5 + 28 }
    private var panelHeight: CGFloat { cellSize.height * 0.5 }
    
    // MARK: - Subviews

    private let blurView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let accentLine: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        l.textColor = .white
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.75
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let pillsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 6
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.65, alpha: 1)
        l.numberOfLines = 5
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let lastAddedLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.numberOfLines = 1
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - State
    private var showTimer: Timer?
    private var currentMovieId: Int?

    // MARK: - Init

    private init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 500, height: 300))
        // Must use frame-based layout for window positioning — do NOT set translatesAutoresizingMaskIntoConstraints = false
        alpha = 0
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 12)
        clipsToBounds = false

        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func build() {
        blurView.layer.cornerRadius = 16
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        addSubview(blurView)

        let cv = blurView.contentView
        cv.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 0.88)
        cv.addSubview(accentLine)
        cv.addSubview(titleLabel)
        cv.addSubview(pillsStack)
        cv.addSubview(infoStack)

        infoStack.addArrangedSubview(descLabel)
        infoStack.addArrangedSubview(lastAddedLabel)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentLine.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 20),
            accentLine.topAnchor.constraint(equalTo: cv.topAnchor, constant: 22),
            accentLine.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -22),
            accentLine.widthAnchor.constraint(equalToConstant: 4),

            titleLabel.leadingAnchor.constraint(equalTo: accentLine.trailingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: cv.topAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -20),

            pillsStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            pillsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            pillsStack.trailingAnchor.constraint(lessThanOrEqualTo: cv.trailingAnchor, constant: -20),

            infoStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoStack.topAnchor.constraint(equalTo: pillsStack.bottomAnchor, constant: 14),
            infoStack.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -20),
            infoStack.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -24),
        ])
    }

    // MARK: - Public API

    func show(for movie: Movie, cellSize: CGSize, delay: TimeInterval = 0.15) {
        guard movie.id != currentMovieId else { return }
        self.cellSize = cellSize
        currentMovieId = movie.id

        showTimer?.invalidate()
        showTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.configure(with: movie)
            self.position()
            self.animateIn()
        }
    }

    func hide(animated: Bool = true) {
        showTimer?.invalidate()
        currentMovieId = nil
        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseIn) {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }
        } else {
            alpha = 0
            transform = .identity
        }
    }

    /// Attach to window if not already added
    func attachToWindow(_ window: UIWindow) {
        guard superview == nil else { return }
        window.addSubview(self)
    }

    // MARK: - Private

    private func configure(with movie: Movie) {
        titleLabel.text = movie.title
        accentLine.backgroundColor = movie.accentColor.lighter(by: 0.55)

        pillsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pillsStack.addArrangedSubview(SmallPill(
            text: "★ \(movie.rating)",
            color: UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)
        ))
        if !movie.year.isEmpty && movie.year != "—" {
            pillsStack.addArrangedSubview(SmallPill(text: movie.year, color: UIColor(white: 0.28, alpha: 1)))
        }
        let genres = movie.genreList.isEmpty ? [movie.genre] : movie.genreList
        for g in genres.prefix(2) where !g.isEmpty && g != "—" {
            pillsStack.addArrangedSubview(SmallPill(
                text: g,
                color: movie.accentColor.withAlphaComponent(0.80)
            ))
        }

        descLabel.text = movie.description.isEmpty ? nil : movie.description
        descLabel.isHidden = movie.description.isEmpty

        if let last = movie.lastAdded, !last.isEmpty {
            lastAddedLabel.text = "▸ \(last)"
            lastAddedLabel.isHidden = false
        } else {
            lastAddedLabel.isHidden = true
        }

        frame.size = CGSize(width: cellSize.width * 2.5 + 28, height: cellSize.height * 0.5)
    }

    private func position() {
        let rightPadding: CGFloat = 30
        let bottomPadding: CGFloat = 15
        
        let x = UIScreen.main.bounds.width - panelWidth - rightPadding
        let y = UIScreen.main.bounds.height - panelHeight - bottomPadding
        
        frame.origin = CGPoint(x: x, y: y)
    }

    private func animateIn() {
        transform = CGAffineTransform(scaleX: 0.96, y: 0.96)

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0.3
        ) {
            self.alpha = 1
            self.transform = .identity
        }
    }
}
