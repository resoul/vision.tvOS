import UIKit
import AsyncDisplayKit

// MARK: - PickerContentNode

final class PickerContentNode: ASDisplayNode {

    private let bgNode = ASDisplayNode()
    private let dotNode = ASDisplayNode()
    private let primaryNode = ASTextNode2()
    private let secondaryNode = ASTextNode2()
    private let iconNode = ASTextNode2()

    private(set) var isItemSelected: Bool = false

    // MARK: Init

    override init() {
        super.init()

        automaticallyManagesSubnodes = true

        backgroundColor = .clear
        isOpaque = false

        bgNode.cornerRadius = 14
        bgNode.cornerRoundingType = .defaultSlowCALayer
        bgNode.backgroundColor = .clear
        bgNode.isOpaque = false

        dotNode.cornerRadius = 3.5
        dotNode.cornerRoundingType = .defaultSlowCALayer
        dotNode.backgroundColor = UIColor(white: 0.5, alpha: 1)
        dotNode.alpha = 0

        primaryNode.isOpaque = false
        primaryNode.backgroundColor = .clear

        secondaryNode.isOpaque = false
        secondaryNode.backgroundColor = .clear

        iconNode.isOpaque = false
        iconNode.backgroundColor = .clear
    }

    // MARK: - Configure

    func configure(with item: PickerItem) {
        isItemSelected = item.isSelected

        primaryNode.attributedText = NSAttributedString(
            string: item.primary,
            attributes: [
                .font: UIFont.systemFont(ofSize: 26, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
        )

        if let secondary = item.secondary {
            secondaryNode.attributedText = NSAttributedString(
                string: secondary,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    .foregroundColor: UIColor(white: 0.40, alpha: 1)
                ]
            )
            secondaryNode.isHidden = false
        } else {
            secondaryNode.isHidden = true
        }

        iconNode.attributedText = NSAttributedString(
            string: item.isSelected ? "✓" : "",
            attributes: [
                .font: UIFont.systemFont(ofSize: 24, weight: .light),
                .foregroundColor: UIColor(white: 0.32, alpha: 1)
            ]
        )

        dotNode.alpha = item.isSelected ? 1 : 0
        bgNode.backgroundColor = item.isSelected
            ? UIColor(white: 1, alpha: 0.08) : .clear
        setNeedsLayout()
    }

    // MARK: - Focus / Press state (from UICollectionViewCell)

    func applyFocusState(isFocused: Bool) {
        bgNode.backgroundColor = isFocused
            ? UIColor(white: 1, alpha: 0.14)
            : (isItemSelected ? UIColor(white: 1, alpha: 0.08) : .clear)

        if let current = iconNode.attributedText?.string, !current.isEmpty {
            iconNode.attributedText = NSAttributedString(
                string: current,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 24, weight: .light),
                    .foregroundColor: isFocused
                        ? UIColor(white: 0.90, alpha: 1)
                        : UIColor(white: 0.32, alpha: 1)
                ]
            )
        }
    }

    func applyPressedState() {
        bgNode.backgroundColor = UIColor(white: 1, alpha: 0.28)
    }

    func applyReleasedState(isFocused: Bool) {
        bgNode.backgroundColor = isFocused
            ? UIColor(white: 1, alpha: 0.20) : .clear
    }

    // MARK: - Layout

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        dotNode.style.preferredSize = CGSize(width: 7, height: 7)
        var textChildren: [ASLayoutElement] = [primaryNode]
        if !secondaryNode.isHidden {
            textChildren.append(secondaryNode)
        }
        let textStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 12,
            justifyContent: .start,
            alignItems: .center,
            children: textChildren
        )

        let textInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 34, bottom: 0, right: 0),
            child: textStack
        )

        let iconInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20),
            child: iconNode
        )

        textInset.style.flexGrow = 1
        textInset.style.flexShrink = 1

        let rowStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 0,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [textInset, iconInset]
        )

        dotNode.style.layoutPosition = CGPoint(x: 14, y: 0)
        let dotAbsolute = ASAbsoluteLayoutSpec(
            sizing: .sizeToFit,
            children: [dotNode]
        )

        let dotCenter = ASCenterLayoutSpec(
            centeringOptions: .Y,
            sizingOptions: .minimumY,
            child: dotAbsolute
        )

        let rowWithDot = ASOverlayLayoutSpec(child: rowStack, overlay: dotCenter)
        let verticalInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0),
            child: rowWithDot
        )

        return ASBackgroundLayoutSpec(child: verticalInset, background: bgNode)
    }
}
