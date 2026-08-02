import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "OAuth2BearerToken"
    
    private init() {}
    
    var token: String? {
           get {
               return KeychainWrapper.standard.string(forKey: tokenKey)
           }
           set {
               if let newToken = newValue {
                   KeychainWrapper.standard.set(newToken, forKey: tokenKey)
               } else {
                   KeychainWrapper.standard.removeObject(forKey: tokenKey)
               }
           }
       }
}
