import UIKit

protocol CategoryTabBarDelegate: AnyObject {
    func categoryTabBar(_ bar: CategoryTabBar, didSelect category: FilmixCategory)
    func categoryTabBar(_ bar: CategoryTabBar, didSelectGenre genre: FilmixGenre, in category: FilmixCategory)
    func categoryTabBarDidSelectSearch(_ bar: CategoryTabBar)
    func categoryTabBarDidSelectSettings(_ bar: CategoryTabBar)
}

// MARK: - CategoryTabBar

final class CategoryTabBar: UIView {

    weak var delegate: CategoryTabBarDelegate?

    // MARK: - Heights
    static let mainRowHeight:  CGFloat = 76
    static let genreRowHeight: CGFloat = 58
    static var collapsedHeight: CGFloat { mainRowHeight }
    static var expandedHeight:  CGFloat { mainRowHeight + genreRowHeight }

    private let categories = FilmixCategory.all
    private var selectedIndex = 0
    private var tabButtons: [CategoryTabButton] = []

    // Genre row state
    private var genreButtons: [GenreTabButton] = []
    private var selectedGenreIndex: Int? = nil
    private var currentGenres: [FilmixGenre] = []

    // MARK: - Main row

    private let mainRow: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let searchButton: CategorySearchButton = {
        let b = CategorySearchButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let settingsButton: CategorySettingsButton = {
        let b = CategorySettingsButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let separatorBottom: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Genre row

    private let genreRow: UIView = {
        let v = UIView()
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let genreScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let genreStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 6
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let genreSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var genreRowHeightConstraint: NSLayoutConstraint!

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func build() {
        addSubview(mainRow)
        addSubview(genreRow)
        addSubview(separatorBottom)

        mainRow.addSubview(stackView)
        mainRow.addSubview(searchButton)
        mainRow.addSubview(settingsButton)

        genreRow.addSubview(genreScrollView)
        genreScrollView.addSubview(genreStack)
        genreRow.addSubview(genreSeparator)

        // Category tab buttons
        for (i, cat) in categories.enumerated() {
            let btn = CategoryTabButton(title: cat.title, icon: cat.icon)
            btn.tag = i
            btn.isActiveTab = (i == 0)
            let index = i
            btn.onSelect = { [weak self] in
                guard let self, index != self.selectedIndex else {
                    if let self, index == self.selectedIndex {
                        self.deselectGenre()
                        self.delegate?.categoryTabBar(self, didSelect: self.categories[index])
                    }
                    return
                }
                self.tabButtons[self.selectedIndex].isActiveTab = false
                self.selectedIndex = index
                self.tabButtons[index].isActiveTab = true
                self.showGenres(for: self.categories[index])
                self.delegate?.categoryTabBar(self, didSelect: self.categories[index])
            }
            stackView.addArrangedSubview(btn)
            tabButtons.append(btn)
        }

        searchButton.onSelect = { [weak self] in
            guard let self else { return }
            self.delegate?.categoryTabBarDidSelectSearch(self)
        }

        settingsButton.onSelect = { [weak self] in
            guard let self else { return }
            self.delegate?.categoryTabBarDidSelectSettings(self)
        }

        genreRowHeightConstraint = genreRow.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Main row
            mainRow.topAnchor.constraint(equalTo: topAnchor),
            mainRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainRow.heightAnchor.constraint(equalToConstant: Self.mainRowHeight),

            // Settings button — far left
            settingsButton.leadingAnchor.constraint(equalTo: mainRow.leadingAnchor, constant: 24),
            settingsButton.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            // Category tabs — centered between settings and search
            stackView.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor, constant: 20),
            stackView.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            // Search button — far right
            searchButton.trailingAnchor.constraint(equalTo: mainRow.trailingAnchor, constant: -24),
            searchButton.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),

            // Genre row
            genreRow.topAnchor.constraint(equalTo: mainRow.bottomAnchor),
            genreRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            genreRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            genreRowHeightConstraint,

            genreScrollView.topAnchor.constraint(equalTo: genreRow.topAnchor),
            genreScrollView.leadingAnchor.constraint(equalTo: genreRow.leadingAnchor),
            genreScrollView.trailingAnchor.constraint(equalTo: genreRow.trailingAnchor),
            genreScrollView.bottomAnchor.constraint(equalTo: genreRow.bottomAnchor),

            genreStack.topAnchor.constraint(equalTo: genreScrollView.topAnchor),
            genreStack.leadingAnchor.constraint(equalTo: genreScrollView.leadingAnchor, constant: 72),
            genreStack.trailingAnchor.constraint(equalTo: genreScrollView.trailingAnchor, constant: -72),
            genreStack.bottomAnchor.constraint(equalTo: genreScrollView.bottomAnchor),
            genreStack.heightAnchor.constraint(equalTo: genreScrollView.heightAnchor),

            genreSeparator.leadingAnchor.constraint(equalTo: genreRow.leadingAnchor),
            genreSeparator.trailingAnchor.constraint(equalTo: genreRow.trailingAnchor),
            genreSeparator.bottomAnchor.constraint(equalTo: genreRow.bottomAnchor),
            genreSeparator.heightAnchor.constraint(equalToConstant: 1),

            // Bottom separator (of entire bar)
            separatorBottom.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorBottom.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorBottom.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorBottom.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    // MARK: - Genre Row Management

    private func showGenres(for category: FilmixCategory) {
        selectedGenreIndex = nil
        currentGenres = category.genres

        genreStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        genreButtons.removeAll()

        if category.genres.isEmpty {
            setGenreRowVisible(false, animated: true)
            return
        }

        for (i, genre) in category.genres.enumerated() {
            let btn = GenreTabButton(title: genre.title)
            btn.isActiveTab = false
            let index = i
            btn.onSelect = { [weak self] in
                guard let self else { return }
                if let prev = self.selectedGenreIndex {
                    self.genreButtons[safe: prev]?.isActiveTab = false
                }
                self.selectedGenreIndex = index
                self.genreButtons[safe: index]?.isActiveTab = true
                self.delegate?.categoryTabBar(self, didSelectGenre: self.currentGenres[index], in: self.categories[self.selectedIndex])
            }
            genreStack.addArrangedSubview(btn)
            genreButtons.append(btn)
        }

        setGenreRowVisible(true, animated: true)
        genreScrollView.setContentOffset(.zero, animated: false)
    }

    private func deselectGenre() {
        if let prev = selectedGenreIndex {
            genreButtons[safe: prev]?.isActiveTab = false
        }
        selectedGenreIndex = nil
    }

    private func setGenreRowVisible(_ visible: Bool, animated: Bool) {
        let targetH: CGFloat = visible ? Self.genreRowHeight : 0
        guard genreRowHeightConstraint.constant != targetH else { return }
        genreRowHeightConstraint.constant = targetH

        if animated {
            UIView.animate(withDuration: 0.28, delay: 0,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.superview?.layoutIfNeeded()
            }
        } else {
            superview?.layoutIfNeeded()
        }
    }

    // MARK: - Programmatic selection

    func select(index: Int) {
        guard index < categories.count, index != selectedIndex else { return }
        tabButtons[selectedIndex].isActiveTab = false
        selectedIndex = index
        tabButtons[selectedIndex].isActiveTab = true
        showGenres(for: categories[index])
    }

    var hasGenres: Bool { !currentGenres.isEmpty }
}
