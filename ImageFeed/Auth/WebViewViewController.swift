import UIKit
import WebKit
import OSLog

public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? { get set }
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
    func load(request: URLRequest)
}
// MARK: - WebViewViewControllerDelegate

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// MARK: - WebViewViewController

final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {
    
    // MARK: - IBOutlets
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var webView: WKWebView!
    
    // MARK: - Properties
    var presenter: WebViewPresenterProtocol?
    weak var delegate: WebViewViewControllerDelegate?
    private var estimatedProgressObservation: NSKeyValueObservation?
    private let logger = Logger(category: "WebViewViewController")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        
        // Современный способ включения JavaScript (iOS 14+)
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // Присваиваем ID для UI-теста
        webView.accessibilityIdentifier = "UnsplashWebView"
        presenter?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            // Принудительно ставим маркер прямо перед тем, как экран покажется
            webView.accessibilityIdentifier = "UnsplashWebView"
        }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            presenter?.didUpdateProgressValue(webView.estimatedProgress)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    // MARK: - IBActions
    
    @IBAction private func buttonWebView(_ sender: Any) {
        delegate?.webViewViewControllerDidCancel(self)
    }

    func load(request: URLRequest) {
        webView.load(request)
    }

    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
    }
}

// MARK: - WKNavigationDelegate

extension WebViewViewController: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Проверяем, есть ли вообще URL у текущего действия
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        print("🌐 [WEBVIEW DETECTED URL]: \(url.absoluteString)")
        
        // 1. Проверяем, вернул ли Unsplash секретный код авторизации (myapp://unsplash-auth?code=...)
        if let code = presenter?.code(from: url) {
            print("🎉 [WEBVIEW SUCCESS]: Код пойман: \(code)")
            
            // Передаем код делегату, который закроет WebView и сохранит токен
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            
            decisionHandler(.cancel) // Закрываем WebView, так как авторизация успешна
            return // Обязательно прерываем выполнение функции!
        }
        
        // 2. Для всех остальных стандартных страниц Unsplash (включая саму форму ввода логина)
        // мы просто разрешаем обычную штатную загрузку
        decisionHandler(.allow)
    }
    
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            return presenter?.code(from: url)
        }
        return nil
    }
}

