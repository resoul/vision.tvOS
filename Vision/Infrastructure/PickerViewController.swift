import UIKit

final class PickerViewController: UIViewController {
    
    struct Item {
        let primary: String
        var secondary: String? = nil
        var isSelected: Bool = false
    }
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 48, weight: .bold)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    var onSelect: ((Int) -> Void)?
    
    private let pickerTitle: String
    private let items: [Item]
    
    init(title: String, items: [Item]) {
        self.pickerTitle = title
        self.items = items
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        
        titleLabel.text = pickerTitle
        view.addSubviews(titleLabel, scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 60),
            scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollView.widthAnchor.constraint(equalToConstant: 800),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        for (index, item) in items.enumerated() {
            let row = PickerRow(item: item)
            row.onSelect = { [weak self] in
                self?.onSelect?(index)
                self?.dismiss(animated: true)
            }
            stackView.addArrangedSubview(row)
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) {
            dismiss(animated: true)
        } else {
            super.pressesBegan(presses, with: event)
        }
    }
}

private final class PickerRow: TVFocusControl {
    private let label = UILabel()
    private let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    
    init(item: PickerViewController.Item) {
        super.init(frame: .zero)
        setup(item: item)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup(item: PickerViewController.Item) {
        focusScale = 1.02
        
        label.text = item.primary
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        checkmark.tintColor = .systemBlue
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.isHidden = !item.isSelected
        
        addSubview(label)
        addSubview(checkmark)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 90),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmark.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            checkmark.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 32),
            checkmark.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        updateColors()
    }
    
    override func applyFocusAppearance(focused: Bool) {
        updateColors()
    }
    
    private func updateColors() {
        let alpha: CGFloat = isFocused ? 0.15 : 0.05
        bgView.backgroundColor = UIColor.white.withAlphaComponent(alpha)
        label.textColor = isFocused ? .white : .lightGray
    }
}
