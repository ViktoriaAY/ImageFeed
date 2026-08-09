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
        let likeImageName = isLiked ? "like_button_on" : "like_button_off"
        guard let likeImage = UIImage(named: likeImageName) else { return }
        
        likeButton.setImage(likeImage, for: .normal)
    }
    
     func startSkeleton() {
        cellImageView.addSkeletonAnimation(cornerRadius: 16)
    }
}
