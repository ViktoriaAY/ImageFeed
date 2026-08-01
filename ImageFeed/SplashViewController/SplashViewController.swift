import UIKit

final class SplashViewController: UIViewController {
    
    // MARK: - Properties
    
    private let storage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private var isFirstLaunch = true
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard isFirstLaunch else { return }
        isFirstLaunch = false
        
        if let token = storage.token {
            print("[SplashVC]: Токен найден в хранилище. Запускаем fetchProfile...")
            fetchProfile(token: token)
        } else {
            print("[SplashVC]: Токена нет. Показываем экран авторизации AuthViewController...")
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
    
    // MARK: - Overrides
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            guard let navigationController = segue.destination as? UINavigationController,
                  let authViewController = navigationController.viewControllers.first as? AuthViewController
            else {
                if let authViewController = segue.destination as? AuthViewController {
                    authViewController.delegate = self
                } else {
                    assertionFailure("Failed to prepare for Auth Flow")
                }
                return
            }
            authViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: - Private Methods
    
//    private func switchToTabBarController() {
//        print("[SplashVC]: Шаг 3. Вызван метод switchToTabBarController. Ищем главное окно через SceneDelegate...")
//        
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let sceneDelegate = windowScene.delegate as? SceneDelegate,
//              let window = sceneDelegate.window else {
//            print("[SplashVC] Ошибка: Не удалось найти главное окно приложения через SceneDelegate!")
//            return
//        }
//        
//        print("[SplashVC]: Создаем TabBarController")
//        let tabBarController = TabBarController()
//        
//        print("[SplashVC]: Меняем rootViewController окна на ТабБар...")
//        window.rootViewController = tabBarController
//        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
//        print("[SplashVC]: Смена экрана завершена успешно.")
//    }

    private func switchToTabBarController() {
        print("[SplashVC]: Шаг 3. Запрашиваем смену экрана. Перенаправляем в главный поток...")
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else {
                print("[SplashVC] Ошибка: Не удалось найти главное окно приложения через SceneDelegate!")
                return
            }
            
            print("[SplashVC]: Загружаем TabBarViewController из Storyboard (активируем awakeFromNib)...")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")
            
            print("[SplashVC]: Меняем rootViewController окна на ТабБар...")
            window.rootViewController = tabBarController
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            print("[SplashVC]: Смена экрана завершена успешно.")
        }
    }

    
    private func fetchProfile(token: String) {
        print("[SplashVC]: 1. Началась функция fetchProfile. Токен передан.")
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            print("[SplashVC]: 2. Сетевой запрос вернул результат.")
            UIBlockingProgressHUD.dismiss()

            guard let self = self else { return }

            switch result {
            case let .success(profile):
                print("[SplashVC]: 3. УСПЕХ! Профиль загружен для \(profile.username). Переключаем экран...")
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                self.switchToTabBarController()

            case let .failure(error):
                print("[SplashVC] КРИТИЧЕСКАЯ ОШИБКА ЗАПРОСА ПРОФИЛЯ: \(error)")
                // Если запрос упал, принудительно красим экран Splash в красный, чтобы сразу увидеть проблему визуально!
                self.view.backgroundColor = .red
            }
        }
    }

}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    
    func didAuthenticate(_ vc: AuthViewController) {
        print("[SplashVC]: Пользователь успешно авторизовался на Web-экране. Закрываем AuthViewController...")
        vc.dismiss(animated: true)
        
        guard let token = storage.token else {
            print("[SplashVC] Ошибка: После авторизации токен не сохранился в хранилище!")
            return
        }
        
        fetchProfile(token: token)
    }
}
