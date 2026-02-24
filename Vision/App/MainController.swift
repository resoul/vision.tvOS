import UIKit

final class MainController: UIViewController {
    private var movies: [Movie] = []
    private var currentFocusedMovieId: Int? = nil

    private var nextPageURL: URL? = nil
    private var isFetching = false
    private var hasLoadedFirstPage = false
    private var currentCategoryURL: String? = nil
    private var isFavoritesTab = false
    private var tabBarHeightConstraint: NSLayoutConstraint!

    // MARK: - Background

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

    // MARK: - Category Tab Bar

    private lazy var categoryTabBar: CategoryTabBar = {
        let bar = CategoryTabBar()
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    // MARK: - Collection View

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: makeFlowLayout())
        cv.backgroundColor = .clear
        cv.contentInsetAdjustmentBehavior = .never
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

    // MARK: - Empty favorites

    private lazy var emptyFavoritesLabel: UILabel = {
        let l = UILabel()
        l.text = "Нет избранных фильмов\nНажмите «+ Добавить в избранное» на странице фильма"
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.4, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Loading / Error views

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
        additionalSafeAreaInsets = .zero

        view.layer.insertSublayer(baseGradientLayer, at: 0)
        view.addSubview(backdropImageView)
        view.layer.addSublayer(vignetteLayer)
        view.addSubview(backdropBlur)
        view.addSubview(categoryTabBar)
        view.addSubview(collectionView)
        view.addSubview(emptyFavoritesLabel)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)

        NSLayoutConstraint.activate([
            backdropImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            categoryTabBar.topAnchor.constraint(equalTo: view.topAnchor),
            categoryTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
           
            {
                let c = categoryTabBar.heightAnchor.constraint(equalToConstant: CategoryTabBar.collapsedHeight)
                tabBarHeightConstraint = c
                return c
            }(),

            // CollectionView теперь занимает всё пространство под табом
            collectionView.topAnchor.constraint(equalTo: categoryTabBar.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyFavoritesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyFavoritesLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyFavoritesLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.55),

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Attach overlay to window once we have one
        if let window = view.window {
            MovieOverlayPanel.shared.attachToWindow(window)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baseGradientLayer.frame = view.bounds
        vignetteLayer.frame     = view.bounds
    }

    // MARK: - Networking

    private func loadFirstPage() {
        if isFavoritesTab {
            loadFavorites()
            return
        }

        guard !isFetching else { return }
        isFetching = true
        errorLabel.isHidden  = true
        retryButton.isHidden = true
        loadingIndicator.startAnimating()

        let url = currentCategoryURL.flatMap { URL(string: $0) }

        FilmixService.shared.fetchPage(url: url) { [weak self] result in
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
                    self.focusFirstCell()

                case .failure(let error):
                    self.errorLabel.text = "Failed to load\n\(error.localizedDescription)"
                    self.errorLabel.isHidden  = false
                    self.retryButton.isHidden = false
                }
            }
        }
    }

    private func loadFavorites() {
        hasLoadedFirstPage = true
        movies = FavoritesStore.shared.all()
        collectionView.reloadData()
        emptyFavoritesLabel.isHidden = !movies.isEmpty
        focusFirstCell()
    }

    private func loadNextPage() {
        guard !isFetching, !isFavoritesTab, let url = nextPageURL else { return }
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

                case .failure:
                    break
                }
            }
        }
    }

    private func switchCategory(url: String?, isFavorites: Bool = false) {
        guard url != currentCategoryURL || isFavorites != isFavoritesTab else { return }
        currentCategoryURL = url
        isFavoritesTab = isFavorites

        movies = []
        nextPageURL = nil
        currentFocusedMovieId = nil
        hasLoadedFirstPage = false
        emptyFavoritesLabel.isHidden = true
        collectionView.reloadData()
        MovieOverlayPanel.shared.hide(animated: false)

        if collectionView.numberOfItems(inSection: 0) > 0 {
            collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        }

        loadFirstPage()
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
        l.sectionInset = UIEdgeInsets(top: 30, left: 80, bottom: 80, right: 80)
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

    // MARK: - Focus helpers

    private var preferredFocusCell: UICollectionViewCell? = nil

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let cell = preferredFocusCell {
            return [cell]
        }
        return super.preferredFocusEnvironments
    }

    private func focusFirstCell() {
        guard !movies.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            let ip = IndexPath(item: 0, section: 0)
            guard let cell = self.collectionView.cellForItem(at: ip) else { return }
            self.preferredFocusCell = cell
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
            self.preferredFocusCell = nil

            // Show overlay for first cell
            let movie = self.movies[0]
            self.currentFocusedMovieId = movie.id
            MovieOverlayPanel.shared.show(
                for: movie,
                cellSize: cellSize(),
                delay: 0
            )
        }
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

            MovieOverlayPanel.shared.show(for: movie, cellSize: cellSize())
        } else if !(context.nextFocusedItem is MovieCell) {
            currentFocusedMovieId = nil
            MovieOverlayPanel.shared.hide()
        }
    }
}

// MARK: - CategoryTabBarDelegate

extension MainController: CategoryTabBarDelegate {
    func categoryTabBarDidSelectSettings(_ bar: CategoryTabBar) {
        MovieOverlayPanel.shared.hide(animated: false)
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .overFullScreen
        settingsVC.modalTransitionStyle   = .crossDissolve
        present(settingsVC, animated: true)
    }
    
    func categoryTabBar(_ bar: CategoryTabBar, didSelect category: FilmixCategory) {
        updateTabBarHeight(hasGenres: !category.genres.isEmpty)
        if category.isFavorites {
            switchCategory(url: nil, isFavorites: true)
        } else {
            switchCategory(url: category.url)
        }
    }

    func categoryTabBar(_ bar: CategoryTabBar, didSelectGenre genre: FilmixGenre, in category: FilmixCategory) {
        switchCategory(url: genre.url)
    }

    func categoryTabBarDidSelectSearch(_ bar: CategoryTabBar) {
        MovieOverlayPanel.shared.hide(animated: false)
        let searchVC = SearchViewController()
        searchVC.modalPresentationStyle = .overFullScreen
        searchVC.modalTransitionStyle   = .crossDissolve
        present(searchVC, animated: true)
    }

    private func updateTabBarHeight(hasGenres: Bool) {
        let target = hasGenres
            ? CategoryTabBar.expandedHeight
            : CategoryTabBar.collapsedHeight
        guard tabBarHeightConstraint.constant != target else { return }
        tabBarHeightConstraint.constant = target
        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MainController: UICollectionViewDataSource {

    func collectionView(_ cv: UICollectionView,
                        numberOfItemsInSection s: Int) -> Int {
        movies.count
    }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseID,
                                          for: ip) as! MovieCell
        cell.configure(with: movies[ip.item])
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

// MARK: - UICollectionViewDelegate

extension MainController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        MovieOverlayPanel.shared.hide(animated: false)
        let vc = BaseDetailViewController.make(movie: movies[ip.item])
        vc.onDismiss = { [weak self] in
            guard let self, self.isFavoritesTab else { return }
            self.loadFavorites()
        }
        present(vc, animated: true)
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

// MARK: - UICollectionViewDelegateFlowLayout

extension MainController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize {
        cellSize()
    }

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        nextPageURL != nil && !isFavoritesTab
            ? CGSize(width: cv.bounds.width, height: 80)
            : .zero
    }
}
