import UIKit
import Combine

final class SearchViewController: BaseViewController {
    private let viewModel: SearchViewModel
    
    private let searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.1)
        v.layer.cornerRadius = 16
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = .lightGray
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 32, weight: .medium)
        tf.textColor = .white
        tf.returnKeyType = .search
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let collectionView: UICollectionView
    private typealias DataSource = UICollectionViewDiffableDataSource<Int, Int>
    private var dataSource: DataSource?
    private var results: [ContentItem] = []
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = .white
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .medium)
        l.textColor = .lightGray
        l.textAlignment = .center
        l.isHidden = true
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    init(viewModel: SearchViewModel, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.viewModel = viewModel
        
        let layout = Self.makeLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        super.init(themeManager: themeManager, languageManager: languageManager)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .black.withAlphaComponent(0.9)
        view.addSubviews(searchContainer, collectionView, loadingIndicator, emptyLabel)
        searchContainer.addSubviews(searchIcon, searchTextField)

        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            searchContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchContainer.widthAnchor.constraint(equalToConstant: 1000),
            searchContainer.heightAnchor.constraint(equalToConstant: 80),
            
            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 24),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 32),
            searchIcon.heightAnchor.constraint(equalToConstant: 32),
            
            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 20),
            searchTextField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -24),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            
            collectionView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 40),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 100),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 100),
            emptyLabel.widthAnchor.constraint(equalToConstant: 800)
        ])
        
        collectionView.backgroundColor = .clear
        collectionView.register(MoviesPosterCollectionCell.self, forCellWithReuseIdentifier: MoviesPosterCollectionCell.reuseID)
        collectionView.delegate = self
        
        searchTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        searchTextField.placeholder = L10n.Search.placeholder
    }
    
    @objc private func textChanged() {
        viewModel.query = searchTextField.text ?? ""
    }
    
    private func bindViewModel() {
        viewModel.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.results = items
                self?.applySnapshot(animated: true)
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
            
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.emptyLabel.isHidden = true
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
            
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                if let msg = msg {
                    self?.emptyLabel.text = msg
                    self?.emptyLabel.isHidden = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateEmptyState() {
        let hasNoResults = results.isEmpty && !viewModel.query.isEmpty && !viewModel.isLoading
        emptyLabel.isHidden = !hasNoResults
        if hasNoResults {
            emptyLabel.text = L10n.Search.emptyResults
        }
    }

    
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, _ in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MoviesPosterCollectionCell.reuseID, for: indexPath) as! MoviesPosterCollectionCell
            if let movie = self.results[safe: indexPath.item] {
                cell.configure(movie: movie)
            }
            return cell
        }
    }
    
    private func applySnapshot(animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(results.map { $0.id }, toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: animated)
    }
    
    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        searchContainer.backgroundColor = style.surface.withAlphaComponent(0.15)
        searchTextField.textColor = style.textPrimary
        searchTextField.tintColor = style.accent
        searchIcon.tintColor = style.textSecondary
    }
    
    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let columns = 5
            let horizontalInset: CGFloat = 80
            let spacing: CGFloat = 28
            
            let containerWidth = environment.container.effectiveContentSize.width
            let availableWidth = containerWidth - (horizontalInset * 2) - (spacing * CGFloat(columns - 1))
            let itemWidth = floor(availableWidth / CGFloat(columns))
            let itemHeight = floor(itemWidth * 313.0 / 220.0)
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth), heightDimension: .absolute(itemHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(itemHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: columns)
            group.interItemSpacing = .fixed(spacing)
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: horizontalInset, bottom: 80, trailing: horizontalInset)
            section.interGroupSpacing = 44
            
            return section
        }
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectItem(at: indexPath.item)
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
