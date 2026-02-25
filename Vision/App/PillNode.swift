import AsyncDisplayKit

final class PillNode: ASDisplayNode {

    // MARK: - Subnodes

    private let textNode = ASTextNode()

    // MARK: - Init

    init(text: String, color: UIColor, cornerRadius: CGFloat = 6, fontSize: CGFloat = 20) {
        super.init()

        self.automaticallyManagesSubnodes = true
        self.backgroundColor = color
        self.cornerRadius = cornerRadius
        self.clipsToBounds = true
        self.cornerRoundingType = .defaultSlowCALayer

        textNode.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
        )
    }

    // MARK: - Layout

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12),
            child: textNode
        )
    }
}
