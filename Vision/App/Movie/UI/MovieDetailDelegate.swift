import UIKit

extension MovieDetailController: CollectionViewProvider {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        section == 0 ? 1 : 10
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView as! MovieDetailCollectionView
        
        if indexPath.section == 0 {
            return cell.configureBanner(indexPath: indexPath)
        } else {
            return cell.configurePoster(indexPath: indexPath)
        }
    }
}
