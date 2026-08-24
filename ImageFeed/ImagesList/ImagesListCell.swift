import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    
    // MARK: - Properties
    static let reuseIdentifier = "ImagesListCell"
    weak var delegate: ImagesListCellDelegate?
    
    // MARK: - IBOutlets
    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
   
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImageView.kf.cancelDownloadTask()
        cellImageView.removeSkeletonAnimation()
    }
    // MARK: - IBAction
    @IBAction func likeButtonAction() {
        delegate?.imageListCellDidTapLike(self)
    }
    
    // MARK: - func
    func setIsLiked(isLiked: Bool) {
        let imageName = isLiked ? "like_button_on" : "like_button_off"
        likeButton.setImage(UIImage(named: imageName), for: .normal)
        
        // 1. Обязательно разрешаем системе тестирования видеть эту кнопку
        likeButton.isAccessibilityElement = true
        
        // 2. Строгое соответствие текстовым именам в UI-тесте (БЕЗ нижних подчеркиваний!)
        likeButton.accessibilityIdentifier = isLiked ? "like button on" : "like button off"
    }
}
