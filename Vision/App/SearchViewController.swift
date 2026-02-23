import UIKit

// MARK: - SearchViewController

final class SearchViewController: UIViewController {

    var onMovieSelected: ((Movie) -> Void)?

    // MARK: - State

    private var searchResults: [Movie] = []
    private var searchDebounce: Timer?
    private var isShowingResults = false

    // MARK: - Background

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 0.88)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Search field

    private let searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.layer.cornerRadius = 16
        v.layer.cornerCurve = .continuous
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 1, alpha: 0.12).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = UIColor(white: 0.55, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.font = UIFont.systemFont(ofSize: 32, weight: .regular)
        tf.textColor = .white
        tf.tintColor = .white
        tf.attributedPlaceholder = NSAttributedString(
            string: "Поиск фильмов и сериалов...",
            attributes: [.foregroundColor: UIColor(white: 0.35, alpha: 1)]
        )
        tf.returnKeyType = .search
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var clearButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark.circle.fill")
        config.baseForegroundColor = UIColor(white: 0.45, alpha: 1)
        let b = UIButton(configuration: config)
        b.isHidden = true
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(clearSearch), for: .touchUpInside)
        return b
    }()

    // MARK: - Results grid

    private lazy var resultsCollectionView: UICollectionView = {
        let l = UICollectionViewFlowLayout()
        l.scrollDirection = .vertical
        l.minimumInteritemSpacing = 28
        l.minimumLineSpacing = 44
        l.sectionInset = UIEdgeInsets(top: 30, left: 80, bottom: 80, right: 80)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: l)
        cv.backgroundColor = .clear
        cv.remembersLastFocusedIndexPath = true
        cv.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseID)
        cv.dataSource = self
        cv.delegate = self
        cv.alpha = 0
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let resultsSpinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.color = .white
        v.hidesWhenStopped = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Layout constants

    private let searchBarTopInset: CGFloat = 80
    private let hInset: CGFloat = 120

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(backdropBlur)
        view.addSubview(dimView)
        view.addSubview(resultsCollectionView)
        view.addSubview(resultsSpinner)
        view.addSubview(emptyLabel)
        view.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchTextField)
        searchContainer.addSubview(clearButton)

        NSLayoutConstraint.activate([
            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Search bar
            searchContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: searchBarTopInset),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: hInset),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -hInset),
            searchContainer.heightAnchor.constraint(equalToConstant: 74),

            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 24),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 28),
            searchIcon.heightAnchor.constraint(equalToConstant: 28),

            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -12),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -20),
            clearButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 36),
            clearButton.heightAnchor.constraint(equalToConstant: 36),

            // Results
            resultsCollectionView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 24),
            resultsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            resultsSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultsSpinner.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 80),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 80),
        ])
    }

    // MARK: - Actions

    @objc private func textChanged() {
        let text = searchTextField.text ?? ""
        clearButton.isHidden = text.isEmpty

        if text.isEmpty {
            hideResults()
            return
        }

        // Debounced search on every keystroke
        searchDebounce?.invalidate()
        searchDebounce = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.loadResults(query: text)
        }
    }

    @objc private func clearSearch() {
        searchTextField.text = ""
        clearButton.isHidden = true
        hideResults()
    }

    // MARK: - Search

    private func loadResults(query: String) {
        guard !query.isEmpty else { return }
        isShowingResults = true
        resultsSpinner.startAnimating()
        emptyLabel.isHidden = true

        FilmixService.shared.fetchSearchResults(query: query) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.resultsSpinner.stopAnimating()

                switch result {
                case .success(let page):
                    self.searchResults = page.movies
                    self.resultsCollectionView.reloadData()
                    if page.movies.isEmpty {
                        self.emptyLabel.text = "Ничего не найдено по запросу «\(query)»"
                        self.emptyLabel.isHidden = false
                        UIView.animate(withDuration: 0.2) { self.resultsCollectionView.alpha = 0 }
                    } else {
                        self.emptyLabel.isHidden = true
                        UIView.animate(withDuration: 0.25) { self.resultsCollectionView.alpha = 1 }
                    }

                case .failure(let error):
                    self.emptyLabel.text = "Ошибка поиска: \(error.localizedDescription)"
                    self.emptyLabel.isHidden = false
                }
            }
        }
    }

    private func hideResults() {
        isShowingResults = false
        searchResults = []
        resultsCollectionView.reloadData()
        UIView.animate(withDuration: 0.2) { self.resultsCollectionView.alpha = 0 }
        emptyLabel.isHidden = true
    }

    // MARK: - Cell sizing

    private func cellSize() -> CGSize {
        let width = view.bounds.width
        let padding = 80.0 * 2
        let spacing = 28.0 * 4
        let w = floor((width - padding - spacing) / 5)
        let h = floor(w * 313 / 220)
        return CGSize(width: w, height: h)
    }

    // MARK: - Menu to dismiss

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) {
            dismiss(animated: true)
        } else {
            super.pressesBegan(presses, with: event)
        }
    }
}

// MARK: - UICollectionView DataSource / Delegate

extension SearchViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        searchResults.count
    }
    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseID, for: ip) as! MovieCell
        cell.configure(with: searchResults[ip.item], rank: ip.item + 1)
        return cell
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        present(BaseDetailViewController.make(movie: searchResults[ip.item]), animated: true)
    }
}

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt ip: IndexPath) -> CGSize { cellSize() }
}

// MARK: - UITextField Delegate

extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let text = textField.text ?? ""
        guard !text.isEmpty else { return true }
        textField.resignFirstResponder()
        searchDebounce?.invalidate()
        loadResults(query: text)
        return true
    }
}
