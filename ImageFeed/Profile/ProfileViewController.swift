import UIKit

// MARK: - Constants
enum ConstantProfileView{
    enum ProfileView {
        static let name = "Екатерина Новикова"
        static let nickname = "@ekaterina_nov"
        static let description = "Hello, world!"
        static let logoutImage = "LogOut"
        static let imageName = "UserImage"
        static let backgroundColor = "YP Black (iOS)"
    }
}

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: ConstantProfileView.ProfileView.imageName)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 35
        return imageView
    }()
    
    let nameProfile: UILabel = {
        let label = UILabel()
        label.text = ConstantProfileView.ProfileView.name
        label.textColor = .ypWhiteIOS
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        return label
    }()
    
    let loginNameLabel: UILabel = {
        let label2 = UILabel()
        label2.text = ConstantProfileView.ProfileView.nickname
        label2.textColor = .ypGrayIOS
        label2.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        return label2
    }()
    
    let descriptionLabel: UILabel = {
        let label3 = UILabel()
        label3.text = ConstantProfileView.ProfileView.description
        label3.textColor = .ypWhiteIOS
        label3.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        return label3
    }()
    
    lazy var logoutButton: UIButton = {
        let button = UIButton()
        let logoutImage = UIImage(named: ConstantProfileView.ProfileView.logoutImage)
        button.setImage(logoutImage, for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }
    
    // MARK: - Setup UI
    
    private func setupView() {
        view.backgroundColor = UIColor(named: ConstantProfileView.ProfileView.backgroundColor)
        view.addSubview(profileImageView)
        view.addSubview(nameProfile)
        view.addSubview(loginNameLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(logoutButton)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        nameProfile.translatesAutoresizingMaskIntoConstraints = false
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            nameProfile.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            nameProfile.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameProfile.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: profileImageView.leadingAnchor),
            logoutButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
}
