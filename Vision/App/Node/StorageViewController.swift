import UIKit
import AsyncDisplayKit

// MARK: - Domain Layer

public protocol DonutChartSegmentProtocol {
    var value: Double { get }
    var color: UIColor { get }
    var title: String { get }
    var subtitle: String? { get }
}

public protocol DonutChartConfigurable {
    var segments: [DonutChartSegmentProtocol] { get }
    var centerText: String? { get }
    var centerSubtext: String? { get }
    var gapAngle: CGFloat { get }
    var lineWidthRatio: CGFloat { get }
    var animationDuration: TimeInterval { get }
}

public extension DonutChartConfigurable {
    var gapAngle: CGFloat { 0.03 }
    var lineWidthRatio: CGFloat { 0.28 }
    var animationDuration: TimeInterval { 0.8 }
    var centerSubtext: String? { nil }
}

// MARK: - Styles

public struct DonutChartTextStyle {
    public let font: UIFont
    public let color: UIColor
    public let alignment: NSTextAlignment

    public var attributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    }

    public static let `default` = DonutChartTextStyle(
        font: .boldSystemFont(ofSize: 28),
        color: .white,
        alignment: .center
    )

    public static let defaultSubtext = DonutChartTextStyle(
        font: .systemFont(ofSize: 16),
        color: UIColor.white.withAlphaComponent(0.6),
        alignment: .center
    )
}

public struct DonutChartAppearance {
    public let backgroundColor: UIColor

    public static let dark = DonutChartAppearance(backgroundColor: .clear)
    public static let light = DonutChartAppearance(backgroundColor: .clear)
}

// MARK: - ViewModel Layer

public struct DonutChartSegmentViewModel {
    public let color: UIColor
    public let startAngle: CGFloat
    public let endAngle: CGFloat
    public let title: String
    public let subtitle: String?
    public let percentage: String

    public var sweepAngle: CGFloat { endAngle - startAngle }
}

public struct DonutChartViewModel {
    public let segments: [DonutChartSegmentViewModel]
    public let centerText: NSAttributedString?
    public let centerSubtext: NSAttributedString?
    public let lineWidth: CGFloat
    public let radius: CGFloat

    public static func build(
        from config: DonutChartConfigurable,
        in bounds: CGRect,
        centerTextStyle: DonutChartTextStyle = .default,
        centerSubtextStyle: DonutChartTextStyle = .defaultSubtext
    ) -> DonutChartViewModel {

        let outerRadius = min(bounds.width, bounds.height) / 2 - 4
        let lineWidth = outerRadius * config.lineWidthRatio * 2
        let radius = outerRadius - lineWidth / 2

        let total = config.segments.reduce(0) { $0 + $1.value }
        guard total > 0, radius > 0, lineWidth > 0 else {
            return DonutChartViewModel(
                segments: [],
                centerText: nil,
                centerSubtext: nil,
                lineWidth: 0,
                radius: 0
            )
        }

        var currentAngle: CGFloat = -.pi / 2
        let gap = config.gapAngle

        let segmentVMs = config.segments.map { segment -> DonutChartSegmentViewModel in
            let sweep = CGFloat(segment.value / total) * 2 * .pi - gap
            let start = currentAngle
            let end = currentAngle + max(sweep, 0)
            currentAngle += max(sweep, 0) + gap

            let percent = String(format: "%.1f%%", segment.value / total * 100)

            return DonutChartSegmentViewModel(
                color: segment.color,
                startAngle: start,
                endAngle: end,
                title: segment.title,
                subtitle: segment.subtitle,
                percentage: percent
            )
        }

        let centerText = config.centerText.map {
            NSAttributedString(string: $0, attributes: centerTextStyle.attributes)
        }

        let centerSubtext = config.centerSubtext.map {
            NSAttributedString(string: $0, attributes: centerSubtextStyle.attributes)
        }

        return DonutChartViewModel(
            segments: segmentVMs,
            centerText: centerText,
            centerSubtext: centerSubtext,
            lineWidth: lineWidth,
            radius: radius
        )
    }
}

