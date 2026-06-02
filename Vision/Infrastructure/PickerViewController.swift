import UIKit

final class PickerViewController: BaseController {
    struct Item {
        let primary: String
        var secondary: String? = nil
        var isSelected: Bool = false
    }
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.bold, size: 48)
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
    
    private let scrollView: UIScrollView = UIScrollView()
    var onSelect: ((Int) -> Void)?
    private let pickerTitle: String
    private let items: [Item]
    
    init(title: String, items: [Item], themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.pickerTitle = title
        self.items = items
        super.init(themeManager: themeManager, languageManager: languageManager)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        view.backgroundColor = style.surface
        titleLabel.textColor = style.textPrimary
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        titleLabel.text = pickerTitle
        view.addSubviews(titleLabel, scrollView)
        scrollView.addSubview(stackView)
        scrollView.constraints(
            top: titleLabel.bottomAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor,
            padding: .init(top: 60, left: 120, bottom: 100, right: 120)
        )
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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
    
    private func setup(item: PickerViewController.Item) {
        focusScale = 1.00
        
        label.text = item.primary
        label.font = .montserrat(.medium, size: 32)
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
