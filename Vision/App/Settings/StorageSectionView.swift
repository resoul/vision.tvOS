import UIKit

final class StorageSectionView: UIView {

    weak var presenter: UIViewController?

    private let donut     = StorageDonutView()
    private let rowsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 0; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()
    private let loadingLabel: UILabel = {
        let l = UILabel()
        l.text = "Подсчёт..."
        l.font = UIFont.systemFont(ofSize: 22)
        l.textColor = UIColor(white: 0.4, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        build()
        reload()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        let donutContainer = UIView()
        donutContainer.translatesAutoresizingMaskIntoConstraints = false
        donutContainer.addSubview(donut)
        donutContainer.addSubview(loadingLabel)
        addSubview(donutContainer)
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            donutContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            donutContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            donutContainer.widthAnchor.constraint(equalToConstant: 180),
            donutContainer.heightAnchor.constraint(equalToConstant: 180),

            donut.topAnchor.constraint(equalTo: donutContainer.topAnchor),
            donut.leadingAnchor.constraint(equalTo: donutContainer.leadingAnchor),
            donut.trailingAnchor.constraint(equalTo: donutContainer.trailingAnchor),
            donut.bottomAnchor.constraint(equalTo: donutContainer.bottomAnchor),

            loadingLabel.centerXAnchor.constraint(equalTo: donutContainer.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: donutContainer.centerYAnchor),

            rowsStack.topAnchor.constraint(equalTo: donutContainer.bottomAnchor, constant: 16),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    func reload() {
        loadingLabel.alpha = 1
        donut.isHidden = true
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        Task { @MainActor in
            let info = await StorageInfo.load()
            self.render(info)
        }
    }

    @MainActor
    private func render(_ info: StorageInfo) {
        loadingLabel.alpha = 0
        donut.isHidden = false

        let totalStr = StorageInfo.format(info.total > 0 ? info.total : 0)

        donut.update(segments: [
            .init(fraction: info.fraction(of: info.postersDisk),  color: StorageColors.posters),
            .init(fraction: info.fraction(of: info.watchedDB),    color: StorageColors.watched),
            .init(fraction: info.fraction(of: info.favoritesDB),  color: StorageColors.favorites),
            .init(fraction: info.fraction(of: info.coreDataFile), color: StorageColors.coredata),
            .init(fraction: info.fraction(of: info.userDefaults), color: StorageColors.prefs),
        ], totalLabel: totalStr)

        func sep() {
            let v = UIView()
            v.backgroundColor = UIColor(white: 1, alpha: 0.06)
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: 1).isActive = true
            rowsStack.addArrangedSubview(v)
        }

        let watchedCount   = WatchStore.shared.totalCount()
        let favoritesCount = FavoritesStore.shared.all().count

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.posters, title: "Постеры",
            subtitle: "Дисковый кэш",
            size: StorageInfo.format(info.postersDisk), canClear: true
        ) { [weak self] in self?.clearPosters() })

        sep()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.watched, title: "История просмотров",
            subtitle: "\(watchedCount) эпизодов · \(StorageInfo.format(info.watchedDB))",
            size: StorageInfo.format(info.watchedDB), canClear: true
        ) { [weak self] in self?.clearWatched() })

        sep()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.favorites, title: "Избранное",
            subtitle: "\(favoritesCount) фильмов · \(StorageInfo.format(info.favoritesDB))",
            size: StorageInfo.format(info.favoritesDB), canClear: false
        ))

        sep()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.coredata, title: "База данных",
            subtitle: "CoreData (.sqlite)",
            size: StorageInfo.format(info.coreDataFile), canClear: false
        ))

        sep()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.prefs, title: "Настройки",
            subtitle: "UserDefaults (.plist)",
            size: StorageInfo.format(info.userDefaults), canClear: false
        ))
    }

    private func clearPosters() {
        confirm("Очистить кэш постеров?") {
            let dir = FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("posters")
            try? FileManager.default.removeItem(at: dir)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.reload()
        }
    }

    private func clearWatched() {
        confirm("Сбросить историю просмотров?\nЭто действие нельзя отменить.") {
            WatchStore.shared.clearAll()
            self.reload()
        }
    }

    private func confirm(_ message: String, action: @escaping () -> Void) {
        guard let vc = presenter else { action(); return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Подтвердить", style: .destructive) { _ in action() })
        vc.present(alert, animated: true)
    }
}
