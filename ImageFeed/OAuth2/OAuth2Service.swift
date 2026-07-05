import Foundation

// MARK: - Models

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - OAuth2Service

final class OAuth2Service {
    
    // MARK: - Properties
    
    static let shared = OAuth2Service()
    private var authToken: String?
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    func fetchOAuthToken(
        with code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let request = makeOAuth2Request(with: code) else {
            print("ERROR: Не удалось создать URLRequest. Проверьте URL или URLComponents.")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("REQUEST =", request.url?.absoluteString ?? "")
        
        let task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                do {
                    let responseBody = try self.decoder.decode(OAuthTokenResponseBody.self, from: data)
                    
                    print("TOKEN =", responseBody.accessToken)
                    self.authToken = responseBody.accessToken
                    
                    completion(.success(responseBody.accessToken))
                } catch {
                    print("DECODE ERROR:", error)
                    completion(.failure(NetworkError.decodingError(error)))
                }
                
            case .failure(let error):
                print("NETWORK OR HTTP ERROR:", error)
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Private Methods
    
    private func makeOAuth2Request(with code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            print("ERROR: Не удалось сформировать базовый URL для авторизации.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        return request
    }
}
