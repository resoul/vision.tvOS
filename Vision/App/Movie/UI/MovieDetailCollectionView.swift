import UIKit

class MovieDetailCollectionView: UICollectionView {
    
    init(frame: CGRect) {
        super.init(
            frame: frame,
            collectionViewLayout: MovieDetailCollectionLayout.createLayout()
        )
        
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundColor = .black
        contentInsetAdjustmentBehavior = .never
        
        register(cell: MovieDetailBanner.self)
        register(cell: MovieDetailPoster.self)
    }
    
    func configureBanner(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withClass: MovieDetailBanner.self, for: indexPath)
        cell.configure(image: testData.backgroundImageURL)
        
        return cell
    }
    
    func configurePoster(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = dequeueReusableCell(withClass: MovieDetailPoster.self, for: indexPath)
        cell.configure(title: "Item \(indexPath.row)")
        
        return cell
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
