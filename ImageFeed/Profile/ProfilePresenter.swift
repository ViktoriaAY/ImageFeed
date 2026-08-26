import Foundation

// MARK: - Protocols
protocol ProfileViewControllerProtocol: AnyObject {
    func updateProfileDetails(name: String, nickname: String, bio: String)
    func updateAvatar(with url: URL)
    func startSkeletonAnimation()
    func removeGradientAnimation()
    func switchToSplashViewController()
}

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogoutButton()
}

protocol ProfileServiceProtocol: AnyObject {
    var profile: Profile? { get }
}

protocol ProfileImageServiceProtocol: AnyObject {
    var avatarURL: String? { get }
}

protocol ProfileLogoutServiceProtocol: AnyObject {
    func logout()
}

// MARK: - ProfilePresenter

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    
    private let profileService: ProfileServiceProtocol
    private let profileImageService: ProfileImageServiceProtocol
    private let profileLogoutService: ProfileLogoutServiceProtocol
    private let notificationCenter: NotificationCenter
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    init(
        profileService: ProfileServiceProtocol = ProfileService.shared,
        profileImageService: ProfileImageServiceProtocol = ProfileImageService.shared,
        profileLogoutService: ProfileLogoutServiceProtocol = ProfileLogoutService.shared,
        notificationCenter: NotificationCenter = .default
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
        self.profileLogoutService = profileLogoutService
        self.notificationCenter = notificationCenter
    }
    
    func viewDidLoad() {
        if let profile = profileService.profile {
            displayProfile(profile)
        } else {
            view?.startSkeletonAnimation()
        }
        
        observeAvatarChanges()
        checkAndObserverAvatar()
    }
    
    func didTapLogoutButton() {
        profileLogoutService.logout()
        view?.switchToSplashViewController()
    }
    
    private func observeAvatarChanges() {
        profileImageServiceObserver = notificationCenter.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.checkAndObserverAvatar()
        }
    }
    
    private func checkAndObserverAvatar() {
        guard let avatarURLString = profileImageService.avatarURL,
              let url = URL(string: avatarURLString) else { return }
        
        view?.removeGradientAnimation()
        view?.updateAvatar(with: url)
    }
    
    private func displayProfile(_ profile: Profile) {
        view?.removeGradientAnimation()
        
        let name = profile.name.isEmpty
            ? ConstantProfileView.ProfileView.namePlaceholder
            : profile.name
            
        let nickname = profile.loginName.isEmpty
            ? ConstantProfileView.ProfileView.nicknamePlaceholder
            : profile.loginName
            
        let bio = (profile.bio?.isEmpty ?? true)
            ? ConstantProfileView.ProfileView.descriptionPlaceholder
            : (profile.bio ?? "")
            
        view?.updateProfileDetails(name: name, nickname: nickname, bio: bio)
    }
    
    deinit {
        if let observer = profileImageServiceObserver {
            notificationCenter.removeObserver(observer)
        }
    }
}

// MARK: - Extensions for Original Services

extension ProfileService: ProfileServiceProtocol {}
extension ProfileImageService: ProfileImageServiceProtocol {}
extension ProfileLogoutService: ProfileLogoutServiceProtocol {}
