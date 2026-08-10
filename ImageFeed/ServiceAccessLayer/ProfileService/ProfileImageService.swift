import Foundation

// MARK: - Models
struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

struct UserResult: Codable {
    let profileImage: ProfileImage
}

final class ProfileImageService {
    
    static let shared = ProfileImageService()
    private(set) var avatarURL: String?
    private var task: URLSessionTask?
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderdidChange")
    
    private init() {}
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()
        
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }
        
        guard let request = makeProfileImageRequest(username: username, token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            switch result {
            case .success(let result):
                guard let self = self else { return }
                self.avatarURL = result.profileImage.small
                completion(.success(result.profileImage.small))

                NotificationCenter.default
                    .post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": self.avatarURL ?? ""]
                    )

            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: \(error) для пользователя: \(username)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }
    
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func clean() {
        avatarURL = nil
    }
}

