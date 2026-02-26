import UIKit

final class PlaybackProgressBar: UIView {

    private let trackView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 1, alpha: 0.08)
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let fillView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.23, green: 0.62, blue: 0.96, alpha: 1) // голубой
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var fillWidthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 3).isActive = true

        addSubview(trackView)
        trackView.addSubview(fillView)

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillWidthConstraint,
        ])

        alpha = 0
    }
    required init?(coder: NSCoder) { fatalError() }

    func setFraction(_ fraction: Double?) {
        guard let fraction, fraction > 0.02, fraction < 0.99 else {
            alpha = 0
            return
        }
        alpha = 1
        layoutIfNeeded()
        let w = trackView.bounds.width * CGFloat(fraction)
        fillWidthConstraint.constant = w
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }
}
