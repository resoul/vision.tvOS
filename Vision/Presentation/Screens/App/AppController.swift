import UIKit
import Combine

final class AppController: BaseViewController {
    var viewModel: AppViewModel
    private var currentChildVC: UIViewController?
    private var tabBarHeightConstraint: NSLayoutConstraint!
    private let contentView = UIView()
    private let tabBarView = TabBarView(configuration: TabBarConfiguration(items: []), searchTitle: L10n.Tab.search)
    
    init(viewModel: AppViewModel, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.viewModel = viewModel
        super.init(themeManager: themeManager, languageManager: languageManager)
    }
    
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModelIfNeeded()
        viewModel.onViewDidLoad()
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [tabBarView]
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .menu }),
              let modal = presentedViewController else {
            super.pressesBegan(presses, with: event)
            return
        }
        modal.dismiss(animated: true) { [weak self] in
            self?.returnFocusToTabBar()
        }
    }

    private func setupLayout() {
        view.addSubviews(contentView, tabBarView)
        tabBarView.delegate = self

        tabBarHeightConstraint = tabBarView.heightAnchor.constraint(equalToConstant: tabBarView.collapsedHeight)
        tabBarView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor)
        contentView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        tabBarHeightConstraint.isActive = true
    }

    private func swapContent(to newVC: UIViewController, animated: Bool) {
        let oldVC = currentChildVC
        newVC.additionalSafeAreaInsets.top = tabBarHeightConstraint.constant

        addChild(newVC)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        newVC.view.alpha = animated ? 0 : 1
        contentView.addSubview(newVC.view)
        pinEdges(newVC.view, to: contentView)
        newVC.didMove(toParent: self)

        if animated {
            UIView.animate(withDuration: 0.25, animations: { newVC.view.alpha = 1 }) { _ in
                oldVC?.willMove(toParent: nil)
                oldVC?.view.removeFromSuperview()
                oldVC?.removeFromParent()
            }
        } else {
            oldVC?.willMove(toParent: nil)
            oldVC?.view.removeFromSuperview()
            oldVC?.removeFromParent()
        }
        currentChildVC = newVC
    }

    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        contentView.backgroundColor = style.background
        
        // Refresh TabBar with new style
        let currentItems = tabBarView.currentItems
        let newConfig = TabBarConfiguration.standard(items: currentItems, style: style)
        tabBarView.apply(configuration: newConfig)
    }

    private func bindViewModelIfNeeded() {
        viewModel.onConfigureTabBar = { [weak self] configuration in
            self?.tabBarView.apply(configuration: configuration)
        }
        viewModel.onUpdateTabBarHeight = { [weak self] hasGenres in
            self?.updateTabBarHeight(hasGenres: hasGenres)
        }
    }

    private func updateTabBarHeight(hasGenres: Bool) {
        let target: CGFloat = hasGenres
            ? tabBarView.expandedHeight
            : tabBarView.collapsedHeight
        guard tabBarHeightConstraint.constant != target else { return }
        tabBarHeightConstraint.constant = target
        currentChildVC?.additionalSafeAreaInsets.top = target
        UIView.animate(withDuration: 0.28, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }

    private func pinEdges(_ child: UIView, to container: UIView) {
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: container.topAnchor),
            child.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    func showContent(_ viewController: UIViewController, animated: Bool) {
        swapContent(to: viewController, animated: animated)
    }

    func presentModal(_ viewController: UIViewController, onDismiss: (() -> Void)? = nil) {
        tabBarView.lockSettingsFocus()
        
        let presenter = topMostViewController()
        
        func performPresentation() {
            let currentPresenter = topMostViewController()
            currentPresenter.present(viewController, animated: true)
        }
        
        if presenter.view.window != nil {
            performPresentation()
        } else {
            DispatchQueue.main.async {
                performPresentation()
            }
        }
    }
    
    private func topMostViewController() -> UIViewController {
        var top = self as UIViewController
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}


extension AppController: TabBarDelegate {
    func tabBar(_ tabBar: TabBarView, didSelectItem item: TabItem) {
        viewModel.didSelectItem(item)
    }

    func tabBar(_ tabBar: TabBarView, didSelectGenre genre: GenreItem, inItem item: TabItem) {
        viewModel.didSelectGenre(genre, in: item)
    }

    func tabBarDidSelectSearch(_ tabBar: TabBarView) {
        viewModel.didSelectSearch()
    }

    func tabBarDidSelectSettings(_ tabBar: TabBarView) {
        viewModel.didSelectSettings()
    }

    func returnFocusToTabBar() {
        tabBarView.unlockSettingsFocus()
    }
}
