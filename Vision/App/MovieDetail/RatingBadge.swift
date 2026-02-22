import UIKit

final class RatingBadge: UIView {
    init(logo: String, logoColor: UIColor, rating: String, votes: String) {
        super.init(frame: .zero); translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(white: 1, alpha: 0.07)
        layer.cornerRadius = 10; layer.cornerCurve = .continuous

        let logoLbl = UILabel(); logoLbl.text = logo
        logoLbl.font = UIFont.systemFont(ofSize: 17, weight: .heavy); logoLbl.textColor = logoColor
        logoLbl.translatesAutoresizingMaskIntoConstraints = false

        let ratingLbl = UILabel(); ratingLbl.text = rating
        ratingLbl.font = UIFont.systemFont(ofSize: 22, weight: .heavy); ratingLbl.textColor = .white
        ratingLbl.translatesAutoresizingMaskIntoConstraints = false

        let votesLbl = UILabel()
        votesLbl.text = votes.isEmpty ? "" : "(\(Self.fmt(votes)))"
        votesLbl.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        votesLbl.textColor = UIColor(white: 0.42, alpha: 1)
        votesLbl.translatesAutoresizingMaskIntoConstraints = false

        let col = UIStackView(arrangedSubviews: [ratingLbl, votesLbl])
        col.axis = .vertical; col.spacing = 1; col.translatesAutoresizingMaskIntoConstraints = false

        let row = UIStackView(arrangedSubviews: [logoLbl, col])
        row.axis = .horizontal; row.spacing = 8; row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    private static func fmt(_ raw: String) -> String {
        guard let n = Int(raw.replacingOccurrences(of: " ", with: "")) else { return raw }
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:     return String(format: "%.1fK", Double(n) / 1_000)
        default: return "\(n)"
        }
    }
}