// MARK: - Draw Parameters

final class DonutChartDrawParameters: NSObject {
    let viewModel: DonutChartViewModel
    let bounds: CGRect

    init(viewModel: DonutChartViewModel, bounds: CGRect) {
        self.viewModel = viewModel
        self.bounds = bounds
    }
}

// MARK: - Renderer

enum DonutChartRenderer {

    static func render(_ params: DonutChartDrawParameters, in bounds: CGRect) {
        let vm = params.viewModel
        guard vm.radius > 0, vm.lineWidth > 0 else { return }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        drawSegments(vm.segments, center: center, vm: vm)
        drawInnerCircle(center: center, vm: vm)
        drawCenterText(vm, center: center)
    }

    // Рисуем каждый сегмент через clip — точная форма без артефактов round cap
    private static func drawSegments(
        _ segments: [DonutChartSegmentViewModel],
        center: CGPoint,
        vm: DonutChartViewModel
    ) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let outerR = vm.radius + vm.lineWidth / 2
        let innerR = vm.radius - vm.lineWidth / 2

        for segment in segments {
            guard segment.sweepAngle > 0.001 else { continue }

            ctx.saveGState()

            // Клип в форме «кусочка» — от innerR до outerR
            let clipPath = UIBezierPath()
            clipPath.move(to: CGPoint(
                x: center.x + innerR * cos(segment.startAngle),
                y: center.y + innerR * sin(segment.startAngle)
            ))
            clipPath.addArc(
                withCenter: center, radius: innerR,
                startAngle: segment.startAngle, endAngle: segment.endAngle,
                clockwise: true
            )
            clipPath.addArc(
                withCenter: center, radius: outerR,
                startAngle: segment.endAngle, endAngle: segment.startAngle,
                clockwise: false
            )
            clipPath.close()

            ctx.addPath(clipPath.cgPath)
            ctx.clip()

            // Заливаем цветом
            segment.color.setFill()
            ctx.fill(CGRect(
                x: center.x - outerR, y: center.y - outerR,
                width: outerR * 2,    height: outerR * 2
            ))

            ctx.restoreGState()
        }
    }

    // Чёрный круг поверх центра — даёт чистую дыру независимо от фона
    private static func drawInnerCircle(center: CGPoint, vm: DonutChartViewModel) {
        let innerR = vm.radius - vm.lineWidth / 2
        guard innerR > 0 else { return }

        let path = UIBezierPath(
            arcCenter: center,
            radius: innerR - 1, // -1px чтобы не было видно края
            startAngle: 0, endAngle: .pi * 2,
            clockwise: true
        )
        UIColor.black.setFill()
        path.fill()
    }

    private static func drawCenterText(_ vm: DonutChartViewModel, center: CGPoint) {
        var totalHeight: CGFloat = 0

        if let text = vm.centerText { totalHeight += text.size().height }
        if let sub = vm.centerSubtext { totalHeight += sub.size().height + 4 }

        var y = center.y - totalHeight / 2

        if let text = vm.centerText {
            let size = text.size()
            text.draw(in: CGRect(
                x: center.x - size.width / 2, y: y,
                width: size.width, height: size.height
            ))
            y += size.height + 4
        }

        if let sub = vm.centerSubtext {
            let size = sub.size()
            sub.draw(in: CGRect(
                x: center.x - size.width / 2, y: y,
                width: size.width, height: size.height
            ))
        }
    }
}

// MARK: - Easing

enum Easing {
    static func easeOutCubic(_ t: CGFloat) -> CGFloat {
        1 - pow(1 - t, 3)
    }
}

// MARK: - DonutChartNode

public final class DonutChartNode: ASDisplayNode {

    // MARK: Public

    public var appearance: DonutChartAppearance = .dark {
        didSet { setNeedsDisplay() }
    }

