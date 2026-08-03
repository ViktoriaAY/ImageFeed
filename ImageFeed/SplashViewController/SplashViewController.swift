import UIKit
import OSLog

final class SplashViewController: UIViewController {
    
    // MARK: - Logger
    private let logger = Logger(category: "SplashViewController")
    
    // MARK: - Properties
    
    private let storage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private var isFirstLaunch = true
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "splash_screen_logo")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard isFirstLaunch else { return }
        isFirstLaunch = false
        
        if let token = storage.token {
            logger.info("Token found in storage. Starting fetchProfile")
            fetchProfile(token: token)
        } else {
            logger.info("No token found. Presenting AuthViewController")

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            guard let authViewController = storyboard.instantiateViewController(
                withIdentifier: "AuthViewController"
            ) as? AuthViewController else {
                assertionFailure("Failed to instantiate AuthViewController from Storyboard")
                return
            }
            
            authViewController.delegate = self
            authViewController.modalPresentationStyle = .fullScreen
            
            present(authViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Overrides
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Private Methods
    
    private func setupView() {
        view.backgroundColor = UIColor(named: "YP Black (iOS)")
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0)
        ])
    }
    
    private func switchToTabBarController() {
        logger.info("Requesting screen switch. Redirecting to main thread")
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else {
                self.logger.error("Failed to find main window via SceneDelegate!")
                return
            }
            
            self.logger.info("Instantiating TabBarViewController from Storyboard")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
            
            self.logger.info("Changing rootViewController to TabBar")
            window.rootViewController = tabBarController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            self.logger.info("Screen switch completed successfully.")
        }
    }
    
    private func fetchProfile(token: String) {
        logger.info("fetchProfile started. Token received.")
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            // Скрываем лоадер сразу, предотвращая зависание интерфейса
            UIBlockingProgressHUD.dismiss()

            guard let self else { return }
            self.logger.info("Profile network request returned a result.")

            switch result {
            case let .success(profile):
                // Защищаем личные данные (username) при помощи приватности логов на реальных девайсах
                self.logger.info("Profile loaded for \(profile.username, privacy: .private). Requesting avatar URL")
            
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.logger.info("Avatar URL received. Switching screen.")
                    self.switchToTabBarController()
                }

            case let .failure(error):
                self.logger.error("CRITICAL ERROR DURING PROFILE REQUEST: \(error.localizedDescription)")
                self.view.backgroundColor = .red
            }
        }
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    
    func didAuthenticate(_ vc: AuthViewController) {
        logger.info("User authenticated successfully via Web view. Dismissing AuthViewController...")
        vc.dismiss(animated: true)
        
        guard let token = storage.token else {
            logger.error("Error: Token was not saved to storage after authentication!")
            return
        }
        
        fetchProfile(token: token)
    }
}
