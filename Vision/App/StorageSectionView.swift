import UIKit

// MARK: - StorageColors

enum StorageColors {
    static let posters   = UIColor(red: 0.27, green: 0.55, blue: 0.95, alpha: 1)  // синий
    static let watched   = UIColor(red: 0.25, green: 0.78, blue: 0.52, alpha: 1)  // зелёный
    static let coredata  = UIColor(red: 0.38, green: 0.82, blue: 0.90, alpha: 1)  // циан
    static let prefs     = UIColor(red: 0.75, green: 0.45, blue: 0.95, alpha: 1)  // фиолетовый
}

// MARK: - StorageDonutView

final class StorageDonutView: UIView {

    struct Segment {
        let fraction: Double
        let color: UIColor
    }

    private var segmentLayers: [CAShapeLayer] = []
    private let centerLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        centerLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        centerLabel.textColor = .white
        centerLabel.textAlignment = .center
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerLabel)
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(segments: [Segment], totalLabel: String) {
        centerLabel.text = totalLabel
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()
        self.segments = segments
        setNeedsLayout()
    }

    private var segments: [Segment] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()
        guard !segments.isEmpty else { return }

        let center    = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius    = min(bounds.width, bounds.height) / 2 - 6
        let lineWidth : CGFloat = 20
        let gap       : Double  = 0.012

        var startF: Double = -0.25
        for seg in segments {
            guard seg.fraction > 0.005 else { continue }
            let sl = CAShapeLayer()
            sl.fillColor   = UIColor.clear.cgColor
            sl.strokeColor = seg.color.cgColor
            sl.lineWidth   = lineWidth
            sl.lineCap     = .butt
            let path = UIBezierPath(
                arcCenter: center, radius: radius,
                startAngle: CGFloat((startF + gap / 2) * .pi * 2),
                endAngle:   CGFloat((startF + seg.fraction - gap / 2) * .pi * 2),
                clockwise: true
            )
            sl.path = path.cgPath
            layer.addSublayer(sl)
            segmentLayers.append(sl)
            startF += seg.fraction
        }
    }
}

// MARK: - StorageRowView

final class StorageRowView: UIView {

    private let dotView   = UIView()
    private let titleLbl  = UILabel()
    private let subtitleLbl = UILabel()
    private let sizeLbl   = UILabel()
    private var clearBtn: ClearBtn?

    init(color: UIColor, title: String, subtitle: String,
         size: String, canClear: Bool, onClear: (() -> Void)? = nil) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 72).isActive = true

        dotView.backgroundColor = color
        dotView.layer.cornerRadius = 6
        dotView.translatesAutoresizingMaskIntoConstraints = false

        titleLbl.text = title
        titleLbl.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        titleLbl.textColor = .white
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        subtitleLbl.text = subtitle
        subtitleLbl.font = UIFont.systemFont(ofSize: 19, weight: .regular)
        subtitleLbl.textColor = UIColor(white: 0.45, alpha: 1)
        subtitleLbl.translatesAutoresizingMaskIntoConstraints = false

        sizeLbl.text = size
        sizeLbl.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        sizeLbl.textColor = UIColor(white: 0.65, alpha: 1)
        sizeLbl.textAlignment = .right
        sizeLbl.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subtitleLbl])
        textStack.axis = .vertical; textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(dotView); addSubview(textStack); addSubview(sizeLbl)

        var trailingAnchor = trailingAnchor
        var trailingConstant: CGFloat = -24

        if canClear, let onClear {
            let btn = ClearBtn()
            btn.onTap = onClear
            addSubview(btn)
            clearBtn = btn
            NSLayoutConstraint.activate([
                btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
                btn.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
            trailingAnchor = btn.leadingAnchor
            trailingConstant = -12
        }

        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 12),
            dotView.heightAnchor.constraint(equalToConstant: 12),
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 16),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            sizeLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: trailingConstant),
            sizeLbl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func updateSize(_ text: String) { sizeLbl.text = text }
    func updateSubtitle(_ text: String) { subtitleLbl.text = text }
}

// MARK: - ClearBtn

private final class ClearBtn: UIControl {
    var onTap: (() -> Void)?

    private let label: UILabel = {
        let l = UILabel()
        l.text = "Очистить"
        l.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        l.textColor = UIColor(red: 0.9, green: 0.30, blue: 0.30, alpha: 1)
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let bg: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 10; v.layer.cornerCurve = .continuous
        v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(bg); addSubview(label)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private let red = UIColor(red: 0.9, green: 0.30, blue: 0.30, alpha: 1)

    override var canBecomeFocused: Bool { true }
    override func didUpdateFocus(in ctx: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            self.bg.backgroundColor = self.isFocused ? self.red.withAlphaComponent(0.18) : .clear
            self.transform = self.isFocused ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }, completion: nil)
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesBegan(presses, with: event); return }
        UIView.animate(withDuration: 0.07) { self.bg.backgroundColor = self.red.withAlphaComponent(0.28) }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else { super.pressesEnded(presses, with: event); return }
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = self.isFocused ? self.red.withAlphaComponent(0.18) : .clear }
        onTap?()
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) { self.bg.backgroundColor = .clear }
        super.pressesCancelled(presses, with: event)
    }
}

