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
    weak var delegate: ImagesListCellDelegate?
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    private let dateFormatter = ISO8601DateFormatter()
    private var fetchPhotosTask: URLSessionTask?
    private var changeLikeTask: URLSessionTask?
    private let tokenStorage = OAuth2TokenStorage.shared
    private let logger = Logger(category: "ImagesListService")
    
    // MARK: - Public Methods
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // 1. Используем отдельный таск для лайков, чтобы пагинация ленты его не отменяла!
        // (Убедитесь, что вы добавили private var changeLikeTask: URLSessionTask? в свойства класса)
        changeLikeTask?.cancel()
        
        let urlString = "\(Constants.defaultBaseURLString)/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.urlRequestError(URLError(.badURL))))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        
        // 2. Берем токен из хранилища
        if let token = tokenStorage.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.log("[ImagesListService]: Отправка лайка с токеном. Метод: \(request.httpMethod ?? "")")
        } else {
            logger.error("[ImagesListService ERROR]: Попытка поставить лайк БЕЗ ТОКЕНА!")
        }
        
        struct LikeResponseResult: Codable {
            let photo: PhotoResult
        }
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<LikeResponseResult, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.changeLikeTask = nil
                
                switch result {
                case .success(let response):
                    // Ищем фото в локальном массиве и обновляем его статус
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let newPhoto = Photo(from: response.photo, dateFormatter: self.dateFormatter)
                        self.photos = self.photos.withReplaced(itemAt: index, newValue: newPhoto)
                        self.logger.log("[ImagesListService]: Статус лайка успешно обновлен на сервере: \(newPhoto.isLiked)")
                    }
                    completion(.success(()))
                    
                case .failure(let error):
                    self.logger.error("[ImagesListService ERROR]: Не удалось изменить статус лайка на сервере: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        self.changeLikeTask = task
        task.resume()
        
    }
    
    
    func fetchPhotosNextPage() {
           assert(Thread.isMainThread)
           // 1. Проверяем только задачу загрузки страниц, чтобы лайки её не блокировали
           guard fetchPhotosTask == nil else { return }
           
           let nextPage = (lastLoadedPage ?? 0) + 1
           logger.log("Начало загрузки страницы \(nextPage) в ImagesListService")
           
           guard let baseURL = URL(string: Constants.defaultBaseURLString)?.appendingPathComponent("photos"),
                 var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
               logger.error("[ImagesListService]: Не удалось создать базовый URL")
               return
           }
           
           urlComponents.queryItems = [
               URLQueryItem(name: "page", value: String(nextPage)),
               URLQueryItem(name: "per_page", value: "10")
           ]
           
           guard let url = urlComponents.url else {
               logger.error("[ImagesListService]: Не удалось собрать финальный URL")
               return
           }
           
           var request = URLRequest(url: url)
           request.httpMethod = "GET"
           
           if let token = tokenStorage.token, !token.isEmpty {
               request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
           } else {
               request.setValue("Client-ID \(Constants.accessKey)", forHTTPHeaderField: "Authorization")
           }
           
           // В локальную константу записываем таск
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
                   // 2. Обнуляем именно fetchPhotosTask по завершении запроса
                   self.fetchPhotosTask = nil
               }
           }
           // 3. Сохраняем таск в правильное свойство класса и запускаем
           self.fetchPhotosTask = task
           task.resume()
       }
    
    func clean() {
            photos = []
            lastLoadedPage = nil
            
            // Отменяем и очищаем задачу загрузки страниц ленты
            fetchPhotosTask?.cancel()
            fetchPhotosTask = nil
            
            // Отменяем и очищаем задачу установки лайков
            changeLikeTask?.cancel()
            changeLikeTask = nil
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

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> [Element] {
        var modifiedArray = self
        modifiedArray[index] = newValue
        return modifiedArray
    }
}
