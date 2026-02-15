import UIKit

protocol SideMenuDelegate: AnyObject {
    func didUpdateFocusOnSideMenu(_ focused: Bool, with coordinator: UIFocusAnimationCoordinator)
    func didSelectMenuItem(at index: Int)
    func didSelectHeader()
    func didSelectFooter()
}

final class SideMenuController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: SideMenuDelegate?
    
    private var isExpanded = false
    private let menuItems = [
        (title: "Home", icon: "house"),
        (title: "Library", icon: "square.stack"),
        (title: "Search", icon: "magnifyingglass")
    ]
    
    private let headerView = FocusableHeaderView()
    private let footerView = FocusableHeaderView()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MenuItemCell.self, forCellReuseIdentifier: "MenuItemCell")
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(footerView)
        tableView.dataSource = self
        tableView.delegate = self
        
        headerView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, size: .init(width: 0, height: 100))
        footerView.constraints(top: nil, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, size: .init(width: 0, height: 100))
        tableView.constraints(top: headerView.bottomAnchor, leading: view.leadingAnchor, bottom: footerView.topAnchor, trailing: view.trailingAnchor)
        
        setupHeaderAndFooter()
    }
    
    private func setupHeaderAndFooter() {
        headerView.label.text = "Profile"
        headerView.delegate = self
        
        footerView.label.text = "Settings"
        footerView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerMenuItems()
    }
    
    private func centerMenuItems() {
        // Вычисляем общую высоту всех ячеек
        let cellHeight: CGFloat = 80 // Убедитесь, что это соответствует высоте вашей ячейки
        let contentHeight = CGFloat(menuItems.count) * cellHeight
        
        // Получаем доступную высоту для таблицы
        let tableViewHeight = tableView.bounds.height
        
        // Вычисляем отступы сверху и снизу для центрирования
        let verticalInset = max(0, (tableViewHeight - contentHeight) / 2)
        
        // Устанавливаем отступы
        tableView.contentInset = UIEdgeInsets(top: verticalInset, left: 0, bottom: verticalInset, right: 0)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemCell", for: indexPath) as? MenuItemCell else {
            return UITableViewCell()
        }
        
        let item = menuItems[indexPath.row]
        cell.configure(with: item.title, icon: item.icon, isExpanded: isExpanded)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80 // Установите ту же высоту, что и в `centerMenuItems()`
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectMenuItem(at: indexPath.row)
    }
    
    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        let isFocused = (context.nextFocusedView?.isDescendant(of: self.view) ?? false)
        if isFocused != isExpanded {
            isExpanded = isFocused
            coordinator.addCoordinatedAnimations({
                self.tableView.reloadData()
            }, completion: nil)
        }
        
        delegate?.didUpdateFocusOnSideMenu(isFocused, with: coordinator)
    }
}

extension SideMenuController: FocusableHeaderViewDelegate {
    func didTapView(_ view: UIView) {
        if view == headerView {
            delegate?.didSelectHeader()
        } else if view == footerView {
            delegate?.didSelectFooter()
        }
    }
}
