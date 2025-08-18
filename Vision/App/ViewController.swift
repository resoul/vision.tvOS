import UIKit

class ViewController: UIViewController {
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowOffset = CGSize(width: 5, height: 5)
        imageView.layer.shadowRadius = 5
        
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        
        imageView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 30, left: 55, bottom: 0, right: 55))
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6).isActive = true
        imageView.loadImage(from: URL(string: "https://images.pexels.com/photos/842711/pexels-photo-842711.jpeg")!)
    }
}
