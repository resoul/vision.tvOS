import UIKit

final class LanguagePickerViewController: UIViewController {

    var onSelect: ((String?) -> Void)?
    private let languages: [(code: String?, name: String)] = [
        ("en",  "English"),
        ("ru",  "Русский"),
        ("uk",  "Українська"),
        ("pl",  "Polski"),
        ("ro",  "Română"),
        ("fr",  "Français"),
        ("es",  "Español"),
        ("it",  "Italiano"),
    ]

    private var currentCode: String? {
        UserDefaults.standard.string(forKey: "AppLanguageCode")
    }

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 0.85)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.07)
        v.layer.cornerRadius = 24
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Язык приложения"
        l.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Изменение вступит в силу при следующем запуске"
        l.font = UIFont.systemFont(ofSize: 22, weight: .regular)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.register(LanguageCell.self, forCellReuseIdentifier: LanguageCell.reuseID)
        tv.dataSource = self
        tv.delegate   = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.remembersLastFocusedIndexPath = true
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backdropBlur)
        view.addSubview(dimView)
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(tableView)

        NSLayoutConstraint.activate([
            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 680),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(languages.count) * 72),
        ])
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true) }
        else { super.pressesBegan(presses, with: event) }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension LanguagePickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { languages.count }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: LanguageCell.reuseID, for: ip) as! LanguageCell
        let item = languages[ip.row]
        cell.configure(name: item.name, isSelected: item.code == currentCode)
        return cell
    }

    func tableView(_ tv: UITableView, heightForRowAt ip: IndexPath) -> CGFloat { 72 }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        let code = languages[ip.row].code
        UserDefaults.standard.set(code, forKey: "AppLanguageCode")
        onSelect?(code)
        dismiss(animated: true)
    }
}

// MARK: - LanguageCell

private final class LanguageCell: UITableViewCell {
    static let reuseID = "LanguageCell"

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let checkmark: UILabel = {
        let l = UILabel()
        l.text = "✓"
        l.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        l.textColor = UIColor(red: 0.4, green: 0.75, blue: 1.0, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 12
        v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(bg)
        contentView.addSubview(nameLabel)
        contentView.addSubview(checkmark)

        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            bg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            bg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            nameLabel.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 20),
            nameLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),

            checkmark.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -20),
            checkmark.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, isSelected: Bool) {
        nameLabel.text = name
        checkmark.isHidden = !isSelected
    }

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext,
                                 with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused
                ? UIColor(white: 1, alpha: 0.13) : .clear
            self.transform = self.isFocused
                ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }, completion: nil)
    }
}
