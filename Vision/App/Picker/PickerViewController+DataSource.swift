import UIKit
import IGListKit

extension PickerViewController: ListAdapterDataSource {

    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        listObjects
    }

    func listAdapter(_ listAdapter: ListAdapter,
                     sectionControllerFor object: Any) -> ListSectionController {
        let sc = PickerSectionController()
        sc.onSelect = { [weak self] index in
            guard let self else { return }
                self.selectedIndex = index
                self.listObjects = self.items.enumerated().map { idx, item in
                    PickerItem(index: idx,
                               primary: item.primary,
                               secondary: item.secondary,
                               isSelected: idx == index)
                }
                self.adapter.performUpdates(animated: true) { _ in
                    self.dismiss(animated: true) { self.onSelect?(index) }
                }
        }
        return sc
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? { nil }
}
