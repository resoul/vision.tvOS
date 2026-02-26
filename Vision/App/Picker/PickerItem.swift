import UIKit
import IGListKit

final class PickerItem: NSObject, ListDiffable {
    let index:      Int
    let primary:    String
    let secondary:  String?
    let isSelected: Bool

    init(index: Int, primary: String, secondary: String?, isSelected: Bool) {
        self.index      = index
        self.primary    = primary
        self.secondary  = secondary
        self.isSelected = isSelected
    }

    // MARK: IGListDiffable

    func diffIdentifier() -> NSObjectProtocol { index as NSObjectProtocol }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let other = object as? PickerItem else { return false }
        return primary == other.primary
            && secondary == other.secondary
            && isSelected == other.isSelected
    }
}
