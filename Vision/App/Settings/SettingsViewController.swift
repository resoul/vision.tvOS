import UIKit

final class SettingsViewController: UIViewController {
    
    private var storageSectionView: StorageSectionView?

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

    override func viewDidLoad() {
        super.viewDidLoad()
        buildLayout()
        buildSections()
    }

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

    private func buildSections() {
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
        let storageSection = SettingsSection(title: "Хранилище")
        let storageView = StorageSectionView()
        storageView.presenter = self
        storageSectionView = storageView
        storageSection.addRow(storageView)
        mainStack.addArrangedSubview(storageSection)

        let aboutSection = SettingsSection(title: "О приложении")
        aboutSection.addRow(SettingsInfoRow(title: "Версия", value: appVersion()))
        mainStack.addArrangedSubview(aboutSection)
    }

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

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if presses.contains(where: { $0.type == .menu }) { dismiss(animated: true) }
        else { super.pressesBegan(presses, with: event) }
    }
}
