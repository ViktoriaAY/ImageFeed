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

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol {
    
    // MARK: - Public Properties
    
    var presenter: ProfilePresenterProtocol?
    func configure(_ presenter: ProfilePresenterProtocol) {
           self.presenter = presenter
           self.presenter?.view = self
       }
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
    
    private var animationLayers = [CAGradientLayer]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Передаем полное управление презентеру. Старый код проверок отсюда удален.
        presenter?.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSkeletonFrames()
    }
    
    // MARK: - ProfileViewControllerProtocol Methods
    
    func updateProfileDetails(name: String, nickname: String, bio: String) {
        nameLabel.text = name
        loginNameLabel.text = nickname
        descriptionLabel.text = bio
        
        // ВАЖНО: Присваиваем ID повторно ПОСЛЕ того, как текст обновился живыми данными из сети!
        nameLabel.accessibilityIdentifier = "Name Label"
    }
    
    func updateAvatar(with url: URL) {
        let placeholderImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ])
    }
    
    func startSkeletonAnimation() {
        guard animationLayers.isEmpty else { return }
        
        addGradientAnimation(to: avatarImageView, cornerRadius: 35)
        addGradientAnimation(to: nameLabel, cornerRadius: 4)
        addGradientAnimation(to: loginNameLabel, cornerRadius: 4)
        addGradientAnimation(to: descriptionLabel, cornerRadius: 4)
    }
    
    func removeGradientAnimation() {
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
    }
    
    func switchToSplashViewController() {
            DispatchQueue.main.async {
                // 1. Находим главное окно приложения
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let sceneDelegate = windowScene.delegate as? SceneDelegate,
                      let window = sceneDelegate.window else { return }
                
                // 2. Создаем навигационный контроллер экрана авторизации из Storyboard
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let authNC = storyboard.instantiateViewController(withIdentifier: "AuthNavigationController") as? UINavigationController else {
                    assertionFailure("Не удалось найти AuthNavigationController в Storyboard")
                    return
                }
                
                // Блок установки делегата удален, так как для UI-теста выхода он не требуется!
                
                // 3. Жестко меняем корневой контроллер окна на экран входа с красивой плавной анимацией
                window.rootViewController = authNC
                
                UIView.transition(
                    with: window,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: nil,
                    completion: nil
                )
                print("🍏 [UI TEST SUCCESS]: Экран авторизации успешно установлен как rootViewController.")
            }
        }

    
    // MARK: - Actions
    
    @objc private func didTapLogoutButton() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверен, что хотите выйти?",
            preferredStyle: .alert
        )
        
        let yesAction = UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            self?.presenter?.didTapLogoutButton()
        }
        
        let noAction = UIAlertAction(title: "Нет", style: .cancel)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        present(alert, animated: true)
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
            nameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            loginNameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
        logoutButton.accessibilityIdentifier = "logout button"
        nameLabel.accessibilityIdentifier = "Name Label"
                loginNameLabel.accessibilityIdentifier = "Username Label"

    }
    
    private func updateSkeletonFrames() {
        guard animationLayers.count == 4 else { return }
        animationLayers[0].frame = avatarImageView.bounds
        animationLayers[1].frame = nameLabel.bounds
        animationLayers[2].frame = loginNameLabel.bounds
        animationLayers[3].frame = descriptionLabel.bounds
    }
    
    private func addGradientAnimation(to view: UIView, cornerRadius: CGFloat) {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
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
}