    public var centerTextStyle: DonutChartTextStyle = .default
    public var centerSubtextStyle: DonutChartTextStyle = .defaultSubtext

    // MARK: Private

    private var pendingConfig: DonutChartConfigurable?
    private var pendingAnimated: Bool = false
    private var _viewModel: DonutChartViewModel?
    private var _animator: DisplayLinkAnimator?

    // MARK: Init

    public override init() {
        super.init()
        isOpaque = false
        backgroundColor = .clear
        isLayerBacked = true
    }

    // MARK: Public API

    public func configure(with config: DonutChartConfigurable, animated: Bool = false) {
        pendingConfig = config
        pendingAnimated = animated

        if bounds.size != .zero {
            commitConfig()
        }
    }

    // MARK: Layout — вызывается ASDK когда bounds финализированы

    public override func layout() {
        super.layout()
        if pendingConfig != nil {
            commitConfig()
        }
    }

    // MARK: Private

    private func commitConfig() {
        guard let config = pendingConfig, bounds.size != .zero else { return }

        let vm = DonutChartViewModel.build(
            from: config,
            in: bounds,
            centerTextStyle: centerTextStyle,
            centerSubtextStyle: centerSubtextStyle
        )
        _viewModel = vm
        pendingConfig = nil

        if pendingAnimated {
            startAnimation(duration: config.animationDuration)
        } else {
            setNeedsDisplay()
        }
    }

    private func startAnimation(duration: TimeInterval) {
        _animator?.invalidate()
        _animator = DisplayLinkAnimator(duration: duration) { [weak self] progress in
            guard let self else { return }
            // progress можно использовать для частичной отрисовки если нужно
            self.setNeedsDisplay()
        } completion: { [weak self] in
            self?._animator = nil
        }
    }

    // MARK: ASDK Drawing (background thread)

    public override func drawParameters(forAsyncLayer layer: _ASDisplayLayer) -> NSObjectProtocol? {
        guard let vm = _viewModel else { return nil }
        return DonutChartDrawParameters(viewModel: vm, bounds: bounds)
    }

    public override class func draw(
        _ bounds: CGRect,
        withParameters parameters: Any?,
        isCancelled isCancelledBlock: () -> Bool,
        isRasterizing: Bool
    ) {
        guard
            let params = parameters as? DonutChartDrawParameters,
            !isCancelledBlock()
        else { return }

        DonutChartRenderer.render(params, in: bounds)
    }
}

// MARK: - DisplayLinkAnimator — чище чем associated objects

private final class DisplayLinkAnimator {
    private var displayLink: CADisplayLink?
    private let startTime: CFTimeInterval
    private let duration: TimeInterval
    private let update: (CGFloat) -> Void
    private let completion: (() -> Void)?

