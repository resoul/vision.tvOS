import UIKit
import IGListKit

final class PickerViewController: UIViewController {

    struct Item {
        let primary:    String
        let secondary:  String?
        let isSelected: Bool
    }

    var onSelect: ((Int) -> Void)?

    private let config:       PickerConfig
    private let titleText:    String
    private let subtitleText: String
    let items: [Item]
    var selectedIndex: Int
    var listObjects: [PickerItem] = []
    lazy var adapter: ListAdapter = {
        ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()

    // MARK: Views

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor     = config.containerColor
        v.layer.cornerRadius  = config.cornerRadius
        v.layer.cornerCurve   = .continuous
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.85
        v.layer.shadowRadius  = 60
        v.layer.shadowOffset  = CGSize(width: 0, height: 20)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text      = titleText
        l.font      = .systemFont(ofSize: 32, weight: .heavy)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.text          = subtitleText
        l.font          = .systemFont(ofSize: 20, weight: .regular)
        l.textColor     = UIColor(white: 0.45, alpha: 1)
        l.numberOfLines = 2
        l.isHidden      = subtitleText.isEmpty
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing      = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // MARK: Init

    init(title: String,
         subtitle: String = "",
         items: [Item],
         config: PickerConfig = .default) {
        self.titleText    = title
        self.subtitleText = subtitle
        self.items        = items
        self.config       = config
        self.selectedIndex = items.firstIndex(where: { $0.isSelected }) ?? 0
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle   = .crossDissolve
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(config.overlayAlpha)

        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(collectionView)

        let safe         = view.safeAreaLayoutGuide
        let headerBottom = subtitleText.isEmpty
            ? titleLabel.bottomAnchor
            : subtitleLabel.bottomAnchor

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: safe.centerYAnchor),
            containerView.widthAnchor.constraint(
                equalTo: safe.widthAnchor, multiplier: config.widthFraction),
            containerView.heightAnchor.constraint(
                equalTo: safe.heightAnchor, multiplier: config.heightFraction),

            titleLabel.topAnchor.constraint(
                equalTo: containerView.topAnchor, constant: 42),
            titleLabel.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor, constant: 44),
            titleLabel.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor, constant: -44),

            subtitleLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor, constant: 44),
            subtitleLabel.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor, constant: -44),

            collectionView.topAnchor.constraint(
                equalTo: headerBottom, constant: 20),
            collectionView.leadingAnchor.constraint(
                equalTo: containerView.leadingAnchor, constant: 24),
            collectionView.trailingAnchor.constraint(
                equalTo: containerView.trailingAnchor, constant: -24),
            collectionView.bottomAnchor.constraint(
                equalTo: containerView.bottomAnchor, constant: -28),
        ])

        adapter.collectionView = collectionView
        adapter.dataSource     = self

        listObjects = items.enumerated().map { idx, item in
            PickerItem(index: idx,
                       primary: item.primary,
                       secondary: item.secondary,
                       isSelected: item.isSelected)
        }
        adapter.performUpdates(animated: false) { [weak self] _ in
            guard let self else { return }
            if let selectedIdx = self.items.firstIndex(where: { $0.isSelected }) {
                self.collectionView.scrollToItem(
                    at: IndexPath(item: 0, section: selectedIdx),
                    at: .centeredVertically, animated: false)
            }
        }
    }

    // MARK: Focus

    override var preferredFocusEnvironments: [UIFocusEnvironment] { [collectionView] }

    // MARK: Menu button

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true) }
        else { super.pressesBegan(presses, with: event) }
    }
}
