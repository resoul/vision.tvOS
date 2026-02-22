import UIKit

final class MainController: UIViewController {
    private var movies: [Movie] = []
    private var currentFocusedMovieId: Int? = nil
    private var detailDebounceTimer: Timer?
    private var pendingMovie: Movie?

    private var nextPageURL: URL? = nil
    private var isFetching = false
    private var hasLoadedFirstPage = false

    private lazy var backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.alpha = 0
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let vignetteLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.type = .radial
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.70).cgColor]
        l.startPoint = CGPoint(x: 0.5, y: 0.5)
        l.endPoint   = CGPoint(x: 1.0, y: 1.0)
        return l
    }()

    private let baseGradientLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.colors = [
            UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1).cgColor,
        ]
        return l
    }()

    private lazy var logoLabel: UILabel = {
        let l = UILabel()
        l.attributedText = NSAttributedString(string: "FILMIX", attributes: [
            .kern: CGFloat(8),
            .font: UIFont.systemFont(ofSize: 38, weight: .heavy),
            .foregroundColor: UIColor.white,
        ])
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let logoAccentDot: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var sectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Popular"
        l.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        l.textColor = UIColor(white: 0.65, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let headerSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var heroPanel: HeroPanel = {
        let p = HeroPanel()
        p.alpha = 0
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()

    private lazy var heroPanelHeightConstraint = heroPanel.heightAnchor.constraint(equalToConstant: 0)
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeFlowLayout())
        cv.backgroundColor = .clear
        cv.remembersLastFocusedIndexPath = true
        cv.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseID)
        cv.register(LoadingFooterView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    withReuseIdentifier: LoadingFooterView.reuseID)
        cv.dataSource = self
        cv.delegate   = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = .white
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.6, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 3
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var retryButton: DetailButton = {
        let b = DetailButton(title: "↻  Retry", style: .secondary)
        b.isHidden = true
        b.addTarget(self, action: #selector(retryTapped), for: .primaryActionTriggered)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.insertSublayer(baseGradientLayer, at: 0)
        view.addSubview(backdropImageView)
        view.layer.addSublayer(vignetteLayer)
        view.addSubview(backdropBlur)
        view.addSubview(logoLabel)
        view.addSubview(logoAccentDot)
        view.addSubview(sectionLabel)
        view.addSubview(headerSeparator)
        view.addSubview(heroPanel)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)

        heroPanelHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            logoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 52),
            logoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),

            logoAccentDot.widthAnchor.constraint(equalToConstant: 10),
            logoAccentDot.heightAnchor.constraint(equalToConstant: 10),
            logoAccentDot.leadingAnchor.constraint(equalTo: logoLabel.trailingAnchor, constant: 4),
            logoAccentDot.bottomAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: -6),

            sectionLabel.centerYAnchor.constraint(equalTo: logoLabel.centerYAnchor),
            sectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),

            headerSeparator.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 18),
            headerSeparator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 80),
            headerSeparator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1),

            heroPanel.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor, constant: 16),
            heroPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroPanelHeightConstraint,

            collectionView.topAnchor.constraint(equalTo: heroPanel.bottomAnchor, constant: 60),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            errorLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),

            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
        ])

        loadFirstPage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baseGradientLayer.frame = view.bounds
        vignetteLayer.frame     = view.bounds
    }

    // MARK: - Networking

    private func loadFirstPage() {
        guard !isFetching else { return }
        isFetching = true
        errorLabel.isHidden  = true
        retryButton.isHidden = true
        loadingIndicator.startAnimating()

        FilmixService.shared.fetchPage(url: nil) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isFetching = false
                self.loadingIndicator.stopAnimating()
                self.hasLoadedFirstPage = true

                switch result {
                case .success(let page):
                    self.nextPageURL = page.nextPageURL
                    self.movies = page.movies
                    self.collectionView.reloadData()
                    // После reloadData обновляем hero для текущего фокуса если он есть
                    self.refreshHeroForCurrentFocus()

                case .failure(let error):
                    self.errorLabel.text = "Failed to load\n\(error.localizedDescription)"
                    self.errorLabel.isHidden  = false
                    self.retryButton.isHidden = false
                }
            }
        }
    }

    private func loadNextPage() {
        guard !isFetching, let url = nextPageURL else { return }
        isFetching = true

        FilmixService.shared.fetchPage(url: url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isFetching = false

                switch result {
                case .success(let page):
                    let startIndex = self.movies.count
                    self.nextPageURL = page.nextPageURL
                    self.movies.append(contentsOf: page.movies)

                    let indexPaths = (startIndex ..< self.movies.count)
                        .map { IndexPath(item: $0, section: 0) }
                    self.collectionView.performBatchUpdates {
                        self.collectionView.insertItems(at: indexPaths)
                    }

                    if self.nextPageURL == nil {
                        self.collectionView.reloadData()
                    }

                    self.refreshHeroForCurrentFocus()

                case .failure:
                    break
                }
            }
        }
    }

    @objc private func retryTapped() {
        loadFirstPage()
    }

    // MARK: - Layout helpers

    private func makeFlowLayout() -> UICollectionViewFlowLayout {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection         = .vertical
        l.minimumInteritemSpacing = 28
        l.minimumLineSpacing      = 44
        l.sectionInset = UIEdgeInsets(top: 0, left: 80, bottom: 80, right: 80)
        l.footerReferenceSize = CGSize(width: 0, height: 80)
        return l
    }

    private func cellSize() -> CGSize {
        let width             = view.bounds.width
        let horizontalPadding = 80.0 * 2
        let spacing           = 28.0 * 4
        let w = floor((width - horizontalPadding - spacing) / 5)
        let h = floor(w * 313 / 220)
        return CGSize(width: w, height: h)
    }

    // MARK: - Hero Panel

    private func showHeroPanel(for movie: Movie) {
        heroPanel.configure(with: movie)
        UIView.transition(with: backdropImageView, duration: 0.55, options: .transitionCrossDissolve) {
            self.backdropImageView.image = PlaceholderArt.generate(for: movie, size: CGSize(width: 1920, height: 1080))
        }
        if heroPanel.alpha < 0.5 {
            heroPanelHeightConstraint.constant = 290
            heroPanel.transform = CGAffineTransform(translationX: 0, y: -20)
            UIView.animate(withDuration: 0.40, delay: 0, options: .curveEaseOut) {
                self.heroPanel.alpha     = 1
                self.heroPanel.transform = .identity
                self.backdropImageView.alpha = 0.22
                self.backdropBlur.alpha      = 0.60
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(withDuration: 0.20) { self.heroPanel.alpha = 1 }
        }
    }

    private func hideHeroPanel() {
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseIn) {
            self.heroPanel.alpha     = 0
            self.heroPanel.transform = CGAffineTransform(translationX: 0, y: -10)
            self.backdropImageView.alpha = 0
            self.backdropBlur.alpha      = 0
            self.heroPanelHeightConstraint.constant = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.heroPanel.transform = .identity
        }
    }

    private func refreshHeroForCurrentFocus() {
        guard let focusedId = currentFocusedMovieId,
              let movie = movies.first(where: { $0.id == focusedId })
        else { return }
        showHeroPanel(for: movie)
    }

    // MARK: - Focus

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        if let cell = context.nextFocusedItem as? MovieCell,
           let ip   = collectionView.indexPath(for: cell) {
            let movie = movies[ip.item]
            guard movie.id != currentFocusedMovieId else { return }
            currentFocusedMovieId = movie.id
            detailDebounceTimer?.invalidate()
            pendingMovie = movie
            detailDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: false) { [weak self] _ in
                guard let self, let m = self.pendingMovie else { return }
                self.showHeroPanel(for: m)
            }
        } else if !(context.nextFocusedItem is MovieCell) {
            detailDebounceTimer?.invalidate()
            pendingMovie          = nil
            currentFocusedMovieId = nil
            hideHeroPanel()
        }
    }
}

extension MainController: UICollectionViewDataSource {

    func collectionView(_ cv: UICollectionView,
                        numberOfItemsInSection s: Int) -> Int {
        movies.count
    }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseID,
                                          for: ip) as! MovieCell
        cell.configure(with: movies[ip.item], rank: ip.item + 1)
        return cell
    }

    func collectionView(_ cv: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at ip: IndexPath) -> UICollectionReusableView {
        let footer = cv.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: LoadingFooterView.reuseID,
            for: ip) as! LoadingFooterView
        footer.setAnimating(isFetching && nextPageURL != nil)
        return footer
    }
}

extension MainController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        present(MovieDetailViewController(movie: movies[ip.item]), animated: true)
    }

    func collectionView(_ cv: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt ip: IndexPath) {
        let threshold = max(0, movies.count - 10)
        if ip.item >= threshold {
            loadNextPage()
        }
    }
}

extension MainController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize {
        cellSize()
    }

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        nextPageURL != nil
            ? CGSize(width: cv.bounds.width, height: 80)
            : .zero
    }
}
