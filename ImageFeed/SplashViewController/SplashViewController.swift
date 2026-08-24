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
        
        guard isFirstLaunch else { return }
        isFirstLaunch = false
        
        // Проверяем, передан ли флаг очистки для UI-теста
        if CommandLine.arguments.contains("clearSessionForTesting") {
            logger.info("🤖 [UI TEST] Тест авторизации: принудительно очищаем сессию.")
            storage.token = nil
            
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
            let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            
            // ВАЖНО: вызываем показ экрана только ТОГДА, когда куки очищены!
            WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) { [weak self] in
                DispatchQueue.main.async {
                    self?.logger.info("🤖 [UI TEST] Очистка куки завершена. Показываем AuthViewController.")
                    self?.presentAuthViewController()
                }
            }
        } else {
            // Стандартная логика обычного запуска приложения
            if let token = storage.token {
                logger.info("Token found in storage. Starting fetchProfile")
                fetchProfile(token: token)
            } else {
                logger.info("No token found. Presenting AuthViewController")
                presentAuthViewController()
            }
        }
    }

       
       // Вспомогательный метод для чистоты кода, чтобы не дублировать логику создания экрана входа
    private func presentAuthViewController() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else { return }
            authViewController.delegate = self
            authViewController.modalPresentationStyle = .fullScreen
            self.present(authViewController, animated: true, completion: nil)
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
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else { return }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController") as! UITabBarController
            
            // 1. НАСТРОЙКА ЛЕНТЫ (Это у вас уже работает)
            if let imagesListVC = tabBarController.viewControllers?.first as? ImagesListViewController {
                let presenter = ImagesListPresenter()
                imagesListVC.configure(presenter)
            }
            
            // 2. ДОБАВЬТЕ ЭТОТ БЛОК ДЛЯ ПРОФИЛЯ:
            // Ищем ProfileViewController среди вкладок (обычно он второй, то есть .last или по индексу)
            if let profileVC = tabBarController.viewControllers?.last as? ProfileViewController {
                print("🍏 [SPLASH LOG]: ProfileViewController найден в TabBar. Конфигурируем MVP...")
                
                // Создаем презентер для профиля
                let presenter = ProfilePresenter()
                
                // Связываем их (убедитесь, что метод configure прописан в ProfileViewController)
                profileVC.presenter = presenter
                presenter.view = profileVC
            } else {
                print("🚨 [SPLASH ERROR]: Не удалось найти ProfileViewController во вкладках таббара!")
            }
            
            window.rootViewController = tabBarController
            window.makeKeyAndVisible()
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
        logger.info("[SplashVC]: Пользователь успешно авторизовался на Web-экране. Начинаем закрытие...")
        
        // Передаем логику получения профиля строго в блок completion метода dismiss!
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            logger.info("[SplashVC]: Экран авторизации полностью скрылся. Проверяем токен...")
            guard let token = self.storage.token else {
                self.logger.error("[SplashVC] Ошибка: После авторизации токен не сохранился!")
                return
            }
            
            // Запускаем загрузку профиля и переход на ТабБар
            self.fetchProfile(token: token)
        }
    }
}

    
    
 
