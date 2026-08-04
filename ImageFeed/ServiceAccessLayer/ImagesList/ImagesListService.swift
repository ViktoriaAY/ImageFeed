import UIKit
import CoreGraphics
import OSLog

// MARK: - Models

struct UrlsResult: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct PhotoResult: Codable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: String?
    let description: String?
    let urls: UrlsResult
    let likedByUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case width
        case height
        case createdAt = "created_at"
        case description
        case urls
        case likedByUser = "liked_by_user"
    }
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

// MARK: - Service

final class ImagesListService {
    
    // MARK: - Properties
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    private let dateFormatter = ISO8601DateFormatter()
    private var task: URLSessionTask?
    private let tokenStorage = OAuth2TokenStorage.shared
    private let logger = Logger(category: "ImagesListService")
    
    // MARK: - Public Methods
    
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        guard task == nil else { return }
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        logger.log("Начало загрузки страницы \(nextPage) в ImagesListService")
        
        guard let url = URL(string: "https://unsplash.com\(nextPage)&per_page=10") else { return } 
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = tokenStorage.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let photoResults):
                    let newPhotos = photoResults.map { Photo(from: $0, dateFormatter: self.dateFormatter) }
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )
                    
                case .failure(let error):
                    self.logger.error("[ImagesListService]: Ошибка загрузки страницы \(nextPage) - \(error.localizedDescription)")
                }
                self.task = nil
            }
        }
        self.task = task
        task.resume()
    }
}

extension Photo {
    init(from result: PhotoResult, dateFormatter: ISO8601DateFormatter) {
        self.id = result.id
        self.size = CGSize(width: result.width, height: result.height)
        
        if let dateString = result.createdAt {
            self.createdAt = dateFormatter.date(from: dateString)
        } else {
            self.createdAt = nil
        }
        
        self.welcomeDescription = result.description
        self.isLiked = result.likedByUser
        self.thumbImageURL = result.urls.thumb
        self.largeImageURL = result.urls.full
    }
}
