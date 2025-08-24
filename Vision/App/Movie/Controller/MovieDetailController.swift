import UIKit

class MovieDetailController: UIViewController {
    
    private lazy var collectionView: MovieDetailCollectionView = {
        let collectionView = MovieDetailCollectionView(
            frame: self.view.bounds
        )
        collectionView.delegate = self
        collectionView.dataSource = self
        
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
    }
}
