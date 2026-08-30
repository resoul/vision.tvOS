import UIKit
import Combine

final class MoviesController: BaseController {
    private enum LayoutMetrics {
        static let columns = 5
        static let horizontalInset = 80.0
        static let interitemSpacing = 28.0
        static let lineSpacing = 44.0
        static let topInset = 30.0
        static let bottomInset = 80.0
        static let posterAspectRatio = 313.0 / 220.0
    }

    private var viewModel: ContentListViewModelProtocol

    private var movies: [ContentItem] = []
    private var moviesByID: [Int: ContentItem] = [:]
    private var preferredIndexPath: IndexPath = IndexPath(item: 0, section: 0)

    private let baseGradientLayer = CAGradientLayer()

    private let backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.alpha = 0.92
        return v
    }()

    private let vignetteLayer: CAGradientLayer = {
        let l = CAGradientLayer()
        l.type = .radial
        l.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.45).cgColor]
        l.startPoint = CGPoint(x: 0.5, y: 0.5)
        l.endPoint = CGPoint(x: 1.2, y: 1.2)
        return l
    }()

    private let collectionView: UICollectionView
    private typealias DataSource = UICollectionViewDiffableDataSource<Int, Int>
    private var dataSource: DataSource?

    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = .white
        v.hidesWhenStopped = true
        return v
    }()

    private let errorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.6, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.isHidden = true
        return l
    }()

    init(
        viewModel: ContentListViewModelProtocol,
        themeManager: ThemeManagerProtocol,
        languageManager: LanguageManagerProtocol
    ) {
        self.viewModel = viewModel
        let layout = Self.makeLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(themeManager: themeManager, languageManager: languageManager)

        collectionView.delegate = self
        collectionView.remembersLastFocusedIndexPath = true
        collectionView.allowsSelection = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        viewModel.onViewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        baseGradientLayer.frame = view.bounds
        vignetteLayer.frame = view.bounds
    }
    
    private func setupUI() {
        view.layer.insertSublayer(baseGradientLayer, at: 0)
        view.layer.addSublayer(vignetteLayer)
        view.addSubviews(backdropImageView, backdropBlur, collectionView, loadingIndicator, errorLabel)
        backdropImageView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        backdropBlur.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        collectionView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        loadingIndicator.constraintToCenter(in: view)
        errorLabel.constraintToCenter(in: view)
        errorLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6).isActive = true
        
        collectionView.register(MoviesPosterCollectionCell.self, forCellWithReuseIdentifier: MoviesPosterCollectionCell.reuseID)
    }

    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, movieID in
            guard let self, let movie = self.moviesByID[movieID] else {
                return UICollectionViewCell()
            }
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MoviesPosterCollectionCell.reuseID,
                for: indexPath
            ) as? MoviesPosterCollectionCell else {
                return UICollectionViewCell()
            }
            cell.configure(movie: movie)
            return cell
        }
    }

    private func applySnapshot(animated: Bool) {
        var seenIDs = Set<Int>()
        let uniqueMovies = movies.filter { seenIDs.insert($0.id).inserted }

        moviesByID = Dictionary(uniqueMovies.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })

        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(uniqueMovies.map(\.id), toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: animated)
    }

    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        collectionView.backgroundColor = .clear

        baseGradientLayer.colors = [
            style.background.cgColor,
            style.surface.cgColor
        ]

        let blurEffect: UIBlurEffect.Style = {
            if style.background.isLight { return .light }
            return .dark
        }()
        backdropBlur.effect = UIBlurEffect(style: blurEffect)

        vignetteLayer.colors = [
            UIColor.clear.cgColor,
            style.background.withAlphaComponent(0.85).cgColor
        ]
    }
    
    private func bindViewModel() {
        viewModel.onLoadingChanged = { [weak self] isLoading in
            guard let self else { return }
            if isLoading {
                self.errorLabel.isHidden = true
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }

        viewModel.onMoviesChanged = { [weak self] movies in
            guard let self else { return }
            self.movies = movies
            self.applySnapshot(animated: false)
        }

        viewModel.onMoviesAppended = { [weak self] movies in
            guard let self else { return }
            guard !movies.isEmpty else { return }
            self.movies.append(contentsOf: movies)
            self.applySnapshot(animated: true)
        }

        viewModel.onError = { [weak self] message in
            guard let self else { return }
            self.errorLabel.text = message
            self.errorLabel.isHidden = false
        }
    }

    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let containerWidth = environment.container.effectiveContentSize.width
            let totalHorizontalInset = LayoutMetrics.horizontalInset * 2
            let totalSpacing = LayoutMetrics.interitemSpacing * CGFloat(LayoutMetrics.columns - 1)
            let availableWidth = max(0, containerWidth - totalHorizontalInset - totalSpacing)
            let itemWidth = floor(availableWidth / CGFloat(LayoutMetrics.columns))
            let itemHeight = floor(itemWidth * LayoutMetrics.posterAspectRatio)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(itemWidth),
                heightDimension: .absolute(itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(itemHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: LayoutMetrics.columns)
            group.interItemSpacing = .fixed(LayoutMetrics.interitemSpacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = LayoutMetrics.lineSpacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: LayoutMetrics.topInset,
                leading: LayoutMetrics.horizontalInset,
                bottom: LayoutMetrics.bottomInset,
                trailing: LayoutMetrics.horizontalInset
            )

            return section
        }
    }

    private func cellSize() -> CGSize {
        let width = view.bounds.width
        let horizontalPadding = LayoutMetrics.horizontalInset * 2
        let spacing = LayoutMetrics.interitemSpacing * CGFloat(LayoutMetrics.columns - 1)
        let w = floor((width - horizontalPadding - spacing) / CGFloat(LayoutMetrics.columns))
        let h = floor(w * LayoutMetrics.posterAspectRatio)
        return CGSize(width: w, height: h)
    }
}

extension MoviesController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelectItem(at: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(currentIndex: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        preferredIndexPath
    }

    func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        true
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didUpdateFocusIn context: UICollectionViewFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        if let next = context.nextFocusedIndexPath, movies.indices.contains(next.item) {
            let movie = movies[next.item]
            preferredIndexPath = next
            UIView.transition(with: backdropImageView, duration: 0.4, options: .transitionCrossDissolve) {
                self.backdropImageView.setPoster(url: movie.posterURL, placeholder: nil)
            }
        } else {
            UIView.transition(with: backdropImageView, duration: 0.3, options: .transitionCrossDissolve) {
                self.backdropImageView.image = nil
            }
        }
    }
}