    init(
        duration: TimeInterval,
        update: @escaping (CGFloat) -> Void,
        completion: (() -> Void)? = nil
    ) {
        self.duration   = duration
        self.startTime  = CACurrentMediaTime()
        self.update     = update
        self.completion = completion

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    @objc private func tick(_ link: CADisplayLink) {
        let elapsed  = CACurrentMediaTime() - startTime
        let progress = min(CGFloat(elapsed / duration), 1.0)
        update(Easing.easeOutCubic(progress))

        if progress >= 1.0 {
            link.invalidate()
            displayLink = nil
            completion?()
        }
    }

    func invalidate() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

// MARK: - Domain Models (конкретная реализация)

struct StorageSegment: DonutChartSegmentProtocol {
    let value: Double
    let color: UIColor
    let title: String
    let subtitle: String?
}

struct StorageChartConfig: DonutChartConfigurable {
    let segments: [DonutChartSegmentProtocol]
    let centerText: String?
    let centerSubtext: String? = nil
    let gapAngle: CGFloat = 0.03
    let lineWidthRatio: CGFloat = 0.28
    let animationDuration: TimeInterval = 0.8
}

// MARK: - StorageCategoryNode

final class StorageCategoryNode: ASDisplayNode {

    private let checkNode      = ASDisplayNode()
    private let checkImageNode = ASImageNode()
    private let titleNode      = ASTextNode()
    private let sizeNode       = ASTextNode()

    init(title: String, percent: String, size: String, color: UIColor) {
        super.init()
        automaticallyManagesSubnodes = true

        checkNode.backgroundColor = color
        checkNode.cornerRadius = 16
        checkNode.style.preferredSize = CGSize(width: 32, height: 32)

        checkImageNode.image = UIImage(systemName: "checkmark")
        checkImageNode.tintColor = .white
        checkImageNode.contentMode = .scaleAspectFit
        checkImageNode.style.preferredSize = CGSize(width: 14, height: 14)

        titleNode.attributedText = NSAttributedString(
            string: "\(title)  \(percent)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22),
                .foregroundColor: UIColor.white
            ]
        )

        sizeNode.attributedText = NSAttributedString(
            string: size,
            attributes: [
                .font: UIFont.systemFont(ofSize: 22),
                .foregroundColor: UIColor.lightGray
            ]
        )
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let checkOverlay = ASOverlayLayoutSpec(
            child: checkNode,
            overlay: ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: [],
                child: checkImageNode
            )
        )

        let leftStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 16,
            justifyContent: .start,
            alignItems: .center,
            children: [checkOverlay, titleNode]
        )
        leftStack.style.flexGrow = 1
        leftStack.style.flexShrink = 1

        let rowStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 12,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [leftStack, sizeNode]
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20),
            child: rowStack
        )
    }
}

// MARK: - StorageScrollNode

final class StorageScrollNode: ASScrollNode {

    struct Content {
        let chart:       DonutChartNode
        let title:       ASTextNode
        let subtitle:    ASTextNode
        let categories:  [StorageCategoryNode]
        let clearButton: ASButtonNode
    }

    // Максимальная ширина карточки — чтобы не растягивалась на весь tvOS экран
    static let maxCardWidth: CGFloat = 640

    private let content: Content
    private let dividers:       [ASDisplayNode]
    private let cardBackground: ASDisplayNode

    init(content: Content) {
        self.content = content

        self.dividers = (0 ..< max(0, content.categories.count - 1)).map { _ in
            let node = ASDisplayNode()
            node.backgroundColor = UIColor(white: 0.25, alpha: 1)
            node.style.height = ASDimensionMake(1)
            return node
        }

        self.cardBackground = {
            let node = ASDisplayNode()
            node.backgroundColor = UIColor(white: 0.12, alpha: 1)
            node.cornerRadius = 16
            return node
        }()

        super.init()
        automaticallyManagesSubnodes = true
        automaticallyManagesContentSize = true
        backgroundColor = .black
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {

        // Ограничиваем ширину контента — на tvOS constrainedSize.max = 1920
        let contentWidth = min(constrainedSize.max.width, StorageScrollNode.maxCardWidth)

        // Chart
        let chartCenter = ASCenterLayoutSpec(
            centeringOptions: .X,
            sizingOptions: [],
            child: content.chart
        )

        // Categories + dividers
        var categoryChildren: [ASLayoutElement] = []
        for (index, category) in content.categories.enumerated() {
            if index > 0 { categoryChildren.append(dividers[index - 1]) }
            categoryChildren.append(category)
        }

        let categoryStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .start,
            alignItems: .stretch,
            children: categoryChildren
        )

        // Card
        let cardInner = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .start,
            alignItems: .stretch,
            children: [
                categoryStack,
                ASInsetLayoutSpec(
                    insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                    child: content.clearButton
                )
            ]
        )

