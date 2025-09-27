import UIKit

class YoutubeController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    private let sections = youtubeData
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(YoutubeVideoCell.self, forCellWithReuseIdentifier: "YoutubeVideoCell")
        collectionView.register(YoutubeStoryCell.self, forCellWithReuseIdentifier: "YoutubeStoryCell")
        collectionView.register(
            YoutubeSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Header"
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            let sectionType = self.sections[sectionIndex]
            
            switch sectionType {
            case .stories:
                // Макет для сторис
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(120), heightDimension: .absolute(150))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 20
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
                
                return section
                
            case .video:
                // Макет для обычных видео-коллекций (ваш предыдущий макет)
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupWidth: CGFloat = 350 * 1.5 + 20
                let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(groupWidth), heightDimension: .absolute(350))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 20
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .topLeading
                )
                section.boundarySupplementaryItems = [header]
                
                return section
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionType = sections[section]
        switch sectionType {
        case .stories(let stories):
            return stories.count
        case .video( _, let videos):
            return videos.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionType = sections[indexPath.section]
        
        switch sectionType {
        case .stories(let stories):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YoutubeStoryCell", for: indexPath) as? YoutubeStoryCell else {
                return UICollectionViewCell()
            }
            let story = stories[indexPath.item]
            cell.configure(with: story)
            // Обновляем состояние фокуса
            cell.updateFocusBorder(isFocused: cell.isFocused, isNew: story.isNew)
            return cell
            
        case .video( _, let videos):
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YoutubeVideoCell", for: indexPath) as? YoutubeVideoCell else {
                return UICollectionViewCell()
            }
            let video = videos[indexPath.item]
            cell.configure(with: video)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionType = sections[indexPath.section]
        
        switch sectionType {
        case .stories:
            // Секция сторис без заголовка
            return UICollectionReusableView()
        case .video(let title, _):
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as? YoutubeSectionHeader else {
                return UICollectionReusableView()
            }
            header.configure(with: title)
            return header
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        // Здесь мы можем обновить состояние ячеек при смене фокуса
        if let focusedCell = context.nextFocusedView as? YoutubeStoryCell, let indexPath = collectionView.indexPath(for: focusedCell) {
//            let story = (sections[indexPath.section] as! YoutubeSectionType.stories).stories[indexPath.item]
//            focusedCell.updateFocusBorder(isFocused: true, isNew: story.isNew)
        }
        
        if let unfocusedCell = context.previouslyFocusedView as? YoutubeStoryCell, let indexPath = collectionView.indexPath(for: unfocusedCell) {
//            let story = (sections[indexPath.section] as! YoutubeSectionType.stories).stories[indexPath.item]
//            unfocusedCell.updateFocusBorder(isFocused: false, isNew: story.isNew)
        }
    }
}
