import UIKit

final class SettingsStorageSectionView: UIView {
    var onClearPosters: (() -> Void)?
    var onClearHistory: (() -> Void)?
    
    private var currentStyle: ThemeStyle?
    private var lastData: SettingsStorageData = .empty
    
    private let donutView = StorageDonutView()
    
    private let postersRow = SettingsInfoRow(
        title: L10n.Settings.Storage.posters,
        value: ByteCountFormatter.string(fromByteCount: 0, countStyle: .file)
    )
    private let historyRow = SettingsInfoRow(
        title: L10n.Settings.Storage.history,
        value: ByteCountFormatter.string(fromByteCount: 0, countStyle: .file)
    )
    private let favoritesRow = SettingsInfoRow(
        title: L10n.Settings.Storage.favorites,
        value: ByteCountFormatter.string(fromByteCount: 0, countStyle: .file)
    )
    private let databaseRow = SettingsInfoRow(
        title: L10n.Settings.Storage.database,
        value: ByteCountFormatter.string(fromByteCount: 0, countStyle: .file)
    )
    private let preferencesRow = SettingsInfoRow(
        title: L10n.Settings.Storage.preferences,
        value: ByteCountFormatter.string(fromByteCount: 0, countStyle: .file)
    )
    
    private let clearPostersRow = SettingsValueRow(
        title: L10n.Settings.Storage.clearPosters,
        icon: "trash"
    )
    private let clearHistoryRow = SettingsValueRow(
        title: L10n.Settings.Storage.clearHistory,
        icon: "clock.arrow.circlepath"
    )
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let donutContainer = UIView()
        donutContainer.translatesAutoresizingMaskIntoConstraints = false
        donutContainer.addSubview(donutView)
        
        NSLayoutConstraint.activate([
            donutView.topAnchor.constraint(equalTo: donutContainer.topAnchor),
            donutView.leadingAnchor.constraint(equalTo: donutContainer.leadingAnchor),
            donutView.trailingAnchor.constraint(equalTo: donutContainer.trailingAnchor),
            donutView.bottomAnchor.constraint(equalTo: donutContainer.bottomAnchor),
            donutContainer.heightAnchor.constraint(equalToConstant: 180)
        ])
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        stackView.addArrangedSubview(donutContainer)
        stackView.setCustomSpacing(16, after: donutContainer)
        stackView.addArrangedSubview(postersRow)
        stackView.addArrangedSubview(historyRow)
        stackView.addArrangedSubview(favoritesRow)
        stackView.addArrangedSubview(databaseRow)
        stackView.addArrangedSubview(preferencesRow)
        stackView.setCustomSpacing(16, after: preferencesRow)
        stackView.addArrangedSubview(clearPostersRow)
        stackView.addArrangedSubview(clearHistoryRow)
    }
    
    private func setupActions() {
        clearPostersRow.onSelect = { [weak self] in
            self?.onClearPosters?()
        }
        
        clearHistoryRow.onSelect = { [weak self] in
            self?.onClearHistory?()
        }
    }
    
    func update(_ data: SettingsStorageData) {
        lastData = data
        postersRow.updateValue(Self.format(data.postersDiskBytes))
        historyRow.updateValue(Self.format(data.watchHistoryBytes))
        favoritesRow.updateValue(Self.format(data.favoritesBytes))
        databaseRow.updateValue(Self.format(data.coreDataFileBytes))
        preferencesRow.updateValue(Self.format(data.userDefaultsBytes))
        
        guard let style = currentStyle else { return }
        
        donutView.update(
            segments: [
                .init(fraction: data.fraction(of: data.postersDiskBytes), color: style.accent),
                .init(fraction: data.fraction(of: data.watchHistoryBytes), color: style.textPrimary.withAlphaComponent(0.85)),
                .init(fraction: data.fraction(of: data.favoritesBytes), color: style.textPrimary.withAlphaComponent(0.65)),
                .init(fraction: data.fraction(of: data.coreDataFileBytes), color: style.textSecondary.withAlphaComponent(0.9)),
                .init(fraction: data.fraction(of: data.userDefaultsBytes), color: style.textSecondary.withAlphaComponent(0.6))
            ],
            totalLabel: Self.format(data.totalBytes),
            textColor: style.textPrimary
        )
    }
    
    func updateColors(style: ThemeStyle) {
        currentStyle = style
        [postersRow, historyRow, favoritesRow, databaseRow, preferencesRow, clearPostersRow, clearHistoryRow].forEach {
            $0.updateColors(style: style)
        }
        update(lastData)
    }
    
    private static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private final class StorageDonutView: UIView {
    struct Segment {
        let fraction: Double
        let color: UIColor
    }
    
    private var segmentLayers: [CAShapeLayer] = []
    private let centerLabel: UILabel = {
        let label = UILabel()
        label.font = .montserrat(.bold, size: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var segments: [Segment] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(centerLabel)
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(segments: [Segment], totalLabel: String, textColor: UIColor) {
        self.segments = segments
        centerLabel.text = totalLabel
        centerLabel.textColor = textColor
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()
        
        guard !segments.isEmpty else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 8
        let lineWidth: CGFloat = 18
        let gap: Double = 0.01
        
        var startFraction: Double = -0.25
        for segment in segments where segment.fraction > 0.005 {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = segment.color.cgColor
            layer.lineWidth = lineWidth
            layer.lineCap = .round
            
            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: CGFloat((startFraction + gap / 2) * .pi * 2),
                endAngle: CGFloat((startFraction + segment.fraction - gap / 2) * .pi * 2),
                clockwise: true
            )
            layer.path = path.cgPath
            self.layer.addSublayer(layer)
            segmentLayers.append(layer)
            startFraction += segment.fraction
        }
    }
}
