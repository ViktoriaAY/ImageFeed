import UIKit
import ProgressHUD
import OSLog

// MARK: - AuthViewControllerDelegate
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

// MARK: - AuthViewController
final class AuthViewController: UIViewController {
    
    // MARK: - Properties
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    weak var delegate: AuthViewControllerDelegate?
    private let logger = Logger(category: "Auth")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    // MARK: - Overrides

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            let authHelper = AuthHelper()
            let webViewPresenter = WebViewPresenter(authHelper: authHelper)
            webViewViewController.presenter = webViewPresenter
            webViewPresenter.view = webViewViewController
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: - Private Methods
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(resource: .navBackButton)
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(resource: .navBackButton)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(resource: .ypBlackIOS)
    }
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
    
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        // 1. Сначала закрываем WebView контроллер
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // 2. Показываем лоадер блокировки интерфейса
            UIBlockingProgressHUD.show()
            self.logger.debug("Начинаем обмен кода на токен в сети...")
            
            // 3. Делаем сетевой запрос к Unsplash за токеном
            self.oauth2Service.fetchOAuthToken(with: code) { [weak self] result in
                // Сразу убираем лоадер на главном потоке
                UIBlockingProgressHUD.dismiss()
                
                guard let self = self else { return }
                self.logger.debug("Получен результат сетевого запроса обмена токена: \(String(describing: result))")
                
                switch result {
                case .success(let token):
                    self.logger.info("Токен успешно получен от Unsplash!")
                    
                    // КРИТИЧЕСКИ ВАЖНО: Сначала железно записываем токен в память!
                    OAuth2TokenStorage.shared.token = token
                    
                    // ПРИНТ 2: Проверяем, прочитался ли он сразу после записи
                    if let check = OAuth2TokenStorage.shared.token {
                        print("🍏 [UI TEST STORAGE SUCCESS]: Токен успешно сохранен в памяти: \(check)")
                    } else {
                        print("🚨 [UI TEST STORAGE ERROR]: Токен пришел из сети, но STORAGE вернул nil после записи!")
                    }
                    
                    // И ТОЛЬКО ПОСЛЕ ЭТОГО уведомляем SplashViewController, что вход выполнен!
                    self.logger.debug("Токен в памяти. Вызываем метод делегата didAuthenticate")
                    self.delegate?.didAuthenticate(self)
                    
                case .failure(let error):
                    self.logger.error("Сетевая ошибка авторизации: \(error.localizedDescription)")
                    self.showAuthErrorAlert()
                }
            }
        }
    }
}

// MARK: - Alert Extension
extension AuthViewController {
    func showAuthErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Logger Extension
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.imagefeed"
    init(category: String) {
        self.init(subsystem: Self.subsystem, category: category)
    }
}
