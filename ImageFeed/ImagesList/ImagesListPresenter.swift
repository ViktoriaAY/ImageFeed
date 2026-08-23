import Foundation
import UIKit

protocol ImagesListViewPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    var photos: [Photo] { get }
    func viewDidLoad()
    func fetchPhotosNextPageIfNeeded(by indexPath: IndexPath)
    func calculateCellHeight(for indexPath: IndexPath, tableViewWidth: CGFloat) -> CGFloat
    func changeLike(at indexPath: IndexPath, completion: @escaping (Result<Void, Error>) -> Void)
}

final class ImagesListPresenter: ImagesListViewPresenterProtocol {
    weak var view: ImagesListViewControllerProtocol?
    
    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?
    private var oldCount = 0
    
    var photos: [Photo] {
        return imagesListService.photos
    }
    
    func viewDidLoad() {
        addNotificationObserver()
        oldCount = photos.count
        print("🍏 [PRESENTER LOG]: Сработал viewDidLoad. Картинок в кэше: \(oldCount)")
                
        if photos.isEmpty {
            imagesListService.fetchPhotosNextPage()
        }
     else {
                // Если картинки уже были в памяти, принудительно говорим UI обновиться
                self.view?.updateTableViewAnimated(oldCount: 0, newCount: photos.count)
            }

    }
    
    func fetchPhotosNextPageIfNeeded(by indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    func calculateCellHeight(for indexPath: IndexPath, tableViewWidth: CGFloat) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageWidth = photo.size.width
        let imageHeight = photo.size.height
        
        guard imageWidth > 0 else { return 0 }
        let imageInsets: CGFloat = 32
        let imageViewWidth = tableViewWidth - imageInsets
        let scale = imageViewWidth / imageWidth
        return imageHeight * scale + 8
    }
    
    func changeLike(at indexPath: IndexPath, completion: @escaping (Result<Void, Error>) -> Void) {
            let photo = photos[indexPath.row]
            
            // Передаем инвертированное значение лайка (!photo.isLiked) в сервис
            imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
                guard let self = self else { return }
                
                // Вся работа с UI и вызов completion ОБЯЗАТЕЛЬНО должны быть на главном потоке
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // Берем уже обновленную модель фото из массива
                        let updatedPhoto = self.photos[indexPath.row]
                        
                        // Обновляем визуальное состояние ячейки
                        self.view?.setCellLiked(at: indexPath, isLiked: updatedPhoto.isLiked)
                        completion(.success(()))
                        
                    case .failure(let error):
                        // Показываем алерт в случае ошибки сети
                        self.view?.showLikeErrorAlert()
                        completion(.failure(error))
                    }
                }
            }
        }
    
    private func addNotificationObserver() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let newCount = self.photos.count
            
            self.view?.updateTableViewAnimated(oldCount: self.oldCount, newCount: newCount)
            self.oldCount = newCount
        }
    }
}
