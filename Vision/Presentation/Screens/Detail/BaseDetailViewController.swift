import UIKit

class BaseDetailViewController: BaseController {
    let movie: ContentItem
    var detail: ContentDetail?
    let backdropIV = UIImageView()
    let backdropBlur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    let vignetteView = UIView()
    let contentView = UIView()
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let posterIV: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.layer.cornerCurve = .continuous
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.shadowColor = UIColor.black.cgColor
        iv.layer.shadowOpacity = 0.5
        iv.layer.shadowRadius = 30
        iv.layer.shadowOffset = CGSize(width: 0, height: 10)
        return iv
    }()
    
    let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.semiBold, size: 54)
        l.textColor = .white
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    let metaStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 10
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let ratingsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.alignment = .center
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let infoStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = .montserrat(.regular, size: 24)
        l.textColor = UIColor(white: 1, alpha: 0.8)
        l.numberOfLines = 5
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    let playButton = DetailButton(title: L10n.Detail.watch, icon: UIImage(systemName: "play.fill"), style: .primary)
    let favoriteButton = DetailButton(title: L10n.Detail.addToFavorites, icon: UIImage(systemName: "plus"), style: .secondary)
    let buttonsStack = UIStackView()
    let playbackUnavailableLabel: UILabel = {
        let label = UILabel()
        label.font = .montserrat(.medium, size: 22)
        label.numberOfLines = 2
        label.text = L10n.Detail.playbackUnavailable
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    init(movie: ContentItem, themeManager: ThemeManagerProtocol, languageManager: LanguageManagerProtocol) {
        self.movie = movie
        super.init(themeManager: themeManager, languageManager: languageManager)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateBasicData()
    }

    private func setupUI() {
        view.backgroundColor = .black
        backdropIV.contentMode = .scaleAspectFill
        backdropBlur.alpha = 0.94
        vignetteView.backgroundColor = .clear
        
        view.addSubviews(backdropIV, backdropBlur, vignetteView, scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubviews(posterIV, titleLabel, metaStack, ratingsStack, infoStack, descriptionLabel)
        
        buttonsStack.addArrangedSubview(playButton)
        buttonsStack.addArrangedSubview(favoriteButton)
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 20
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(buttonsStack)
        contentView.addSubview(playbackUnavailableLabel)
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        posterIV.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        posterIV.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        posterIV.layer.borderWidth = 1
        
        backdropIV.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        backdropBlur.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        vignetteView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        scrollView.constraints(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor)
        contentView.constraints(top: scrollView.topAnchor, leading: scrollView.leadingAnchor, bottom: scrollView.bottomAnchor, trailing: scrollView.trailingAnchor)
        
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            posterIV.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            posterIV.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 80),
            posterIV.widthAnchor.constraint(equalToConstant: 400),
            posterIV.heightAnchor.constraint(equalToConstant: 600),
            
            titleLabel.topAnchor.constraint(equalTo: posterIV.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: posterIV.trailingAnchor, constant: 60),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
            
            metaStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            metaStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            ratingsStack.topAnchor.constraint(equalTo: metaStack.bottomAnchor, constant: 24),
            ratingsStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            
            buttonsStack.topAnchor.constraint(equalTo: ratingsStack.bottomAnchor, constant: 44),
            buttonsStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            playbackUnavailableLabel.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor, constant: 16),
            playbackUnavailableLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            playbackUnavailableLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: playbackUnavailableLabel.bottomAnchor, constant: 24),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            infoStack.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 36),
            infoStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            infoStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        setupVignette()
    }
    
    private func setupVignette() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.4).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        vignetteView.layer.addSublayer(gradient)
    }
    
    private func populateBasicData() {
        titleLabel.text = movie.title
        descriptionLabel.text = movie.description
        
        posterIV.setPoster(url: movie.posterURL, placeholder: nil)
        backdropIV.setPoster(url: movie.posterURL, placeholder: nil)
    }
    
    func startLoading() {
        loadingIndicator.startAnimating()
        contentView.alpha = 0.5
    }
    
    func stopLoading() {
        loadingIndicator.stopAnimating()
        UIView.animate(withDuration: 0.3) {
            self.contentView.alpha = 1.0
        }
    }
    
    // MARK: - Theme
    
    override func applyStyle(_ style: ThemeStyle) {
        super.applyStyle(style)
        
        playButton.setThemeStyle(style)
        favoriteButton.setThemeStyle(style)

        let isLight = themeManager.theme == .light
        let textColor = isLight ? style.textPrimary : .white
        
        titleLabel.textColor = textColor
        descriptionLabel.textColor = textColor.withAlphaComponent(0.8)
        playbackUnavailableLabel.textColor = style.accent
        
        infoStack.arrangedSubviews.compactMap { $0 as? DetailInfoRow }.forEach {
            $0.updateColors(textPrimary: textColor, textSecondary: style.textSecondary)
        }
    }

    func setPlaybackAvailability(isUnavailable: Bool) {
        playbackUnavailableLabel.isHidden = !isUnavailable
        playButton.isUserInteractionEnabled = !isUnavailable
        playButton.alpha = isUnavailable ? 0.5 : 1.0
    }
}
