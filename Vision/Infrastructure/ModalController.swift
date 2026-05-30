import UIKit

final class ModalController: UIViewController {
    private let content: UIViewController
    private let onDismiss: () -> Void

    init(content: UIViewController, onDismiss: @escaping () -> Void) {
        self.content = content
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(content)
//        content.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(content.view)
        content.view.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
//        NSLayoutConstraint.activate([
//            content.view.topAnchor.constraint(equalTo: view.topAnchor),
//            content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            content.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
        content.didMove(toParent: self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || isMovingFromParent {
            onDismiss()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
