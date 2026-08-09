import UIKit
import Kingfisher

// MARK: - ImagesListViewController

enum LikeImage: String {
    case on = "like_button_on"
    case off = "like_button_off"
}

final class ImagesListViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Properties
    
    var photos: [Photo] = []
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        addNotificationObserver()
        
        if photos.isEmpty {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    // MARK: - Overrides
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showSingleImageSegueIdentifier else {
            super.prepare(for: segue, sender: sender)
            return
        }
        guard
            let viewController = segue.destination as? SingleImageViewController,
            let indexPath = sender as? IndexPath
        else {
            assertionFailure("Invalid segue destination")
            return
        }
        let photo = photos[indexPath.row]
        if let fullImageURL = URL(string: photo.largeImageURL) {
            viewController.imageURL = fullImageURL
        }
    }
    
    // MARK: - Private Methods
    
    private func addNotificationObserver() {
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.updateTableViewAnimated()
        }
    }
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        if oldCount != newCount {
            tableView.performBatchUpdates {
                
                let indexPaths = (oldCount..<newCount).map { i in
                    IndexPath(row: i, section: 0)
                }
                
                tableView.insertRows(at: indexPaths, with: .automatic)
            } completion: { _ in }
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
    
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        guard let url = URL(string: photo.thumbImageURL) else { return }
        cell.cellImageView.addSkeletonAnimation(cornerRadius: 16)
        
        cell.cellImageView.kf.indicatorType = .activity
        cell.cellImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "stub")
        ) { [weak cell] result in
            cell?.cellImageView.removeSkeletonAnimation()
        }
        
        if let createdAt = photo.createdAt {
            cell.dateLabel.text = DateFormatter.sharedImagesListFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = ""
        }
        cell.setIsLiked(isLiked: photo.isLiked)
    }
}

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let imageWidth = photo.size.width
        let imageHeight = photo.size.height
        
        guard imageWidth > 0 else { return 0 }
        let imageLeftInset: CGFloat = 16
        let imageRightInset: CGFloat = 16
        let imageViewWidth = tableView.bounds.width - imageLeftInset - imageRightInset
        let scale = imageViewWidth / imageWidth
        let cellHeight = imageHeight * scale + 8
        
        return cellHeight
    }
}

// MARK: - UITableViewDataSource

extension ImagesListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        imageListCell.delegate = self
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

// MARK: - ImagesListCellDelegate

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        UIBlockingProgressHUD.show()
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success:
                self.photos = self.imagesListService.photos
                let updatedPhoto = self.photos[indexPath.row]
                cell.setIsLiked(isLiked: updatedPhoto.isLiked)
                
            case .failure(let error):
                self.showLikeErrorAlert()
                print("Ошибка изменения лайка: \(error.localizedDescription)")
            }
        }
    }
    
    private func showLikeErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось изменить статус лайка. Попробуйте ещё раз.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
}
// MARK: - DateFormatter Extension
extension DateFormatter {
    static let sharedImagesListFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
}