// MARK: - StorageSectionView

final class StorageSectionView: UIView {

    weak var presenter: UIViewController?

    private let donut     = StorageDonutView()
    private let rowsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical; sv.spacing = 0; sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false; return sv
    }()
    private let loadingLabel: UILabel = {
        let l = UILabel()
        l.text = "Подсчёт..."
        l.font = UIFont.systemFont(ofSize: 22)
        l.textColor = UIColor(white: 0.4, alpha: 1)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        build()
        reload()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        let donutContainer = UIView()
        donutContainer.translatesAutoresizingMaskIntoConstraints = false
        donutContainer.addSubview(donut)
        donutContainer.addSubview(loadingLabel)
        addSubview(donutContainer)
        addSubview(rowsStack)

        NSLayoutConstraint.activate([
            donutContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            donutContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            donutContainer.widthAnchor.constraint(equalToConstant: 180),
            donutContainer.heightAnchor.constraint(equalToConstant: 180),

            donut.topAnchor.constraint(equalTo: donutContainer.topAnchor),
            donut.leadingAnchor.constraint(equalTo: donutContainer.leadingAnchor),
            donut.trailingAnchor.constraint(equalTo: donutContainer.trailingAnchor),
            donut.bottomAnchor.constraint(equalTo: donutContainer.bottomAnchor),

            loadingLabel.centerXAnchor.constraint(equalTo: donutContainer.centerXAnchor),
            loadingLabel.centerYAnchor.constraint(equalTo: donutContainer.centerYAnchor),

            rowsStack.topAnchor.constraint(equalTo: donutContainer.bottomAnchor, constant: 16),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    func reload() {
        loadingLabel.alpha = 1
        donut.isHidden = true
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        Task { @MainActor in
            let info = await StorageInfo.load()
            self.render(info)
        }
    }

    @MainActor
    private func render(_ info: StorageInfo) {
        loadingLabel.alpha = 0
        donut.isHidden = false

        let totalStr = StorageInfo.format(info.total > 0 ? info.total : 0)

        donut.update(segments: [
            .init(fraction: info.fraction(of: info.postersDisk),  color: StorageColors.posters),
            .init(fraction: info.fraction(of: info.watchedDB),    color: StorageColors.watched),
            .init(fraction: info.fraction(of: info.coreDataFile), color: StorageColors.coredata),
            .init(fraction: info.fraction(of: info.userDefaults), color: StorageColors.prefs),
        ], totalLabel: totalStr)

        func sep() {
            let v = UIView()
            v.backgroundColor = UIColor(white: 1, alpha: 0.06)
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: 1).isActive = true
            rowsStack.addArrangedSubview(v)
        }

        let watchedCount = WatchStore.shared.totalCount()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.posters, title: "Постеры",
            subtitle: "Дисковый кэш",
            size: StorageInfo.format(info.postersDisk), canClear: true
        ) { [weak self] in self?.clearPosters() })

        sep()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.watched, title: "История просмотров",
            subtitle: "\(watchedCount) эпизодов",
            size: StorageInfo.format(info.watchedDB), canClear: true
        ) { [weak self] in self?.clearWatched() })

        sep()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.coredata, title: "База данных",
            subtitle: "CoreData (.sqlite)",
            size: StorageInfo.format(info.coreDataFile), canClear: false
        ))

        sep()

        rowsStack.addArrangedSubview(StorageRowView(
            color: StorageColors.prefs, title: "Настройки",
            subtitle: "UserDefaults (.plist)",
            size: StorageInfo.format(info.userDefaults), canClear: false
        ))
    }

    // MARK: - Actions

    private func clearPosters() {
        confirm("Очистить кэш постеров?") {
            let dir = FileManager.default
                .urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("posters")
            try? FileManager.default.removeItem(at: dir)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.reload()
        }
    }

    private func clearWatched() {
        confirm("Сбросить историю просмотров?\nЭто действие нельзя отменить.") {
            WatchStore.shared.clearAll()
            self.reload()
        }
    }

    private func confirm(_ message: String, action: @escaping () -> Void) {
        guard let vc = presenter else { action(); return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Подтвердить", style: .destructive) { _ in action() })
        vc.present(alert, animated: true)
    }
}
