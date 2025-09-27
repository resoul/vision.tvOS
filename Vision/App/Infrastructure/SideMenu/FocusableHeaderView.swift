import UIKit

protocol FocusableHeaderViewDelegate: AnyObject {
    func didTapView(_ view: UIView)
}

class FocusableHeaderView: UIView {
    
    weak var delegate: FocusableHeaderViewDelegate?
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.backgroundColor = self.isFocused ? UIColor.white.withAlphaComponent(0.2) : .clear
        }, completion: nil)
    }
    
    // Переопределяем pressesEnded для обработки нажатия на Siri Remote
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first, press.type == .select else {
            super.pressesEnded(presses, with: event)
            return
        }
        
        // Сообщаем делегату о клике
        delegate?.didTapView(self)
    }
}
