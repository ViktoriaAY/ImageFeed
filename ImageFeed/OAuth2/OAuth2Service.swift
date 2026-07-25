import Foundation

// MARK: - Models

private struct OAuthTokenResponseBody: Decodable {
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
    private var lastCode: String?
    private var task: URLSessionTask?
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
        assert(Thread.isMainThread)
        guard lastCode != code else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        task?.cancel()
        lastCode = code
    
        guard let request = makeOAuth2Request(with: code) else {
            lastCode = nil
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        let task = URLSession.shared.data(for: request) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.task = nil
                self.lastCode = nil
                
                switch result {
                case .success(let data):
                    do {
                        let responseBody = try self.decoder.decode(OAuthTokenResponseBody.self, from: data)
                        self.authToken = responseBody.accessToken
                        completion(.success(responseBody.accessToken))
                    } catch {
                        completion(.failure(NetworkError.decodingError(error)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Private Methods
    
    private func makeOAuth2Request(with code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            assertionFailure("Failed to create URL")
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
