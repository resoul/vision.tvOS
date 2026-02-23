import UIKit

// MARK: - SettingsViewController

final class SettingsViewController: UIViewController {

    private lazy var backdropBlur: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let dimView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 0.90)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentView: UIView = {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Настройки"
        l.font = UIFont.systemFont(ofSize: 52, weight: .heavy)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let mainStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 40; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // Keep reference to reload after clear
    private var storageSectionView: StorageSectionView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        buildSections()
    }

    // MARK: - Layout

    private func buildLayout() {
        view.addSubview(backdropBlur)
        view.addSubview(dimView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            backdropBlur.topAnchor.constraint(equalTo: view.topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 120),

            mainStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 48),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 120),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -120),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -80),
        ])
    }

    // MARK: - Sections

    private func buildSections() {

        // ── Воспроизведение ────────────────────────────────────────────────
        let currentQuality = SeriesPickerStore.shared.globalPreferredQuality ?? "Авто"
        let playSection = SettingsSection(title: "Воспроизведение")
        playSection.addRow(SettingsValueRow(
            title: "Качество по умолчанию",
            value: currentQuality,
            icon: "4k.tv.fill"
        ) { [weak self] row in
            self?.showQualityPicker(row: row)
        })
        mainStack.addArrangedSubview(playSection)

        // ── Память — ползунок ──────────────────────────────────────────────
        let memSection = SettingsSection(title: "Память")
        let slider = CacheSliderRow(stepIndex: CacheSettings.shared.stepIndex)
        slider.onChange = { stepIndex in
            CacheSettings.shared.stepIndex = stepIndex
        }
        memSection.addRow(slider)
        memSection.addRow(SettingsHintRow(
            text: "Определяет сколько RAM резервируется для постеров. " +
                  "При превышении лимита старые изображения вытесняются автоматически."
        ))
        mainStack.addArrangedSubview(memSection)

        // ── Хранилище — диаграмма ──────────────────────────────────────────
        let storageSection = SettingsSection(title: "Хранилище")
        let storageView = StorageSectionView()
        storageView.presenter = self
        storageSectionView = storageView
        storageSection.addRow(storageView)
        mainStack.addArrangedSubview(storageSection)

        // ── О приложении ──────────────────────────────────────────────────
        let aboutSection = SettingsSection(title: "О приложении")
        aboutSection.addRow(SettingsInfoRow(title: "Версия", value: appVersion()))
        mainStack.addArrangedSubview(aboutSection)
    }

    // MARK: - Actions

    private func showQualityPicker(row: SettingsValueRow) {
        let qualities = ["4K UHD", "1080p Ultra+", "1080p", "720p", "480p", "360p"]
        let picker = GlobalQualityPickerViewController(
            qualities: qualities,
            current: SeriesPickerStore.shared.globalPreferredQuality
        )
        picker.onSelect = { [weak row] quality in
            SeriesPickerStore.shared.globalPreferredQuality = quality
            row?.updateValue(quality ?? "Авто")
        }
        present(picker, animated: true)
    }

    private func appVersion() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    // MARK: - Dismiss

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true) }
        else { super.pressesBegan(presses, with: event) }
    }
}

// MARK: - SettingsSection

final class SettingsSection: UIView {

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        l.textColor = UIColor(white: 0.40, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let rowsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 0; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.05)
        v.layer.cornerRadius = 18; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = title.uppercased()
        addSubview(headerLabel); addSubview(container); container.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            container.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            rowsStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            rowsStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            rowsStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            rowsStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func addRow(_ row: UIView) {
        if !rowsStack.arrangedSubviews.isEmpty {
            let sep = UIView()
            sep.backgroundColor = UIColor(white: 1, alpha: 0.06)
            sep.translatesAutoresizingMaskIntoConstraints = false
            sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
            rowsStack.addArrangedSubview(sep)
        }
        rowsStack.addArrangedSubview(row)
    }
}

// MARK: - SettingsHintRow

final class SettingsHintRow: UIView {
    init(text: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        l.textColor = UIColor(white: 0.35, alpha: 1)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        addSubview(l)
        NSLayoutConstraint.activate([
            l.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            l.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            l.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            l.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - SettingsValueRow

final class SettingsValueRow: UIView {

    private let action: (SettingsValueRow) -> Void
    private let iconView: UIImageView = {
        let iv = UIImageView(); iv.contentMode = .scaleAspectFit; iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let titleLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 28, weight: .medium); l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let valueLabel: UILabel = {
        let l = UILabel(); l.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        l.textColor = UIColor(white: 0.50, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let chevron: UILabel = {
        let l = UILabel(); l.text = "›"; l.font = UIFont.systemFont(ofSize: 30, weight: .light)
        l.textColor = UIColor(white: 0.30, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bg: UIView = {
        let v = UIView(); v.layer.cornerRadius = 14; v.layer.cornerCurve = .continuous
        v.isUserInteractionEnabled = false; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    init(title: String, value: String, icon: String, action: @escaping (SettingsValueRow) -> Void) {
        self.action = action
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 76).isActive = true
        titleLabel.text = title; valueLabel.text = value
        iconView.image = UIImage(systemName: icon)
        addSubview(bg); addSubview(iconView); addSubview(titleLabel)
        addSubview(valueLabel); addSubview(chevron)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            iconView.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 24),
            iconView.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -24),
            chevron.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -10),
            valueLabel.centerYAnchor.constraint(equalTo: bg.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func updateValue(_ text: String) { valueLabel.text = text }

    override var canBecomeFocused: Bool { true }
    override func didUpdateFocus(in ctx: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.12) : .clear
            self.chevron.textColor = self.isFocused ? UIColor(white: 0.80, alpha: 1) : UIColor(white: 0.30, alpha: 1)
            self.valueLabel.textColor = self.isFocused ? .white : UIColor(white: 0.50, alpha: 1)
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }, completion: nil)
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesBegan(presses, with: event); return }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = UIColor(white: 1, alpha: 0.20) }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesEnded(presses, with: event); return }
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = self.isFocused ? UIColor(white: 1, alpha: 0.12) : .clear }
        action(self)
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = .clear }
        super.pressesCancelled(presses, with: event)
    }
}

// MARK: - SettingsInfoRow

final class SettingsInfoRow: UIView {
    init(title: String, value: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 64).isActive = true
        let tl = UILabel(); tl.text = title
        tl.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        tl.textColor = UIColor(white: 0.60, alpha: 1)
        tl.translatesAutoresizingMaskIntoConstraints = false
        let vl = UILabel(); vl.text = value
        vl.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        vl.textColor = UIColor(white: 0.38, alpha: 1)
        vl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tl); addSubview(vl)
        NSLayoutConstraint.activate([
            tl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            tl.centerYAnchor.constraint(equalTo: centerYAnchor),
            vl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            vl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}
