import UIKit
import IGListKit

final class PickerSectionController: ListSectionController {

    var onSelect: ((Int) -> Void)?

    private var item: PickerItem!

    override init() {
        super.init()
        inset = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
    }

    // MARK: IGListSectionController

    override func numberOfItems() -> Int { 1 }

    override func sizeForItem(at index: Int) -> CGSize {
        CGSize(width: collectionContext!.containerSize.width, height: 72)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext!.dequeueReusableCell(
            of: PickerCell.self,
            for: self,
            at: index
        ) as! PickerCell
        cell.configure(with: item)
        return cell
    }

    override func didUpdate(to object: Any) {
        item = object as? PickerItem
    }

    override func didSelectItem(at index: Int) {
        onSelect?(item.index)
    }
}