        let card = ASBackgroundLayoutSpec(
            child: ASInsetLayoutSpec(
                insets: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0),
                child: cardInner
            ),
            background: cardBackground
        )

        // Основной стек с ограниченной шириной
        let mainStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 24,
            justifyContent: .start,
            alignItems: .stretch,
            children: [
                chartCenter,
                ASCenterLayoutSpec(centeringOptions: .X, sizingOptions: [], child: content.title),
                ASCenterLayoutSpec(centeringOptions: .X, sizingOptions: [], child: content.subtitle),
                card
            ]
        )
        mainStack.style.width = ASDimensionMake(contentWidth)

        // Центрируем узкий контент по горизонтали внутри широкого экрана
        let centered = ASCenterLayoutSpec(
            centeringOptions: .X,
            sizingOptions: .minimumY,
            child: mainStack
        )

        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 100, left: 0, bottom: 60, right: 0),
            child: centered
        )
    }
}

// MARK: - StorageViewController

final class StorageViewController: ASDKViewController<StorageScrollNode> {

    override init() {
        let content = StorageScrollNode.Content(
            chart:       Self.makeChart(),
            title:       Self.makeTitle(),
            subtitle:    Self.makeSubtitle(),
            categories:  Self.makeCategories(),
            clearButton: Self.makeClearButton()
        )
        super.init(node: StorageScrollNode(content: content))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // tvOS safe area — задаём отступы scroll node после того как view появилась
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // На tvOS safeAreaInsets = {0, 0, 0, 0} но может меняться,
        // поэтому явно говорим scroll node пересчитать layout
        node.setNeedsLayout()
    }

    // MARK: - Static Factories

    private static func makeChart() -> DonutChartNode {
        let node = DonutChartNode()
        node.appearance = .dark
        // Увеличиваем — на tvOS 240 обрезается, нужно минимум 320
        node.style.preferredSize = CGSize(width: 320, height: 320)
        node.configure(
            with: StorageChartConfig(
                segments: [
                    StorageSegment(value: 64.1, color: .systemBlue,   title: "Videos", subtitle: "3.4 GB"),
                    StorageSegment(value: 14.9, color: .systemGreen,  title: "Files",  subtitle: "818.2 MB"),
                    StorageSegment(value: 13.7, color: .systemOrange, title: "Misc",   subtitle: "752.7 MB"),
                    StorageSegment(value: 4.2,  color: .systemTeal,   title: "Photos", subtitle: "233.7 MB"),
                    StorageSegment(value: 2.8,  color: .systemYellow, title: "Other",  subtitle: "155.9 MB"),
                ],
                centerText: "5.3 GB"
            ),
            animated: true
        )
        return node
    }

    private static func makeTitle() -> ASTextNode {
        let node = ASTextNode()
        node.attributedText = NSAttributedString(
            string: "Storage Usage",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 34),
                .foregroundColor: UIColor.white
            ]
        )
        return node
    }

    private static func makeSubtitle() -> ASTextNode {
        let node = ASTextNode()
        node.attributedText = NSAttributedString(
            string: "Telegram uses 3% of your free disk space.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: UIColor.lightGray
            ]
        )
        return node
    }

    private static func makeCategories() -> [StorageCategoryNode] {
        [
            StorageCategoryNode(title: "Videos", percent: "64.1%", size: "3.4 GB",   color: .systemBlue),
            StorageCategoryNode(title: "Files",  percent: "14.9%", size: "818.2 MB", color: .systemGreen),
            StorageCategoryNode(title: "Misc",   percent: "13.7%", size: "752.7 MB", color: .systemOrange),
            StorageCategoryNode(title: "Photos", percent: "4.2%",  size: "233.7 MB", color: .systemTeal),
            StorageCategoryNode(title: "Other",  percent: "2.8%",  size: "155.9 MB", color: .systemYellow),
        ]
    }

    private static func makeClearButton() -> ASButtonNode {
        let node = ASButtonNode()
        node.setAttributedTitle(
            NSAttributedString(
                string: "Clear Entire Cache  5.3 GB",
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.white
                ]
            ),
            for: .normal
        )
        node.backgroundColor = .systemBlue
        node.cornerRadius = 14
        node.style.height = ASDimensionMake(60)
        return node
    }
}
