import UIKit

final class SplashViewController: UIViewController {
    
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
            print("[SplashVC]: Токен найден в хранилище. Запускаем fetchProfile...")
            fetchProfile(token: token)
        } else {
            print("[SplashVC]: Токена нет. Показываем экран авторизации кодом из задания...")

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
        print("[SplashVC]: Началась функция fetchProfile. Токен передан.")
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            print("[SplashVC]: Сетевой запрос профиля вернул результат.")

            guard let self = self else { return }

            switch result {
            case let .success(profile):
                print("[SplashVC]: Профиль загружен для \(profile.username). Запрашиваем ссылку на аватарку...")
            
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { [weak self] _ in
                    guard let self = self else { return }
                    
                    print("[SplashVC]: Ссылка на аватарку получена. Скрываем HUD и переключаем экран.")
                    UIBlockingProgressHUD.dismiss()
                    self.switchToTabBarController()
                }

            case let .failure(error):
                UIBlockingProgressHUD.dismiss()
                print("[SplashVC] КРИТИЧЕСКАЯ ОШИБКА ЗАПРОСА ПРОФИЛЯ: \(error)")
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
