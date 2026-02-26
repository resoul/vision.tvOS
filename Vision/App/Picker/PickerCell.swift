import UIKit
import AsyncDisplayKit

// MARK: - PickerCell

/// UICollectionViewCell — host for UIKit:
///   • focus engine (canBecomeFocused, didUpdateFocus)
///   • UIPressesEvent (pressesBegan / pressesEnded / pressesCancelled)
///   • IGListKit dequeue / reuse
///
final class PickerCell: UICollectionViewCell {

    // MARK: - Node

    private let contentNode = PickerContentNode()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        let nodeView = contentNode.view
        nodeView.backgroundColor = .clear
        nodeView.isOpaque = false
        nodeView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nodeView)

        NSLayoutConstraint.activate([
            nodeView.topAnchor.constraint(equalTo: contentView.topAnchor),
            nodeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nodeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nodeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        contentNode.layoutIfNeeded()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with item: PickerItem) {
        contentNode.configure(with: item)
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        contentNode.applyFocusState(isFocused: false)
    }

    // MARK: - Focus (tvOS)

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        coordinator.addCoordinatedAnimations({
            self.contentNode.applyFocusState(isFocused: self.isFocused)
        }, completion: nil)
    }

    // MARK: - Press handling (tvOS)

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesBegan(presses, with: event)
            return
        }
        UIView.animate(withDuration: 0.07) {
            self.contentNode.applyPressedState()
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard presses.contains(where: { $0.type == .select }) else {
            super.pressesEnded(presses, with: event)
            return
        }
        UIView.animate(withDuration: 0.10) {
            self.contentNode.applyReleasedState(isFocused: self.isFocused)
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.10) {
            self.contentNode.applyReleasedState(isFocused: self.isFocused)
        }
        super.pressesCancelled(presses, with: event)
    }
}
