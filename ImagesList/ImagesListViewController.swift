import UIKit

final class ImagesListViewController: UIViewController {
    
    
    // MARK: - IBOutlets
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Properties
    private let imagesName: [String] = Array(0..<20).map{ "\($0)" }
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO: Реализация в следующих спринтах
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let imageName = imagesName[indexPath.row]
        guard let image = UIImage(named: imageName) else {
            return 0
        }
        let imageWidth = image.size.width
        guard imageWidth > 0 else {
            return 0
        }
        let imageViewWidth = tableView.bounds.width
        let scale = imageViewWidth / imageWidth
        let imageHeight = image.size.height
        return imageHeight * scale
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imagesName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
    
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let imageName = imagesName[indexPath.row]
        guard let image = UIImage(named: imageName) else {
            return
        }
        cell.cellImageView.image = image
        let currentDate = dateFormatter.string(from: Date())
        cell.dateLabel.text = currentDate
        setIsLiked(for: cell, with: indexPath)
    }
    
    private func setIsLiked(for cell: ImagesListCell, with indexPath: IndexPath) {
        let isLiked = indexPath.row % 2 == 0
        let likeImageName = isLiked ? "like_button_on" : "like_button_off"
        guard let likeImage = UIImage(named: likeImageName) else { return }
        cell.likeButton.setImage(likeImage, for: .normal)
    }
}



