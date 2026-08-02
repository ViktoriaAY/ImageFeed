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
    
    // MARK: - Private Properties
    
    private var avatarImageView: UIImageView!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton! 
    private var profileImageServiceObserver: NSObjectProtocol?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SetupUI()
        
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

    // MARK: - Actions
    
    @objc private func didTapLogoutButton() {
    }

    // MARK: - Private Methods
    
    private func SetupUI() {
        view.backgroundColor = UIColor(named: ConstantProfileView.ProfileView.backgroundColor)
        setupAvatarView()
        setupNameLabel()
        setupDescriptionLabel()
        setupLogoutButton()
    }

    private func setupAvatarView() {
        let profileImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        avatarImageView = UIImageView(image: profileImage)
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 35
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        
        let size: CGFloat = 70
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: size),
            avatarImageView.heightAnchor.constraint(equalToConstant: size)
        ])
    }
    
    private func setupNameLabel() {
        nameLabel = UILabel()
        nameLabel.text = ConstantProfileView.ProfileView.namePlaceholder
        nameLabel.textColor = UIColor(named: ConstantProfileView.ProfileView.whiteColor) ?? .white
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor)
        ])
        
        loginNameLabel = UILabel()
        loginNameLabel.text = ConstantProfileView.ProfileView.nicknamePlaceholder
        loginNameLabel.textColor = UIColor(named: ConstantProfileView.ProfileView.grayColor) ?? .gray
        loginNameLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        NSLayoutConstraint.activate([
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor)
        ])
    }
    
    private func setupDescriptionLabel() {
        descriptionLabel = UILabel()
        descriptionLabel.text = ConstantProfileView.ProfileView.descriptionPlaceholder
        descriptionLabel.textColor = UIColor(named: ConstantProfileView.ProfileView.whiteColor) ?? .white
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor)
        ])
    }
    
    private func setupLogoutButton() {
        logoutButton = UIButton.systemButton(
            with: UIImage(named: ConstantProfileView.ProfileView.logoutImage)!,
            target: self,
            action: #selector(didTapLogoutButton)
        )
        
        logoutButton.tintColor = .red
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }

    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let imageUrl = URL(string: profileImageURL)
        else { return }

        print("[ProfileViewController.updateAvatar]: imageUrl: \(imageUrl)")

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
            ]) { result in
                switch result {
                case .success(let value):
                    print("[ProfileViewController.updateAvatar]: Success \(value.cacheType)")
                case .failure(let error):
                    print("[ProfileViewController.updateAvatar]: Error \(error)")
                }
            }
    }
    
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name.isEmpty
            ? ConstantProfileView.ProfileView.namePlaceholder
            : profile.name
            
        loginNameLabel.text = profile.loginName.isEmpty
            ? ConstantProfileView.ProfileView.nicknamePlaceholder
            : profile.loginName
            
        descriptionLabel.text = (profile.bio?.isEmpty ?? true)
            ? ConstantProfileView.ProfileView.descriptionPlaceholder
            : profile.bio
        
        updateAvatar()
    }
}
