import UIKit

final class RatingBadgeView: UIView {
    private let logoLabel = UILabel()
    private let ratingLabel = UILabel()
    private let votesLabel = UILabel()
    
    init(logo: String, logoColor: UIColor, rating: String, votes: String) {
        super.init(frame: .zero)
        setup(logo: logo, logoColor: logoColor, rating: rating, votes: votes)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup(logo: String, logoColor: UIColor, rating: String, votes: String) {
        backgroundColor = UIColor(white: 1, alpha: 0.1)
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous
        
        logoLabel.text = logo
        logoLabel.font = .montserrat(.semiBold, size: 20)
        logoLabel.textColor = logoColor
        
        ratingLabel.text = rating
        ratingLabel.font = .montserrat(.bold, size: 24)
        ratingLabel.textColor = .white
        
        votesLabel.text = votes
        votesLabel.font = .montserrat(.regular, size: 16)
        votesLabel.textColor = UIColor(white: 1, alpha: 0.5)
        
        let stack = UIStackView(arrangedSubviews: [logoLabel, ratingLabel, votesLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        addSubview(stack)
        stack.constraints(
            top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor,
            padding: .init(top: 6, left: 12, bottom: 6, right: 12)
        )
    }
}
