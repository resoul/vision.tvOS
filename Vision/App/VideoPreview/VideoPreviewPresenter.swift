import AsyncDisplayKit

final class VideoPreviewPresenter {

    // MARK: - Configuration

    struct Config {
        var rightPadding:  CGFloat = 30
        var bottomPadding: CGFloat = 15
        var cellSize:      CGSize  = .zero

        var panelWidth:  CGFloat { cellSize.width * 2.5 + 28 }
        var panelHeight: CGFloat { cellSize.height * 0.5 }
    }

    // MARK: - Private state

    private let overlayNode    = VideoPreviewNode()
    private var config         = Config()
    private var currentMovieId: Int?

    // MARK: - Public API

    func attach(to view: UIView) {
        guard overlayNode.view.superview == nil else { return }
        view.addSubview(overlayNode.view)
        overlayNode.view.layer.zPosition = 100
        overlayNode.view.isHidden = true
    }

    func show(for movie: Movie, cellSize: CGSize) {
        guard movie.id != currentMovieId else { return }
        currentMovieId  = movie.id
        config.cellSize = cellSize

        overlayNode.configure(with: VideoPreviewViewModel(movie: movie))
        updateFrame()
        overlayNode.view.isHidden = false
    }

    func hide() {
        currentMovieId = nil
        overlayNode.view.isHidden = true
    }

    // MARK: - Private

    private func updateFrame() {
        guard let superview = overlayNode.view.superview else { return }
        let bounds = superview.bounds
        overlayNode.view.frame = CGRect(
            x: bounds.width  - config.panelWidth  - config.rightPadding,
            y: bounds.height - config.panelHeight - config.bottomPadding,
            width:  config.panelWidth,
            height: config.panelHeight
        )
    }
}
