import UIKit

final class TabBarView: UIView {
    weak var delegate: TabBarDelegate?

    private let separatorHeight: CGFloat = 1
    var collapsedHeight: CGFloat { config.mainRowHeight + separatorHeight }
    var expandedHeight: CGFloat { config.mainRowHeight + (selectedItemHasGenres ? config.genreRowHeight : 0) + separatorHeight }

    private var config: TabBarConfiguration
    private let searchTitle: String
    private var selectedIndex = 0
    private var selectedGenreIndex: Int?
    private var selectedItemHasGenres = false
    private var genreRowHeightConstraint: NSLayoutConstraint!
    private var tabButtons: [TabButton] = []
    private var genreButtons: [GenreButton] = []

    var currentItems: [TabItem] { config.items }

    private let mainRow = UIView()
    private let tabStack = UIStackView()
    private let separator = UIView()
    private let genreRow = UIView()
    private let genreStack = UIStackView()
    private let genreScrollView = UIScrollView()
    private lazy var searchButton = SearchButton(config: config, searchTitle: searchTitle)
    private lazy var settingsButton = SettingsButton(config: config)

    init(configuration: TabBarConfiguration, searchTitle: String) {
        self.config = configuration
        self.searchTitle = searchTitle
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildLayout()
        apply(configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(configuration: TabBarConfiguration) {
        config = configuration
        backgroundColor = configuration.backgroundColor
        separator.backgroundColor = configuration.separatorColor
        buildTabs()
    }

    func selectItem(id: String) {
        guard let index = config.items.firstIndex(where: { $0.id == id }) else { return }
        activateTab(at: index, notify: false)
    }

    func lockSettingsFocus() {
        settingsButton.canFocusAfterDismiss = false
    }

    func unlockSettingsFocus() {
        settingsButton.canFocusAfterDismiss = true
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        tabButtons.first.map { [$0] } ?? []
    }

    private func buildLayout() {
        [mainRow, genreRow, separator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        [tabStack, settingsButton, searchButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            mainRow.addSubview($0)
        }
        genreScrollView.translatesAutoresizingMaskIntoConstraints = false
        genreStack.translatesAutoresizingMaskIntoConstraints = false
        genreStack.axis = .horizontal
        genreStack.spacing = 8
        tabStack.axis = .horizontal
        tabStack.spacing = 8
        tabStack.alignment = .center
        genreRow.addSubview(genreScrollView)
        genreScrollView.addSubview(genreStack)
        genreRowHeightConstraint = genreRow.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            mainRow.topAnchor.constraint(equalTo: topAnchor),
            mainRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainRow.heightAnchor.constraint(equalToConstant: config.mainRowHeight),
            settingsButton.leadingAnchor.constraint(equalTo: mainRow.leadingAnchor, constant: 24),
            settingsButton.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),
            tabStack.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor, constant: 20),
            tabStack.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),
            searchButton.trailingAnchor.constraint(equalTo: mainRow.trailingAnchor, constant: -24),
            searchButton.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),
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
            separator.topAnchor.constraint(equalTo: genreRow.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: separatorHeight),
        ])

        searchButton.onSelect = { [weak self] in
            guard let self else { return }
            self.delegate?.tabBarDidSelectSearch(self)
        }
        settingsButton.onSelect = { [weak self] in
            guard let self else { return }
            self.delegate?.tabBarDidSelectSettings(self)
        }
    }

    private func buildTabs() {
        tabStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tabButtons.removeAll()
        selectedIndex = min(selectedIndex, max(0, config.items.count - 1))
        for (index, item) in config.items.enumerated() {
            let button = TabButton(item: item, config: config)
            button.isActiveTab = index == selectedIndex
            button.onSelect = { [weak self] in
                self?.activateTab(at: index, notify: true)
            }
            tabStack.addArrangedSubview(button)
            tabButtons.append(button)
        }
        if let item = config.items[safe: selectedIndex] {
            rebuildGenres(for: item, animated: false)
        }
    }

    private func activateTab(at index: Int, notify: Bool) {
        guard let item = config.items[safe: index] else { return }
        tabButtons[safe: selectedIndex]?.isActiveTab = false
        selectedIndex = index
        selectedGenreIndex = nil
        tabButtons[safe: selectedIndex]?.isActiveTab = true
        rebuildGenres(for: item, animated: true)
        if notify {
            delegate?.tabBar(self, didSelectItem: item)
        }
    }

    private func rebuildGenres(for item: TabItem, animated: Bool) {
        genreStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        genreButtons.removeAll()
        selectedItemHasGenres = !item.genres.isEmpty
        genreRowHeightConstraint.constant = selectedItemHasGenres ? config.genreRowHeight : 0
        for (index, genre) in item.genres.enumerated() {
            let button = GenreButton(genre: genre, config: config)
            button.onSelect = { [weak self] in
                self?.activateGenre(at: index)
            }
            genreStack.addArrangedSubview(button)
            genreButtons.append(button)
        }
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.superview?.layoutIfNeeded()
            }
        }
    }

    private func activateGenre(at index: Int) {
        guard
            let item = config.items[safe: selectedIndex],
            let genre = item.genres[safe: index]
        else { return }
        if let previous = selectedGenreIndex {
            genreButtons[safe: previous]?.isActiveTab = false
        }
        selectedGenreIndex = index
        genreButtons[safe: index]?.isActiveTab = true
        delegate?.tabBar(self, didSelectGenre: genre, inItem: item)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
