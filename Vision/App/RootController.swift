import UIKit

final class RootController: UIViewController {
    
    private let sideMenuController = SideMenuController()
    private var currentContentVC: UIViewController?
    
    private lazy var mainVC: YoutubeController = {
        let vc = YoutubeController()
//        vc.view.backgroundColor = .systemBrown
        return vc
    }()
    
    private lazy var libraryVC: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemTeal
        return vc
    }()
    
    private lazy var searchVC: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemPurple
        return vc
    }()
    
    private lazy var profileVC: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemGray
        return vc
    }()
    
    private lazy var settingsVC: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemYellow
        return vc
    }()
    
    private var sideMenuWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSideMenu()
        showContentController(mainVC)
    }
    
    private func setupSideMenu() {
        addChild(sideMenuController)
        view.addSubview(sideMenuController.view)
        sideMenuController.didMove(toParent: self)
        
        sideMenuWidthConstraint = sideMenuController.view.widthAnchor.constraint(equalToConstant: 100)
        sideMenuWidthConstraint.isActive = true
        
        
        sideMenuController.view.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: nil)
        
        sideMenuController.delegate = self
    }
    
    private func showContentController(_ newContentVC: UIViewController) {
        if let currentVC = currentContentVC {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        addChild(newContentVC)
        view.addSubview(newContentVC.view)
        newContentVC.didMove(toParent: self)
        
        newContentVC.view.translatesAutoresizingMaskIntoConstraints = false
        newContentVC.view.constraints(top: view.topAnchor, leading: sideMenuController.view.trailingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)

        self.currentContentVC = newContentVC
    }
}

extension RootController: SideMenuDelegate {
    
    func didSelectMenuItem(at index: Int) {
        let targetVC: UIViewController
        switch index {
        case 0:
            targetVC = mainVC
        case 1:
            targetVC = libraryVC
        case 2:
            targetVC = searchVC
        default:
            return
        }
        if targetVC != currentContentVC {
            showContentController(targetVC)
        }
    }
    
    func didUpdateFocusOnSideMenu(_ focused: Bool, with coordinator: UIFocusAnimationCoordinator) {
        let newWidth: CGFloat = focused ? 400 : 100
        
        if sideMenuWidthConstraint.constant != newWidth {
            sideMenuWidthConstraint.constant = newWidth
            
            coordinator.addCoordinatedAnimations({
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func didSelectHeader() {
        if profileVC != currentContentVC {
            showContentController(profileVC)
        }
    }
    
    func didSelectFooter() {
        if settingsVC != currentContentVC {
            showContentController(settingsVC)
        }
    }
}
