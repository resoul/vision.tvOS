import AsyncDisplayKit

final class VideoPreviewNode: ASDisplayNode {

    // MARK: - Subnodes

    private let blurNode    = ASDisplayNode()
    private let accentLine  = ASDisplayNode()
    private let titleNode   = ASTextNode()
    private let pillsRow    = ASStackLayoutSpec()
    private let descNode    = ASTextNode()
    private let lastAddedNode = ASTextNode()

    private var pills: [PillNode] = []

    // MARK: - Init

    override init() {
        super.init()
        automaticallyManagesSubnodes = true

        cornerRadius = 16
        cornerRoundingType = .defaultSlowCALayer
        clipsToBounds = false
        shadowColor = UIColor.black.cgColor
        shadowOpacity = 0.6
        shadowRadius = 24
        shadowOffset = CGSize(width: 0, height: 12)

        blurNode.setViewBlock {
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            blur.contentView.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.11, alpha: 0.88)
            return blur
        }
        blurNode.cornerRadius = 16
        blurNode.clipsToBounds = true
        accentLine.cornerRadius = 2
        accentLine.style.width  = ASDimensionMake(4)

        pillsRow.direction  = .horizontal
        pillsRow.spacing    = 6
        pillsRow.alignItems = .center
        titleNode.maximumNumberOfLines = 2
        titleNode.truncationMode = .byTruncatingTail
        descNode.maximumNumberOfLines = 5
        descNode.truncationMode = .byTruncatingTail
    }

    // MARK: - Configuration

    func configure(with viewModel: VideoPreviewViewModel) {
        accentLine.backgroundColor = viewModel.accentColor.lighter(by: 0.55)
        titleNode.attributedText = NSAttributedString(
            string: viewModel.title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 34, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
        )

        pills = []
        pills.append(PillNode(
            text: viewModel.rating,
            color: UIColor(red: 1, green: 0.82, blue: 0, alpha: 1)
        ))
        if !viewModel.year.isEmpty && viewModel.year != "—" {
            pills.append(PillNode(
                text: viewModel.year,
                color: UIColor(white: 0.28, alpha: 1)
            ))
        }
        for genre in viewModel.genres.prefix(2) where !genre.isEmpty && genre != "—" {
            pills.append(PillNode(
                text: genre,
                color: viewModel.accentColor.withAlphaComponent(0.80)
            ))
        }
        pillsRow.children = pills

        if viewModel.description.isEmpty {
            descNode.attributedText = nil
            descNode.isHidden = true
        } else {
            descNode.isHidden = false
            descNode.attributedText = NSAttributedString(
                string: viewModel.description,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 22, weight: .regular),
                    .foregroundColor: UIColor(white: 0.65, alpha: 1)
                ]
            )
        }

        if let last = viewModel.lastAdded, !last.isEmpty {
            lastAddedNode.isHidden = false
            lastAddedNode.attributedText = NSAttributedString(
                string: "▸ \(last)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                    .foregroundColor: UIColor(white: 0.45, alpha: 1)
                ]
            )
        } else {
            lastAddedNode.isHidden = true
            lastAddedNode.attributedText = nil
        }

        setNeedsLayout()
    }

    // MARK: - Layout

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let padding = UIEdgeInsets(top: 22, left: 20, bottom: 22, right: 20)
        var infoChildren: [ASLayoutElement] = []
        if !descNode.isHidden      { infoChildren.append(descNode) }
        if !lastAddedNode.isHidden { infoChildren.append(lastAddedNode) }

        let infoStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 6,
            justifyContent: .start,
            alignItems: .stretch,
            children: infoChildren
        )

        let contentStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 14,
            justifyContent: .start,
            alignItems: .stretch,
            children: [titleNode, pillsRow, infoStack]
        )
        contentStack.style.flexShrink = 1

        let rowStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 18,
            justifyContent: .start,
            alignItems: .stretch,
            children: [accentLine, contentStack]
        )

        let insetContent = ASInsetLayoutSpec(insets: padding, child: rowStack)
        let backgroundOverlay = ASOverlayLayoutSpec(child: blurNode, overlay: insetContent)

        return backgroundOverlay
    }
}
