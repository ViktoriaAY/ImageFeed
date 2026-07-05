import UIKit
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
            guard let webViewViewController = segue.destination as? WebViewViewController else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
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
        logger.debug("Начинаем обмен кода на токен")
        
        oauth2Service.fetchOAuthToken(with: code) { [weak self] result in
            guard let self else {
                // Если контроллер ушел из памяти, логируем это как предупреждение
                let staticLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.imagefeed", category: "Auth")
                staticLogger.warning("AuthViewController был уничтожен в памяти")
                return
            }
            
            // Логируем результат выполнения запроса
            self.logger.debug("Получен результат сетевого запроса: \(String(describing: result))")
            
            switch result {
            case .success(let token):
                self.logger.info("Токен успешно получен")
                OAuth2TokenStorage.shared.token = token
                
                self.logger.debug("Вызываем метод делегата didAuthenticate")
                self.delegate?.didAuthenticate(self)
                
            case .failure(let error):
                self.logger.error("Сетевая ошибка авторизации: \(error.localizedDescription)")
            }
        }
    }
}

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.imagefeed"
    init(category: String) {
        self.init(subsystem: Self.subsystem, category: category)
    }
}
