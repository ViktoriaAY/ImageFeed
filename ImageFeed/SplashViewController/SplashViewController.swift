import UIKit
import WebKit
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
        
        // Переносим guard на самый верх, чтобы контролировать только первый запуск!
        guard isFirstLaunch else {
            // Если это повторное появление (возврат с WebView) — проверяем токен, который только что сохранили
            if let token = storage.token {
                logger.info("Token verified after WebView dismiss. Starting fetchProfile.")
                fetchProfile(token: token)
            }
            return
        }
        isFirstLaunch = false
        
        // Очистку сессии для UI-теста делаем СТРОГО ОДИН РАЗ при холодном старте приложения
        if CommandLine.arguments.contains("isUITesting") {
            logger.info("🤖 [UI TEST] Холодный старт: принудительно очищаем старую сессию.")
            storage.token = nil
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
            let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {}
        }
        
        // Стандартная логика проверки при холодном старте
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
        self.logger.info("Requesting screen switch. Redirecting to main thread")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else {
                self.logger.error("Failed to find main window via SceneDelegate!")
                return
            }
            
            self.logger.info("Instantiating TabBarViewController from Storyboard")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController") as! UITabBarController
            
            // НАДЁЖНАЯ СБОРКА ПРЕЗЕНТЕРА (Внедрение зависимостей):
            // Находим ImagesListViewController внутри вкладок TabBar
            if let imagesListVC = tabBarController.viewControllers?.first as? ImagesListViewController {
                print("🍏 [SPLASH LOG]:ImagesListViewController найден в TabBar. Конфигурируем MVP...")
                
                let presenter = ImagesListPresenter()
                
                imagesListVC.configure(presenter)
            } else {
                print("🚨 [SPLASH ERROR]: Не удалось найти ImagesListViewController в первой вкладке TabBar!")
            }
            
            self.logger.info("Changing rootViewController to TabBar")
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
            
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
                self.logger.info("Profile loaded for \(profile.username, privacy: .private). Requesting avatar URL")
                
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { [weak self] _ in
                    guard let self = self else { return }
                    self.logger.info("Avatar URL request finished. Switching screen.")
                    // Переключаем экран в любом случае
                    self.switchToTabBarController()
                }
                
            case let .failure(error):
                self.logger.error("CRITICAL ERROR DURING PROFILE REQUEST: \(error.localizedDescription)")
                // Исправление: если профиль не загрузился, всё равно пробуем пройти к ленте для теста
                self.switchToTabBarController()
            }
        }
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    
    func didAuthenticate(_ vc: AuthViewController) {
        logger.info("User authenticated successfully via Web view. Dismissing AuthViewController...")
        
        // Закрываем WebView
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Ждем 1 секунду, чтобы дать возможность OAuth2Service гарантированно
            // завершить сетевой запрос и записать токен в OAuth2TokenStorage
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard let token = OAuth2TokenStorage.shared.token else {
                    self.logger.error("Error: Token was not saved to storage yet! Retrying...")
                    return
                }
                
                self.logger.info("Token successfully verified in Storage. Starting fetchProfile.")
                self.fetchProfile(token: token)
            }
        }
    }
}
