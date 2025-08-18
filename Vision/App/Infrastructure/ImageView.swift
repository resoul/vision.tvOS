import UIKit

extension UIImageView {
    func loadImage(from url: URL, placeholder: UIImage? = nil) {
        if let placeholder = placeholder {
            self.image = placeholder
        }

        Task {
            do {
                let image = try await CacheManager.shared.loadImage(from: url)
                await MainActor.run {
                    self.image = image
                }
            } catch {
                print("Download error: \(error)")
            }
        }
    }
}
