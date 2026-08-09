import UIKit
import Kingfisher

// MARK: - Constants

enum ConstantProfileView {
    enum ProfileView {
        static let namePlaceholder = "Имя не указано"
        static let nicknamePlaceholder = "@неизвестный_пользователь"
        static let descriptionPlaceholder = "Профиль не заполнен"
        static let logoutImage = "LogOut"
        
        static let backgroundColor = "YP Black (iOS)"
        static let whiteColor = "YP White (iOS)"
        static let grayColor = "YP Gray (iOS)"
    }
}

// MARK: - ProfileViewController

final class ProfileViewController: UIViewController {
    
    // MARK: - Private UI Properties
    
    private lazy var avatarImageView: UIImageView = {
        let profileImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        let imageView = UIImageView(image: profileImage)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 35
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = ConstantProfileView.ProfileView.namePlaceholder
        label.textColor = UIColor(named: ConstantProfileView.ProfileView.whiteColor) ?? .white
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var loginNameLabel: UILabel = {
        let label = UILabel()
        label.text = ConstantProfileView.ProfileView.nicknamePlaceholder
        label.textColor = UIColor(named: ConstantProfileView.ProfileView.grayColor) ?? .gray
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ConstantProfileView.ProfileView.descriptionPlaceholder
        label.textColor = UIColor(named: ConstantProfileView.ProfileView.whiteColor) ?? .white
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var logoutButton: UIButton = {
        let image = UIImage(named: ConstantProfileView.ProfileView.logoutImage) ?? UIImage()
        let button = UIButton.systemButton(
            with: image,
            target: self,
            action: #selector(didTapLogoutButton)
        )
        button.tintColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var profileImageServiceObserver: NSObjectProtocol?
    private var animationLayers = [CAGradientLayer]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        }
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        
        updateAvatar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Если профиль ещё загружается — включаем скелетон-эффект
        if ProfileService.shared.profile == nil {
            avatarImageView.addSkeletonAnimation(cornerRadius: avatarImageView.bounds.height / 2)
            nameLabel.addSkeletonAnimation(cornerRadius: 4)
            loginNameLabel.addSkeletonAnimation(cornerRadius: 4)
            descriptionLabel.addSkeletonAnimation(cornerRadius: 4)
        }
    }
    
    // MARK: - Actions
    private func addGradientAnimation(to view: UIView, cornerRadius: CGFloat) {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: .zero, size: view.bounds.size)
        gradient.locations = [0, 0.1, 0.3]
        gradient.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = cornerRadius
        gradient.masksToBounds = true
        let gradientChangeAnimation = CABasicAnimation(keyPath: "locations")
        gradientChangeAnimation.fromValue = [0, 0.1, 0.3]
        gradientChangeAnimation.toValue = [0.7, 0.8, 1.0]
        gradientChangeAnimation.duration = 1.2
        gradientChangeAnimation.repeatCount = .infinity
        gradient.add(gradientChangeAnimation, forKey: "locationsChange")
        animationLayers.append(gradient)
        view.layer.addSublayer(gradient)
    }
    
    private func removeGradientAnimation() {
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
    }
    
    
    
    @objc private func didTapLogoutButton() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверен, что хотите выйти?",
            preferredStyle: .alert
        )
        
        let yesAction = UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            ProfileLogoutService.shared.logout()
            self.switchToSplashViewController()
        }
        
        let noAction = UIAlertAction(title: "Нет", style: .cancel)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true)
    }
    
    private func switchToSplashViewController() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else {
                print("Ошибка: Не удалось найти главное окно приложения!")
                return
            }
            let splashViewController = SplashViewController()
            window.rootViewController = splashViewController
        }
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: ConstantProfileView.ProfileView.backgroundColor)
        view.addSubview(avatarImageView)
        view.addSubview(nameLabel)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(logoutButton)
        
        let size: CGFloat = 70
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: size),
            avatarImageView.heightAnchor.constraint(equalToConstant: size),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let imageUrl = URL(string: profileImageURL)
        else { return }
        
        let placeholderImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: imageUrl,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .forceRefresh
            ])
    }
    
    
    private func updateProfileDetails(profile: Profile) {
        avatarImageView.removeSkeletonAnimation()
        nameLabel.removeSkeletonAnimation()
        loginNameLabel.removeSkeletonAnimation()
        descriptionLabel.removeSkeletonAnimation()
        
        nameLabel.text = (profile.name.isEmpty)
        ? ConstantProfileView.ProfileView.namePlaceholder
        : profile.name
        
        loginNameLabel.text = (profile.loginName.isEmpty)
        ? ConstantProfileView.ProfileView.nicknamePlaceholder
        : profile.loginName
        
        descriptionLabel.text = (profile.bio?.isEmpty ?? true)
        ? ConstantProfileView.ProfileView.descriptionPlaceholder
        : profile.bio
        
        updateAvatar()
    }
}
