import UIKit

final class EpisodeRow: TVFocusControl {
    private let titleLabel = UILabel()
    private let indexLabel = UILabel()
    private let watchedIcon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    var onPlay: (() -> Void)?
    
    init(index: Int, title: String) {
        super.init(frame: .zero)
        setup(index: index, title: title)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup(index: Int, title: String) {
        focusScale = 1.02
        normalBgAlpha = 0.05
        
        indexLabel.text = "\(index + 1)."
        indexLabel.font = .montserrat(.regular, size: 22)
        indexLabel.textColor = UIColor(white: 1, alpha: 0.4)
        
        titleLabel.text = title
        titleLabel.font = .montserrat(.medium, size: 24)
        titleLabel.textColor = .white
        
        watchedIcon.tintColor = .systemGreen
        watchedIcon.isHidden = true
        
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = UIColor(white: 1, alpha: 0.1)
        progressView.progress = 0
        progressView.isHidden = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        let stack = UIStackView(arrangedSubviews: [indexLabel, titleLabel, UIView(), watchedIcon])
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        addSubview(progressView)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            
            watchedIcon.widthAnchor.constraint(equalToConstant: 24),
            watchedIcon.heightAnchor.constraint(equalToConstant: 24),
            
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    @objc private func handleTap() {
        onPlay?()
    }
    
    func setWatched(_ watched: Bool) {
        watchedIcon.isHidden = !watched
    }
    
    func setProgress(_ fraction: Double?) {
        if let f = fraction, f > 0.05 {
            progressView.progress = Float(f)
            progressView.isHidden = false
        } else {
            progressView.isHidden = true
        }
    }
    
    func setThemeStyle(_ style: ThemeStyle) {
        titleLabel.textColor = style.textPrimary
        indexLabel.textColor = style.textSecondary
        progressView.progressTintColor = style.accent
        bgView.backgroundColor = style.textPrimary.withAlphaComponent(0.08)
    }
}
