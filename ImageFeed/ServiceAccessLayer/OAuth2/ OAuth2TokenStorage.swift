import Foundation
import SwiftKeychainWrapper
final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "OAuth2BearerToken"
    
    private init() {
        // Очищаем сессию для теста авторизации
        if CommandLine.arguments.contains("clearSessionForTesting") {
            userDefaults.removeObject(forKey: tokenKey)
            userDefaults.synchronize()
        }
    }
    
    var token: String? {
        get {
            if CommandLine.arguments.contains("isUITesting") {
                // 1. Сначала проверяем, есть ли уже сохраненный токен в UserDefaults
                if let savedToken = userDefaults.string(forKey: tokenKey), !savedToken.isEmpty {
                    return savedToken
                }
                
                // 2. Если в UserDefaults пусто (первый запуск теста ленты), берем токен из Environment
                if let envToken = ProcessInfo.processInfo.environment["TEST_TOKEN"], !envToken.isEmpty {
                    // Сразу сохраняем его, чтобы приложение работало стабильно
                    userDefaults.set(envToken, forKey: tokenKey)
                    userDefaults.synchronize()
                    return envToken
                }
                return nil
            }
            // Обычный режим приложения
            return KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if CommandLine.arguments.contains("isUITesting") {
                if let newToken = newValue {
                    userDefaults.set(newToken, forKey: tokenKey)
                } else {
                    userDefaults.removeObject(forKey: tokenKey)
                }
                userDefaults.synchronize()
            } else {
                if let newToken = newValue {
                    KeychainWrapper.standard.set(newToken, forKey: tokenKey)
                } else {
                    KeychainWrapper.standard.removeObject(forKey: tokenKey)
                }
            }
        }
    }
}
