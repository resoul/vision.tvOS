import UIKit

extension UIImageView {
    func setPoster(url: String,
                   placeholder: UIImage?,
                   crossfadeDuration: TimeInterval = 0.25) {
        if let prev = objc_getAssociatedObject(self, &AssociatedKeys.posterURL) as? String,
           !prev.isEmpty {
            PosterCache.shared.cancelTask(for: prev)
        }

        objc_setAssociatedObject(self, &AssociatedKeys.posterURL, url,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        image = placeholder
        guard !url.isEmpty else { return }

        if let cached = PosterCache.shared.image(for: url,
                                                  placeholder: placeholder,
                                                  completion: { [weak self] downloaded in
            guard let self else { return }
            let current = objc_getAssociatedObject(self, &AssociatedKeys.posterURL) as? String
            guard current == url else { return }

            if crossfadeDuration > 0 {
                UIView.transition(with: self,
                                  duration: crossfadeDuration,
                                  options: .transitionCrossDissolve) {
                    self.image = downloaded
                }
            } else {
                self.image = downloaded
            }
        }) {
            image = cached
        }
    }

    func cancelPoster() {
        if let url = objc_getAssociatedObject(self, &AssociatedKeys.posterURL) as? String {
            PosterCache.shared.cancelTask(for: url)
        }
        objc_setAssociatedObject(self, &AssociatedKeys.posterURL, nil,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private enum AssociatedKeys {
    static var posterURL: UInt8 = 0
}
