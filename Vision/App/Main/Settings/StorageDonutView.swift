import UIKit

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
