import UIKit
import Kingfisher

protocol ImagesListViewControllerProtocol: AnyObject {
    func updateTableViewAnimated(oldCount: Int, newCount: Int)
    func setCellLiked(at indexPath: IndexPath, isLiked: Bool)
    func showLikeErrorAlert()
}

final class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    
    // MARK: - IBOutlets
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Properties
    private var presenter: ImagesListViewPresenterProtocol!
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    func configure(_ presenter: ImagesListViewPresenterProtocol) {
        self.presenter = presenter
        self.presenter.view = self
        
        if isViewLoaded {
            presenter.viewDidLoad()
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        presenter?.viewDidLoad()
    }
    
    // MARK: - Overrides
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == showSingleImageSegueIdentifier else {
            super.prepare(for: segue, sender: sender)
            return
        }
        guard
            let viewController = segue.destination as? SingleImageViewController,
            let indexPath = sender as? IndexPath,
            let photo = presenter?.photos[indexPath.row]
        else {
            assertionFailure("Invalid segue destination")
            return
        }
        if let fullImageURL = URL(string: photo.largeImageURL) {
            viewController.imageURL = fullImageURL
        }
    }
    
    // MARK: - ImagesListViewControllerProtocol
    func updateTableViewAnimated(oldCount: Int, newCount: Int) {
            // Запрашиваем реальное количество строк, которое таблица отображает прямо сейчас
            let currentRowsCount = tableView.numberOfRows(inSection: 0)
            
            print("🍏 [VIEW LOG]: Обновление таблицы. Строк в UI сейчас: \(currentRowsCount), должно стать: \(newCount)")
            
            if currentRowsCount != newCount {
                tableView.performBatchUpdates {
                    let indexPaths = (currentRowsCount..<newCount).map { i in
                        IndexPath(row: i, section: 0)
                    }
                    tableView.insertRows(at: indexPaths, with: .automatic)
                } completion: { _ in }
            }
        }
    
    func setCellLiked(at indexPath: IndexPath, isLiked: Bool) {
           // Принудительно перезагружаем только одну строку ячейки.
           // Это гарантирует 100% синхронизацию модели данных с UI слоя.
           tableView.reloadRows(at: [indexPath], with: .none)
       }
    
    func showLikeErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось изменить статус лайка. Попробуйте ещё раз.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Private Methods
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        // Возвращаем стандартные системные отступы
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        tableView.accessibilityIdentifier = "ImagesListTable"
    }
    
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        guard let photo = presenter?.photos[indexPath.row],
              let url = URL(string: photo.thumbImageURL) else { return }
        
        cell.cellImageView.addSkeletonAnimation(cornerRadius: 16)
        cell.cellImageView.kf.indicatorType = .activity
        cell.cellImageView.kf.setImage(with: url, placeholder: UIImage(named: "stub")) { [weak cell] _ in
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

extension DateFormatter {
    static let sharedImagesListFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    } ()
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter?.fetchPhotosNextPageIfNeeded(by: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return presenter?.calculateCellHeight(for: indexPath, tableViewWidth: tableView.bounds.width) ?? 0
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.photos.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imageListCell = cell as? ImagesListCell else { return UITableViewCell() }
        imageListCell.delegate = self
        configCell(for: imageListCell, with: indexPath)
        
        // ДОБАВЛЕНО ДЛЯ UI-ТЕСТОВ: Каждая ячейка получает свое уникальное имя
        imageListCell.accessibilityIdentifier = "ImagesListCell"
        
        return imageListCell
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        UIBlockingProgressHUD.show()
        presenter?.changeLike(at: indexPath) { _ in
            UIBlockingProgressHUD.dismiss()
        }
    }
}
