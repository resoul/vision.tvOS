import UIKit
import Combine
import VisionProvider

final class SettingsViewController: BaseController {
    private let viewModel: SettingsViewModel
    private let contentView = UIView()
    
    private let scrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        return s
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.semiBold, size: 52)
        return l
    }()
    
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 32
        s.alignment = .fill
        return s
    }()
    
    // MARK: - Rows
    private var providerRow: SettingsValueRow?
    private var autoplayRow: SettingsValueRow?
    private var qualityRow: SettingsValueRow?
    private var themeRow: SettingsValueRow?
    private var languageRow: SettingsValueRow?
    private var fontRow: SettingsValueRow?
    private var cacheSlider: SettingsSliderRow?
    private var cacheHint: SettingsHintRow?
    private var storageSectionView: SettingsStorageSectionView?
    private var versionRow: SettingsInfoRow?
    
    init(viewModel: SettingsViewModel, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.viewModel = viewModel
        super.init(themeManager: themeManager, languageManager: languageManager)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        titleLabel.text = L10n.Settings.title
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(titleLabel, stackView)
        scrollView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        contentView.constraints(top: scrollView.topAnchor, leading: scrollView.leadingAnchor, bottom: scrollView.bottomAnchor, trailing: scrollView.trailingAnchor)
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        titleLabel.constraints(top: contentView.topAnchor, leading: contentView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 80, left: 120, bottom: 0, right: 0))
        stackView.constraints(top: titleLabel.bottomAnchor, leading: contentView.leadingAnchor, bottom: contentView.bottomAnchor, trailing: contentView.trailingAnchor, padding: .init(top: 48, left: 120, bottom: 80, right: 120))
        
        buildSections()
    }
    
    private func buildSections() {
        addSectionHeader(L10n.Settings.Section.playback)
        
        providerRow = SettingsValueRow(title: L10n.Settings.Provider.title, icon: "tv.badge.wifi.fill")
        providerRow?.onSelect = { [weak self] in self?.showProviderPicker() }
        stackView.addArrangedSubview(providerRow!)
        
        autoplayRow = SettingsValueRow(title: L10n.Settings.Autoplay.title, icon: "play.rectangle")
        autoplayRow?.onSelect = { [weak self] in self?.viewModel.toggleAutoplay() }
        stackView.addArrangedSubview(autoplayRow!)
        
        qualityRow = SettingsValueRow(title: L10n.Settings.Quality.title, icon: "4k.tv.fill")
        qualityRow?.onSelect = { [weak self] in self?.showQualityPicker() }
        stackView.addArrangedSubview(qualityRow!)
        
        addSectionHeader(L10n.Settings.Section.interface)
        
        themeRow = SettingsValueRow(title: L10n.Settings.Theme.title, icon: "paintbrush.fill")
        themeRow?.onSelect = { [weak self] in self?.showThemePicker() }
        stackView.addArrangedSubview(themeRow!)
        
        languageRow = SettingsValueRow(title: L10n.Settings.Language.title, icon: "globe")
        languageRow?.onSelect = { [weak self] in self?.showLanguagePicker() }
        stackView.addArrangedSubview(languageRow!)
        
        addSectionHeader(L10n.Settings.Section.memory)
        
        cacheSlider = SettingsSliderRow(
            title: L10n.Settings.Cache.title,
            steps: viewModel.getCacheSteps(),
            initialIndex: 3
        )
        cacheSlider?.onValueChange = { [weak self] index in
            self?.viewModel.didUpdateCacheStep(index)
        }
        stackView.addArrangedSubview(cacheSlider!)
        
        cacheHint = SettingsHintRow(text: L10n.Settings.Cache.hint)
        stackView.addArrangedSubview(cacheHint!)
        
        addSectionHeader(L10n.Settings.Section.storage)
        
        storageSectionView = SettingsStorageSectionView()
        storageSectionView?.onClearPosters = { [weak self] in self?.confirmClearPosters() }
        storageSectionView?.onClearHistory = { [weak self] in self?.confirmClearHistory() }
        stackView.addArrangedSubview(storageSectionView!)
        
        addSectionHeader(L10n.Settings.Section.about)
        
        versionRow = SettingsInfoRow(title: L10n.Settings.About.version, value: viewModel.getVersionString())
        stackView.addArrangedSubview(versionRow!)
    }
    
    private func addSectionHeader(_ title: String) {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = .montserrat(.bold, size: 26)
        stackView.addArrangedSubview(label)
        stackView.setCustomSpacing(16, after: label)
    }
    
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .loaded(let data) = state {
                    self?.updateUI(with: data)
                }
            }
            .store(in: &cancellables)
            
        viewModel.$currentProvider
            .receive(on: DispatchQueue.main)
            .sink { [weak self] provider in self?.providerRow?.updateValue(provider.title) }
            .store(in: &cancellables)
            
        viewModel.$currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in self?.themeRow?.updateValue(theme.displayName) }
            .store(in: &cancellables)
            
        viewModel.$currentLanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lang in self?.languageRow?.updateValue(lang.displayName) }
            .store(in: &cancellables)
        
        viewModel.$storageData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.storageSectionView?.update(data)
            }
            .store(in: &cancellables)
        
        viewModel.$storageError
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.presentStorageError(message)
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with data: SettingsData) {
        providerRow?.updateValue(viewModel.currentProvider.title)
        autoplayRow?.updateValue(data.isAutoplayEnabled ? L10n.Settings.Autoplay.on : L10n.Settings.Autoplay.off)
        qualityRow?.updateValue(data.preferredQuality.rawValue)
        cacheSlider?.setIndex(data.cacheSizeStep)
    }
    
    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        titleLabel.textColor = style.textPrimary
        
        stackView.arrangedSubviews.forEach { view in
            if let row = view as? SettingsRowBase {
                row.updateColors(style: style)
            } else if let hint = view as? SettingsHintRow {
                hint.updateColors(style: style)
            } else if let storageView = view as? SettingsStorageSectionView {
                storageView.updateColors(style: style)
            } else if let label = view as? UILabel {
                label.textColor = style.textSecondary.withAlphaComponent(0.6)
            }
        }
    }
    
    private func showProviderPicker() {
        let items = ProviderType.allCases.map { provider in
            PickerViewController.Item(
                primary: provider.title,
                isSelected: provider == viewModel.currentProvider
            )
        }
        let picker = PickerViewController(
            title: L10n.Settings.Provider.title,
            items: items,
            themeManager: themeManager,
            languageManager: languageManager
        )
        
        picker.onSelect = { [weak self] index in
            self?.viewModel.didSelectProvider(ProviderType.allCases[index])
        }
        
        present(picker, animated: true)
    }
    
    private func showQualityPicker() {
        let items = VideoQuality.allCases.map { quality in
            PickerViewController.Item(
                primary: quality.rawValue,
                isSelected: quality.rawValue == qualityRow?.valueText
            )
        }
        let picker = PickerViewController(
            title: L10n.Settings.Quality.title,
            items: items,
            themeManager: themeManager,
            languageManager: languageManager
        )
        
        picker.onSelect = { [weak self] index in
            self?.viewModel.didSelectQuality(VideoQuality.allCases[index])
        }
        
        present(picker, animated: true)
    }

    private func showThemePicker() {
        let items = Theme.allCases.map { theme in
            PickerViewController.Item(primary: theme.displayName, isSelected: theme == viewModel.currentTheme)
        }
        let picker = PickerViewController(
            title: L10n.Settings.Theme.title,
            items: items,
            themeManager: themeManager,
            languageManager: languageManager
        )
        
        picker.onSelect = { [weak self] index in
            self?.viewModel.didSelectTheme(Theme.allCases[index])
        }
        
        present(picker, animated: true)
    }
    
    private func showLanguagePicker() {
        let items = AppLanguage.allCases.map { lang in
            PickerViewController.Item(primary: lang.displayName, isSelected: lang == viewModel.currentLanguage)
        }
        let picker = PickerViewController(
            title: L10n.Settings.Language.title,
            items: items,
            themeManager: themeManager,
            languageManager: languageManager
        )
        
        picker.onSelect = { [weak self] index in
            self?.viewModel.didSelectLanguage(AppLanguage.allCases[index])
        }
        present(picker, animated: true)
    }
    
    private func confirmClearPosters() {
        let alert = UIAlertController(
            title: nil,
            message: L10n.Settings.Storage.Confirm.clearPosters,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Common.confirm, style: .destructive) { [weak self] _ in
            self?.viewModel.clearPosterCache()
        })
        present(alert, animated: true)
    }
    
    private func confirmClearHistory() {
        let alert = UIAlertController(
            title: nil,
            message: L10n.Settings.Storage.Confirm.clearHistory,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.Common.confirm, style: .destructive) { [weak self] _ in
            self?.viewModel.clearWatchHistory()
        })
        present(alert, animated: true)
    }
    
    private func presentStorageError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.Common.back, style: .default))
        present(alert, animated: true)
    }
}
